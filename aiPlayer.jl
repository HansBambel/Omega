include("grid.jl")

'''
grid is the field
numplayers is the number of players
player is the color the AI tries to maximize
time is the time left to compute
'''
function makeSmartMove(grid::Array, player::Int, timeLeft::Int)
    # what moves are available
    posMoves = possibleMoves(grid)

    maxDepth = 1
    timeElapsed = 0
    while timeElapsed < timeLeft
        # do alpha-beta-search
        bestMove = alphaBeta(grid, player, maxDepth)
    # get the best move and play it
    end
end

# returns the best move
function alphaBeta(grid::Array, player::Int, maxDepth::Int)

end

# returns values
function alphaBetaSearch(grid::Array, player::Int, alpha::Float64, beta::Float64, depth::Int)
    if depth <= 0 || gameOver(grid)
        scores = calculateScores(grid)
        otherPlayer = 2 ? player==1 : 1
        return scores[player]-scores[otherPlayer]
        # eval board
    else
        # NOTE MAKE a "turn" consist of moving twice --> reduces search breadth
        # get moves
        # do all of them
        # for all moves: execute all of them
        # undo all the moves
    end
end
