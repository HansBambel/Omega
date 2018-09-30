using IterTools

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
function makeSmartTurn(grid, player::Int, timeLeft::Float64, currentTurn::Int)
    # in the beginning of the game maybe use a fixed set of moves so we dont waste time for shallow search
    posMoves = grid.possibleMoves()
    println("Turns left: ", length(posMoves) ÷ 2)
    println("Possible moves: ", length(posMoves))
    bestTurn = [posMoves[1], posMoves[2]]
    # println(bestTurn)
    # if game just started: put your own stones in the corner and the other ones in the middle
    gridOffset::Int = grid.getOffset()
    otherPlayer::Int = player == 1 ? 2 : 1
    # best opening move
    if currentTurn == 1
        bestTurn[player] = [2*gridOffset+1 gridOffset+1]
        bestTurn[otherPlayer] = [gridOffset+1 gridOffset+1]
        grid.setGridValue!(bestTurn[player][1], bestTurn[player][2], player+1)
        grid.setGridValue!(bestTurn[otherPlayer][1], bestTurn[otherPlayer][2], otherPlayer+1)
    elseif currentTurn < 6
        # bottem right corner
        if [2*gridOffset+1, gridOffset+1] in posMoves
            bestTurn[player] = [2*gridOffset+1, gridOffset+1]
        # bottom left corner
        elseif [2*gridOffset+1, 1] in posMoves
            bestTurn[player] = [2*gridOffset+1, 1]
        # middle right
        elseif [gridOffset+1, 2*gridOffset+1] in posMoves
            bestTurn[player] = [gridOffset+1, 2*gridOffset+1]
        # middle left
        elseif [gridOffset+1, 1] in posMoves
            bestTurn[player] = [gridOffset+1, 1]
        # top right
        elseif [1, gridOffset+1] in posMoves
            bestTurn[player] = [1, gridOffset+1]
        # top left
        elseif [1, 1] in posMoves
            bestTurn[player] = [1, 1]
        end
        bestTurn[otherPlayer] = posMoves[length(posMoves) ÷ 2]
        grid.setGridValue!(bestTurn[player][1], bestTurn[player][2], player+1)
        grid.setGridValue!(bestTurn[otherPlayer][1], bestTurn[otherPlayer][2], otherPlayer+1)
    else
        # TODO make smart time management (when the game is more advanced it requires less time to search)
        # --> in the beginning do bigger search, later less needed
        timeForTurns = timeLeft - 20
        aiTurns = (length(posMoves) ÷ 2 + 1) ÷ 2
        # the last 3 AIturns require about 15s and always reach the end
        # --> they get the whole time (no need for management)
        if aiTurns <= 3
            timeForThisTurn = 15.0
        else
            # the current turn requires the most time
            timeForThisTurn = timeForTurns/(aiTurns - 3)
        end
        println("Time for Turn ", currentTurn, ": ", timeForThisTurn)
        bestTurn = iterativeDeepening(grid, player, posMoves, timeForThisTurn)
        # get the best move and play it
        # first move is already done by iterative deepening
        grid.setGridValue!(bestTurn[2][1], bestTurn[2][2], 3)
    end


    println(PLAYERCOLORS[1], " stone set on (", bestTurn[1][1], ", ", bestTurn[1][2], ")")
    println(PLAYERCOLORS[2], " stone set on (", bestTurn[2][1], ", ", bestTurn[2][2], ")")
    grid.printBoard()

end

# returns the best turn
function iterativeDeepening(grid, player::Int, posMoves::Array, timeLeft::Float64)::Array{Array{Int, 1}}

    # create transpositionTable(hashmap)
    # TT looks the following: key=grid, value=Tuple(value, flag, searchDepth, bestTurn)
    transpositionTable = Dict{Int64, Tuple{Float64, Int, Int, Array}}()
    # println("Time left: ", timeLeft)
    let
    maxDepth = 1
    timeElapsed = 0.0
    while (timeElapsed < timeLeft) & (maxDepth < length(posMoves))
        # do alpha-beta-search
        initAlpha = -Inf
        initBeta = Inf
        startTime = time_ns()
        newValue = alphaBetaSearch(grid, transpositionTable, player, initAlpha, initBeta, maxDepth, posMoves, timeLeft-timeElapsed, false)
        println("Depth ", maxDepth, " took ", (time_ns()-startTime)/1.0e9,"s Best Value: ", newValue)
        # Write in hashmap
        timeElapsed += (time_ns()-startTime)/1.0e9
        maxDepth += 1
    end
    end

    # look up state in hashmap and return the best turn from it
    if haskey(transpositionTable, grid.getHash())
        # println("Got firstMove")
        _, _, _, firstMove = transpositionTable[grid.getHash()]
    else
        println("No firstMove in transpositionTable --> basic opening")
        _, _, _, firstMove = get(transpositionTable, grid.getHash(), (0.0, 0, 0, posMoves[1]))
    end
    # execute it and get next one move to finish a turn
    grid.setGridValue!(firstMove[1], firstMove[2], 2)
    if haskey(transpositionTable, grid.getHash())
        # println("Got secondMove")
        _, _, _, secondMove = transpositionTable[grid.getHash()]
    else
        println("No secondMove in transpositionTable --> basic opening")
        _, _, _, secondMove = get(transpositionTable, grid.getHash(), (0.0, 0, 0, posMoves[2]))
    end
    # println("Best Move: ", [firstMove, secondMove])

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
    otherPlayer = player == 1 ? 2 : 1
    oldAlpha = alpha
    value = -Inf # this needs to be outside the "if" because... Julia
    bestMove = posMoves[1]
    # look in transpositionTable for entry
    if haskey(transpositionTable, grid.getHash())
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
    if grid.getNumPosMoves() <= 1
        scores = grid.calculateScores()
        # println("EndScore: Player ",player, " - player ", otherPlayer," --> ", scores[player]-scores[otherPlayer])
        return scores[player]-scores[otherPlayer]
    # not yet gameOver, but max search depth
    elseif depth <= 0
        # TODO come up with a good heuristic
        # return a heuristic-value ("AN ADMISSABLE HEURISTIC NEVER OVERESTIMATES!" - Helmar Gust)
        approximation = grid.heuristic()
        return approximation[player] - approximation[otherPlayer]
        # approximation = grid.calculateScores()
        # return approximation[player] - approximation[otherPlayer]

    # continue searching
    else
        startTime = time_ns()
        # for all possible TURNS: execute them all
        for (index, move) in enumerate(posMoves)
            # if no time left
            if timeLeft <= (time_ns()-startTime)/1.0e9
                # println("Not time left --> no write in transpositionTable at this depth")
                return value
            end
            # do deeper search there
            # Other player's turn
            if firstStoneSet
                grid.setGridValue!(move[1], move[2], 3)
                newValue = -alphaBetaSearch(grid, transpositionTable, otherPlayer, -beta, -alpha, depth-1, posMoves[1:end .!= index], timeLeft-(time_ns()-startTime)/1.0e9, false)
            # same player's turn, but other stone
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
