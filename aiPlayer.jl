include("grid.jl")
include("randomPlayer.jl")
using IterTools
using ProgressMeter
"""
https://boardgamegeek.com/thread/563815/omega-pc-axiom-version-making-interesting-read
'keep your groups similar in size; and keep your groups close to e (~2.7) in size'

grid is the field
player is the color the AI tries to maximize
time is the time left to compute
"""
function makeSmartTurn(grid::Array, player::Int, timeLeft::Float64)
    # what moves are available
    posMoves = possibleMoves(grid)
    posTurns = [[i, j] for i in posMoves for j in posMoves if i!=j]
    # count number of turns
    turns = countNum(1, grid) / 2
    # Iterative deepening only useful if having TranspositionTable
    let
    bestTurn = [posMoves[1], posMoves[2]]
    global maxDepth = 1
    timeElapsed = 0.0
    while (timeElapsed < timeLeft) & (maxDepth <= turns)
        # do alpha-beta-search
        println("Depth: ", maxDepth)
        bestTurn, time, memory, _, _ = @timed alphaBeta(grid, player, maxDepth, posTurns, timeLeft-timeElapsed)
        timeElapsed += time
        println("Time: ", time, "s; memory used: ", memory/1024, " kbytes")
        global maxDepth += 1
    end
    println("MaxDepth = ", maxDepth-1)
    # get the best move and play it
    setGridValue!(grid, bestTurn[1][1], bestTurn[1][2], 2)
    setGridValue!(grid, bestTurn[2][1], bestTurn[2][2], 3)

    println(PLAYERCOLORS[1], " stone set on (", bestTurn[1][1], ", ", bestTurn[1][2], ")")
    println(PLAYERCOLORS[2], " stone set on (", bestTurn[2][1], ", ", bestTurn[2][2], ")")
    printBoard(grid)
    end
end

# returns the best turn
function alphaBeta(grid::Array, player::Int, maxDepth::Int, posTurns::Array, timeLeft::Float64)
    # do a copy of the grid and run alphaBetaSearch on it
    copiedGrid = copy(grid)
    println(" possible Turns: ", length(posTurns))
    # TODO TurnOrdering here
    # for all possible TURNS: execute them all. (turn = 2 moves)
    # let
    bestTurn = posTurns[1]
    bestValue = -Inf
    bestAlpha = -Inf
    bestBeta = Inf
    startTime = time_ns()
    # println("Possible turns at depth ", maxDepth, ": ", length(posTurns))
    # TODO: parallelize this and write to a array/hashmap/sth else?
    # valueOfTurn = Dict{Array{Array{Int, Int}, Array{Int, Int}}, Int}()
    @showprogress 1 "Alpha-Beta-Searching... " for (index, turn) in enumerate(posTurns)
        # if not enough time: stop and return (current) bestTurn
        if (time_ns()-startTime)/1.0e9 >= timeLeft
            return bestTurn
        end
        # execute moves
        setGridValue!(copiedGrid, turn[1][1], turn[1][2], 2)
        setGridValue!(copiedGrid, turn[2][1], turn[2][2], 3)
        # Initial call of search for every possible Turn
        newValue = alphaBetaSearch(copiedGrid, player, bestAlpha, bestBeta, maxDepth, posTurns[1:end .!= index], timeLeft-((time_ns()-startTime)/1.0e9))
        if newValue > bestValue
            bestTurn = turn
            # println("Found better turn: ", bestTurn)
        end
        bestValue = max(bestValue, newValue)
        bestAlpha = max(bestAlpha, bestValue)
        # prune --> no need to look at the other children
        if bestAlpha >= bestBeta
            setGridValue!(copiedGrid, turn[1][1], turn[1][2], 1)
            setGridValue!(copiedGrid, turn[2][1], turn[2][2], 1)
            break
        end

        # undo all the moves
        setGridValue!(copiedGrid, turn[1][1], turn[1][2], 1)
        setGridValue!(copiedGrid, turn[2][1], turn[2][2], 1)
    end
    return bestTurn
end

# returns best value in subtree
function alphaBetaSearch(grid::Array, player::Int, alpha::Float64, beta::Float64, depth::Int, posTurns::Array, timeLeft::Float64)
    # if in terminal state
    # println("started search on depth: ", depth)
    otherPlayer = player == 2 ? 3 : 2
    value = -Inf
    if gameOver(grid, 2)
        scores = calculateScores(grid, 2)
        return scores[player]-scores[otherPlayer]
        # eval board
    # not yet finished, but max search depth
    elseif depth <= 0
        # TODO come up with a good heuristic
        approximation = heuristic(grid)
        return approximation[otherPlayer] - approximation[player]
        # scores = calculateScores(grid, 2)
        # return scores[player]-scores[otherPlayer]
        # return a heuristic-value ("AN ADMISSABLE HEURISTIC NEVER OVERESTIMATES!" - Helmar Gust)
    # continue searching
    else
        startTime = time_ns()
        # NOTE MAKE a "turn" consist of moving twice --> reduces search breadth
        # TODO TurnOrdering here (needs TranspositionTable)
        # for all possible TURNS: execute them all. (turn = 2 moves)

        for (index, turn) in enumerate(posTurns)
            # if no time left
            if timeLeft-(time_ns()-startTime)/1.0e9 <= 0
                return value
            end
            # execute the two moves
            setGridValue!(grid, turn[1][1], turn[1][2], 2)
            setGridValue!(grid, turn[2][1], turn[2][2], 3)
            # do deeper search there
            value = max(value, -alphaBetaSearch(grid, otherPlayer, -beta, -alpha, depth-1, posTurns[1:end .!= index], timeLeft-(time_ns()-startTime)/1.0e9))
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
        # this is the value that alphaBeta/negamax returned
        return value
    end
end

# const global PLAYERCOLORS = ["\U2715", "\U25B3", "\U26C4", "\U2661"]
# grid = initializeGrid(4)
# players = 2
# printBoard(grid)
#
# totalTurnTime = 2*60
# turns = countNum(1, grid) / players
# aiTurns = turns ÷ 2
# timePerTurn = totalTurnTime / aiTurns
# println("Time per turn: ", timePerTurn, "s")
#
# turn = 0
# while(!gameOver(grid, players))
#     # each player after the other
#     for p in 1:players
#         global turn += 1
#         println("####   TURN ", turn, ": PLAYER ", PLAYERCOLORS[p], "   ####")
#         if p == 1
#             makeRandomTurn(grid, players)
#         else
#             # calculate how much time the algorithm gets
#             makeSmartTurn(grid, p, timePerTurn)
#         end
#
#     end
# end
# println("### Game ended ###")
# scores = calculateScores(grid, 2)
# println("Scores: ")
# for p in 1:players
#     println(PLAYERCOLORS[p], " has scored: ", scores[p], " points")
# end
