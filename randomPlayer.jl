# include("grid.jl")
# include("main.jl")
using Random
# const global PLAYERCOLORS = ["\U2715", "\U25B3", "\U26C4", "\U2661"]

function makeRandomTurn(grid::Array, players::Int)
    # for every player-color
    # enumerate possible moves
    posMoves = possibleMoves(grid)
    # println("posMoves: ", posMoves)

    # get a n-players possible moves from the list
    chosenMoves = posMoves[randperm(length(posMoves))[1:players]]
    for p in 1:players
        setGridValue!(grid, chosenMoves[p][1], chosenMoves[p][2], p+1)
        println(PLAYERCOLORS[p], " stone set on (", chosenMoves[p][1], ", ", chosenMoves[p][2], ")")
    end
    printBoard(grid)

end
