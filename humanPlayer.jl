
function makeTurn(grid, players::Int)
    # for every player-color
    # ask for input and check whether it is a valid move
    for p in 1:players
        row, col = 0, 0
        while true
            # ASK player row + col
            # TODO if player enter "undo" (or something) UNDO last move
            println("Where should a stone of player ", PLAYERCOLORS[p], " be put? (Format: row, col or row col) ")
            humanInput = chomp(readline())
            try
                row, col = parse(Int, split(humanInput)[1]), parse(Int, split(humanInput)[end])
            catch
                row, col = 0, 0
            end
            # if valid hexfield --> leave while-loop
            if grid.getGridValue(row, col) == 1
                break
            end
            println("Please enter a valid Hexfield! It must be free and the indices between 1 and ", size(grid.getArray())[1], ".")
            # ask again

        end
        grid.setGridValue!(row, col, p+1)
        println(PLAYERCOLORS[p], " stone set on (", row, ", ", col, ")")
        grid.printBoard()

    end

end
