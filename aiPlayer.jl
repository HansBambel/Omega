include("grid.jl")
include("randomPlayer.jl")
using IterTools
using ProgressMeter

# flags
const EXACT = 0
const LOWER = -1
const UPPER = 1

"""
https://boardgamegeek.com/thread/563815/omega-pc-axiom-version-making-interesting-read
'keep your groups similar in size; and keep your groups close to e (~2.7) in size'

grid is the field
player is the color the AI tries to maximize
time is the time left to compute
"""
function makeSmartTurn(grid::Array, player::Int, timeLeft::Float64)
    # TODO make smart time management (when the game is more advanced it requires less time to search)
    # --> in the beginning do bigger search, later less needed
    bestTurn = iterativeDeepening(grid, player, timeLeft)

    # get the best move and play it
    setGridValue!(grid, bestTurn[1][1], bestTurn[1][2], 2)
    setGridValue!(grid, bestTurn[2][1], bestTurn[2][2], 3)

    println(PLAYERCOLORS[1], " stone set on (", bestTurn[1][1], ", ", bestTurn[1][2], ")")
    println(PLAYERCOLORS[2], " stone set on (", bestTurn[2][1], ", ", bestTurn[2][2], ")")
    printBoard(grid)

end

# returns the best turn
function iterativeDeepening(grid::Array, player::Int, timeLeft::Float64)::Array{Array{Int, 2}}
    # what moves are available
    posMoves = possibleMoves(grid)
    # println("turns left: ", length(posMoves) ÷ 2)
    # calculate all possible turns from those moves
    posTurns = [[i, j] for i in posMoves for j in posMoves if i!=j]
    # println(" possible Turns: ", length(posTurns))
    # Iterative deepening only useful if having TranspositionTable
    # create transpositionTable(hashmap)
    # TT looks the following: key=grid, value=Tuple(value, flag, searchDepth, bestTurn)
    transpositionTable = Dict{Array, Tuple{Float64, Int, Int, Array}}()
    println("Time left: ", timeLeft)
    let
    maxDepth = 1
    timeElapsed = 0.0
    # number of turns left: length(posMoves) ÷ 2
    println("Turns left: ", length(posMoves) ÷ 2)
    while (timeElapsed < timeLeft) & (maxDepth <= length(posMoves) ÷ 2)
        # do alpha-beta-search
        # do a copy of the grid and run alphaBetaSearch on it
        copiedGrid = copy(grid)
        # for all possible TURNS: execute them all
        # let
        initAlpha = -Inf
        initBeta = Inf
        startTime = time_ns()
        println("Possible turns at depth ", maxDepth, ": ", length(posTurns))
        newValue, time, _, _, _ = @timed alphaBetaSearch(copiedGrid, transpositionTable, player, initAlpha, initBeta, maxDepth, posTurns, timeLeft-timeElapsed)

        println("Depth ", maxDepth, " took ", time,"s")
        # Write in hashmap

        timeElapsed += (time_ns()-startTime)/1.0e9
        maxDepth += 1

    end
    # println("MaxDepth = ", maxDepth-1)
    end
    # look up state in hashmap and return the best turn from it
    # println("transpositionTable:")
    # println(transpositionTable)
    # printBoard(grid)
    println("Best Move: ", transpositionTable[grid])
    # sleep(3)
    _, _, _, bestTurn = get(transpositionTable, grid, (0.0, 0, 0, posTurns[1]))
    return bestTurn
end

# returns best value in subtree and write it in hashmap
function alphaBetaSearch(grid::Array,
                         transpositionTable::Dict{Array, Tuple{Float64, Int, Int, Array}},
                         player::Int,
                         alpha::Float64,
                         beta::Float64,
                         depth::Int,
                         posTurns::Array,
                         timeLeft::Float64)::Float64
    otherPlayer = player == 2 ? 3 : 2
    oldAlpha = alpha
    value = -Inf # this needs to be outside the "if" because... Julia
    bestTurn = posTurns[1]
    # look in transpositionTable for entry
    if haskey(transpositionTable, grid)
        # println("Has Entry: ", transpositionTable[grid])
        ttValue, ttFlag, ttDepth, ttTurn = transpositionTable[grid]
        # check if we already have been here and get info
        if ttDepth >= depth
            if ttFlag == EXACT
                return ttValue
            elseif ttFlag == LOWER
                alpha = max(alpha, ttValue)
            elseif ttFlag == UPPER
                beta = min(beta, ttValue)
            end

            if alpha >= beta
                return ttValue
            end
        end
    end
    # TODO IS THIS ^ ALREADY TURNORDERING?

    # if no possible move --> gameover (terminal state)
    # if gameOver(grid, 2)
    if length(posTurns) < 2
        scores = calculateScores(grid, 2)
        return scores[player]-scores[otherPlayer]
    # not yet finished, but max search depth
    elseif depth <= 0
        # TODO come up with a good heuristic
        # return a heuristic-value ("AN ADMISSABLE HEURISTIC NEVER OVERESTIMATES!" - Helmar Gust)
        approximation = heuristic(grid)
        return approximation[otherPlayer] - approximation[player]
    # continue searching
    else
        startTime = time_ns()
        # for all possible TURNS: execute them all
        println("Not game over or search depth reached")
        for (index, turn) in enumerate(posTurns)
            # if no time left
            if timeLeft <= (time_ns()-startTime)/1.0e9
                # println("Not time left --> no write in transpositionTable")
                return value
            end
            # execute the two moves
            setGridValue!(grid, turn[1][1], turn[1][2], 2)
            setGridValue!(grid, turn[2][1], turn[2][2], 3)
            # do deeper search there
            newValue = -alphaBetaSearch(grid, transpositionTable, otherPlayer, -beta, -alpha, depth-1, posTurns[1:end .!= index], timeLeft-(time_ns()-startTime)/1.0e9)
            if newValue > value
                bestTurn = turn
                value = newValue
            end
            alpha = max(alpha, value)
            # prune --> no need to look at the other children
            if alpha >= beta
                setGridValue!(grid, turn[1][1], turn[1][2], 1)
                setGridValue!(grid, turn[2][1], turn[2][2], 1)
                break
            end

            # undo all the moves
            setGridValue!(grid, turn[1][1], turn[1][2], 1)
            setGridValue!(grid, turn[2][1], turn[2][2], 1)
        end

        println("Store the result")
        println("Value: ", value, " oldAlpha: ", oldAlpha, " beta: ", beta)
        # Store (more accurate) result in transpositionTable
        if value <= oldAlpha
            transpositionTable[grid] = value, UPPER, depth, bestTurn
        elseif value >= beta
            transpositionTable[grid] = value, LOWER, depth, bestTurn
        else
            transpositionTable[grid] = value, EXACT, depth, bestTurn
        end

        # this is the value that alphaBeta/negamax returned
        return value
    end
end
