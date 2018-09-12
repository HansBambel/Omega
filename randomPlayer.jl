# include("grid.jl")
# include("main.jl")
# const global PLAYERCOLORS = ["\U2715", "\U25B3", "\U26C4", "\U2661"]

function makeRandomTurn(grid::Array, players::Int)
    # for every player-color
    # enumerate possible moves
    posMoves = possibleMoves(grid)
    # get a n-players possible moves from the list
    chosenMoves = posMoves[rand(1:length(posMoves), players)]
    for p in 1:players
        setGridValue!(grid, chosenMoves[p][1], chosenMoves[p][2], p+1)
        println(PLAYERCOLORS[p], " stone set on (", chosenMoves[p][1], ", ", chosenMoves[p][2], ")")
    end
    printBoard(grid)

end

function possibleMoves(hexgrid::Array)
    moves = []
    for row = 1:size(hexgrid)[1]
        for col = 1:size(hexgrid)[1]
            value = getGridValue(hexgrid, row, col)
            if value == 0
                break
            elseif value == 1
                push!(moves, [row col])
            end
        end
    end
    return moves
end
