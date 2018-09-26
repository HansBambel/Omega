# include("grid.jl")
# include("randomPlayer.jl")
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
function makeSmartTurn(grid, player::Int, timeLeft::Float64)
    # TODO make smart time management (when the game is more advanced it requires less time to search)
    # --> in the beginning do bigger search, later less needed
    # TODO in the beginning of the game maybe use a fixed set of moves so we dont waste time for shallow search
    bestTurn = iterativeDeepening(grid, player, timeLeft)

    # get the best move and play it
    # grid.setGridValue!(bestTurn[1][1], bestTurn[1][2], 2)
    # first move is already done by iterative deepening
    grid.setGridValue!(bestTurn[2][1], bestTurn[2][2], 3)

    # println("Finished smart turn")
    # println(grid.history)
    # grid.printBoard()
    # println(grid.calculateScores(2))
    # sleep(5)
    println(PLAYERCOLORS[1], " stone set on (", bestTurn[1][1], ", ", bestTurn[1][2], ")")
    println(PLAYERCOLORS[2], " stone set on (", bestTurn[2][1], ", ", bestTurn[2][2], ")")
    grid.printBoard()

end

# returns the best turn
function iterativeDeepening(grid, player::Int, timeLeft::Float64)::Array{Array{Int, 2}}
    # what moves are available
    posMoves = grid.possibleMoves()
    # println("turns left: ", length(posMoves) ÷ 2)
    # calculate all possible turns from those moves
    # posTurns = [[i, j] for i in posMoves for j in posMoves if i!=j]
    # println(" possible Turns: ", length(posTurns))
    # Iterative deepening only useful if having TranspositionTable
    # create transpositionTable(hashmap)
    # TT looks the following: key=grid, value=Tuple(value, flag, searchDepth, bestTurn)
    transpositionTable = Dict{Int64, Tuple{Float64, Int, Int, Array}}()
    println("Time left: ", timeLeft)
    let
    maxDepth = 1
    timeElapsed = 0.0
    # number of turns left: length(posMoves) ÷ 2
    println("Turns left: ", length(posMoves) ÷ 2)
    println("Possible moves: ", length(posMoves))
    while (timeElapsed < timeLeft) & (maxDepth < length(posMoves))
        # do alpha-beta-search
        # do a copy of the grid and run alphaBetaSearch on it
        # copiedGrid = copy(grid)
        # for all possible TURNS: execute them all
        # let
        initAlpha = -Inf
        initBeta = Inf
        startTime = time_ns()
        newValue = alphaBetaSearch(grid, transpositionTable, player, initAlpha, initBeta, maxDepth, posMoves, timeLeft-timeElapsed, false)
        println("Best value: ", newValue)
        println("Depth ", maxDepth, " took ", (time_ns()-startTime)/1.0e9,"s")
        # Write in hashmap
        # println("error after alphaBetaSearch")
        timeElapsed += (time_ns()-startTime)/1.0e9
        maxDepth += 1
    end
    # println("MaxDepth = ", maxDepth-1)
    end
    # look up state in hashmap and return the best turn from it
    # println("transpositionTable:")
    # println(transpositionTable)
    # printBoard(grid)
    if haskey(transpositionTable, grid.getHash())
        println("Got firstMove")
        _, _, _, firstMove = transpositionTable[grid.getHash()]
    else
        println("No firstMove in transpositionTable --> basic opening")
        _, _, _, firstMove = get(transpositionTable, grid.getHash(), (0.0, 0, 0, posMoves[1]))
    end
    # execute it and get next one move to finish a turn
    grid.setGridValue!(firstMove[1], firstMove[2], 2)
    if haskey(transpositionTable, grid.getHash())
        println("Got secondMove")
        _, _, _, secondMove = transpositionTable[grid.getHash()]
    else
        println("No secondMove in transpositionTable --> basic opening")
        _, _, _, secondMove = get(transpositionTable, grid.getHash(), (0.0, 0, 0, posMoves[2]))
    end
    println("Best Move: ", [firstMove, secondMove])
    # sleep(3)

    return [firstMove, secondMove]
end

# returns best value in subtree and write it in hashmap
function alphaBetaSearch(grid,
                         transpositionTable::Dict{Int64, Tuple{Float64, Int, Int, Array}},
                         player::Int,
                         alpha::Float64,
                         beta::Float64,
                         depth::Int,
                         posMoves::Array,
                         timeLeft::Float64,
                         firstStoneSet::Bool)::Float64
    otherPlayer = player == 2 ? 3 : 2
    oldAlpha = alpha
    value = -Inf # this needs to be outside the "if" because... Julia
    bestMove = posMoves[1]
    # look in transpositionTable for entry
    if haskey(transpositionTable, grid.getHash())
        # println("Has Entry: ", transpositionTable[grid])
        # println("Found Entry")
        ttValue, ttFlag, ttDepth, ttMove = transpositionTable[grid.getHash()]
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

    # if no possible move --> gameover (terminal state)
    # if grid.gameOver(2)
    if grid.getNumPosMoves() < 1
        # println("Game over --> Eval Board")
        # println("possibleMoves: ", grid.getNumPosMoves())
        scores = grid.calculateScores(2)
        return scores[player]-scores[otherPlayer]
    # not yet finished, but max search depth
    elseif depth <= 0
        # TODO come up with a good heuristic
        # return a heuristic-value ("AN ADMISSABLE HEURISTIC NEVER OVERESTIMATES!" - Helmar Gust)
        approximation = grid.calculateScores(2)
        return approximation[player] - approximation[otherPlayer]
    # continue searching
    else
        startTime = time_ns()
        # for all possible TURNS: execute them all
        # println("Not game over or search depth reached")
        for (index, move) in enumerate(posMoves)
            # if no time left
            # println("one possible Turn: ", turn)
            if timeLeft <= (time_ns()-startTime)/1.0e9
                # println("Not time left --> no write in transpositionTable")
                return value
            end
            # do deeper search there
            if firstStoneSet
                grid.setGridValue!(move[1], move[2], 3)
                newValue = -alphaBetaSearch(grid, transpositionTable, otherPlayer, -beta, -alpha, depth-1, posMoves[1:end .!= index], timeLeft-(time_ns()-startTime)/1.0e9, false)
            else
                grid.setGridValue!(move[1], move[2], 2)
                newValue = alphaBetaSearch(grid, transpositionTable, player, alpha, beta, depth-1, posMoves[1:end .!= index], timeLeft-(time_ns()-startTime)/1.0e9, true)
            end

            if newValue > value
                bestMove = move
                value = newValue
            end
            alpha = max(alpha, value)
            # prune --> no need to look at the other children
            if alpha >= beta
                grid.setGridValue!(move[1], move[2], 1)
                break
            end

            # undo all the moves
            grid.setGridValue!(move[1], move[2], 1)
        end

        # println("Store the result")
        # println("Value: ", value, " oldAlpha: ", oldAlpha, " beta: ", beta)
        # Store (more accurate) result in transpositionTable
        if value <= oldAlpha
            transpositionTable[grid.getHash()] = value, UPPER, depth, bestMove
        elseif value >= beta
            transpositionTable[grid.getHash()] = value, LOWER, depth, bestMove
        else
            transpositionTable[grid.getHash()] = value, EXACT, depth, bestMove
        end

        # this is the value that alphaBeta/negamax returned
        return value
    end
end
