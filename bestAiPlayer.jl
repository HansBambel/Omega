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
function BestAI()
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
            bestTurn[player] = [2*gridOffset+1, gridOffset+1]
            bestTurn[otherPlayer] = [gridOffset+1, gridOffset+1]
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
            # make smart time management (when the game is more advanced it requires less time to search)
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
        # for every depth I save two killermoves (moves that produced a cut off)
        killerMoves = Array{Array{Array{Int, 1}, 1}, 1}()
        # println("Time left: ", timeLeft)
        let
        maxDepth = 1
        timeElapsed = 0.0
        while (timeElapsed < timeLeft) & (maxDepth < length(posMoves))
            global movesInvestigated = 0
            pushfirst!(killerMoves, [])
            # do alpha-beta-search
            initAlpha = -Inf
            initBeta = Inf
            startTime = time_ns()
            newValue, _ = alphaBetaSearch(grid, transpositionTable, player, initAlpha, initBeta, maxDepth, true, posMoves, killerMoves, timeLeft-timeElapsed, false)
            _, _, _, firstMove = get(transpositionTable, grid.getHash(), (-Inf, 0, 0, posMoves[1]))
            grid.setGridValue!(firstMove[1], firstMove[2], 2)
            bestValue, _, _, _ = get(transpositionTable, grid.getHash(), (-Inf, 0, 0, posMoves[1]))
            grid.setGridValue!(firstMove[1], firstMove[2], 1)
            println("Depth ", maxDepth, " took ", (time_ns()-startTime)/1.0e9,"s Best Value: ", bestValue, " Moves investigated: ", movesInvestigated)
            timeElapsed += (time_ns()-startTime)/1.0e9
            maxDepth += 1
        end
        end

        # println("KillerMoves: ", killerMoves)
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
                             doNull::Bool,
                             posMoves::Array,
                             killerMoves::Array{Array{Array{Int, 1}, 1}, 1},
                             timeLeft::Float64,
                             firstStoneSet::Bool)::Tuple{Float64, Bool}
        otherPlayer = player == 1 ? 2 : 1
        oldAlpha = alpha
        value = -Inf # this needs to be outside the "if" because... Julia
        bestMove = posMoves[1]
        move_ordering::Array{Array{Int,1},1} = []
        # look in transpositionTable for entry
        if haskey(transpositionTable, grid.getHash())
            ttValue, ttFlag, ttDepth, ttMove = transpositionTable[grid.getHash()]
            # check if we already have been here and get info
            if ttDepth >= depth
                if ttFlag == EXACT
                    return ttValue, false
                elseif ttFlag == LOWER
                    alpha = max(alpha, ttValue)
                elseif ttFlag == UPPER
                    beta = min(beta, ttValue)
                end

                if alpha >= beta
                    return ttValue, false
                end
            end
            if ttMove in posMoves
                push!(move_ordering, ttMove)
            end
        end
        # IDEA more move ordering? Null move + Multi-cut? History heuristic? --> PVS/Aspriation search (delta ~10?) (PVS needs good moveordering)?

        # if no possible move --> gameover (terminal state)
        if grid.getNumPosMoves() <= 1
            scores = grid.calculateScores()
            return scores[player]-scores[otherPlayer], false
        # not yet gameOver, but max search depth
        elseif depth <= 0
            # "AN ADMISSABLE HEURISTIC NEVER OVERESTIMATES!" - Helmar Gust
            score = grid.calculateScores()
            heuristicScore = grid.heuristic()
            # the less moves are available (lategame) the more the current score counts
            approximation = score/grid.getNumPosMoves() + heuristicScore*(1.0-1.0/grid.getNumPosMoves())
            return approximation[player] - approximation[otherPlayer], false

        # continue searching
        else
            startTime = time_ns()
            timeOut = false
            # do move ordering here
            # Killermoves (stored in reverse order: KillerMoves = [kmovesDepth3, kmovesDepth2, kmovesDepth1])
            # this is due to iterative deepening: when the maxsearchdepth is increased the first depth not be 1 any more, but 2 and so on
            if length(killerMoves[end-(depth-1)]) == 1
                if killerMoves[end-(depth-1)][1] in posMoves
                    push!(move_ordering, killerMoves[end-(depth-1)][1])
                end
            elseif length(killerMoves[end-(depth-1)]) == 2
                # check whether the stored killer move is currently possible
                if killerMoves[end-(depth-1)][1] in posMoves
                    push!(move_ordering, killerMoves[end-(depth-1)][1])
                end
                if killerMoves[end-(depth-1)][2] in posMoves
                    push!(move_ordering, killerMoves[end-(depth-1)][2])
                end
            end
            # this places the important moves at the front and the rest in the back
            move_ordering = vcat(move_ordering, posMoves)
            # this eliminates all duplicates
            move_ordering = unique(move_ordering)

            ### Do Null move here ###
            R = 2
            newValue = -Inf
            if doNull #& (depth%2 == 0)
                # println("Apply null move!")
                grid.changePlayer()
                newValue, timeOut = alphaBetaSearch(grid, transpositionTable, otherPlayer, -beta, -alpha, depth-1-R, false, move_ordering, killerMoves, timeLeft-(time_ns()-startTime)/1.0e9, false)
                newValue = -newValue
                grid.changePlayer()
            end
            if newValue >= beta
                # println("Pruning!!")
                return beta, timeOut
            end

            ### Do multi-cut now ###
            if depth >= 4
                C = 3
                M = 10
                let
                c = 0
                for (index, move) in enumerate(move_ordering)
                    if index >= M
                        break
                    end
                    global movesInvestigated += 1
                    # do a move and check for the next M searches with lower search depth whether at least C prunings occur
                    if firstStoneSet
                        grid.setGridValue!(move[1], move[2], 3)
                        grid.changePlayer()
                        newValue, timeOut = alphaBetaSearch(grid, transpositionTable, otherPlayer, -beta, -alpha, depth-1-R, true, move_ordering[1:end .!= index], killerMoves, timeLeft-(time_ns()-startTime)/1.0e9, false)
                        newValue = -newValue
                        grid.changePlayer()
                    # same player's turn, but other stone (note that doNull is false)
                    else
                        grid.setGridValue!(move[1], move[2], 2)
                        newValue, timeOut = alphaBetaSearch(grid, transpositionTable, player, alpha, beta, depth-1-R, false, move_ordering[1:end .!= index], killerMoves, timeLeft-(time_ns()-startTime)/1.0e9, true)
                    end
                    if newValue >= beta
                        c += 1
                        if c >= C
                            # undo move
                            grid.setGridValue!(move[1], move[2], 1)
                            # println("multi cut pruning!")
                            return beta, timeOut
                        end
                    end
                    # undo the move
                    grid.setGridValue!(move[1], move[2], 1)
                end
                end
            end

            ### regular alpha-beta search ###
            # for all possible turns: execute them all
            for (index, move) in enumerate(move_ordering)
                # check every 1000 moves
                if movesInvestigated%1000 == 0
                    # if no time left
                    if timeLeft <= (time_ns()-startTime)/1.0e9
                        # println("Not time left --> no write in transpositionTable at this depth")
                        return value, true
                    end
                end
                global movesInvestigated += 1
                # do deeper search there
                # Other player's turn
                if firstStoneSet
                    grid.setGridValue!(move[1], move[2], 3)
                    grid.changePlayer()
                    newValue, timeOut = alphaBetaSearch(grid, transpositionTable, otherPlayer, -beta, -alpha, depth-1, true, move_ordering[1:end .!= index], killerMoves, timeLeft-(time_ns()-startTime)/1.0e9, false)
                    newValue = -newValue
                    grid.changePlayer()
                # same player's turn, but other stone (note that doNull is false)
                else
                    grid.setGridValue!(move[1], move[2], 2)
                    newValue, timeOut = alphaBetaSearch(grid, transpositionTable, player, alpha, beta, depth-1, false, move_ordering[1:end .!= index], killerMoves, timeLeft-(time_ns()-startTime)/1.0e9, true)
                end

                if newValue > value
                    bestMove = move
                    value = newValue
                end
                alpha = max(alpha, value)
                # prune --> no need to look at the other children
                if alpha >= beta
                    # add killermove if not already present
                    if !(move in killerMoves[end-(depth-1)])
                        if length(killerMoves[end-(depth-1)]) < 2
                            push!(killerMoves[end-(depth-1)], move)
                        else
                            killerMoves[end-(depth-1)][rand(1:2)] = move
                        end
                    end
                    grid.setGridValue!(move[1], move[2], 1)
                    break
                end

                # undo all the moves
                grid.setGridValue!(move[1], move[2], 1)
            end

            # Store (more accurate) result in transpositionTable if there did not occur a timeout
            # a result from a timeout would not be accurate and thus should not be stored
            if !timeOut
                if value <= oldAlpha
                    transpositionTable[grid.getHash()] = value, UPPER, depth, bestMove
                elseif value >= beta
                    transpositionTable[grid.getHash()] = value, LOWER, depth, bestMove
                else
                    transpositionTable[grid.getHash()] = value, EXACT, depth, bestMove
                end
            end

            # this is the value that alphaBeta/negamax returned
            return value, timeOut
        end
    end

    () -> (makeSmartTurn)
end
