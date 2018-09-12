
function makeTurn(grid::Array, players::Int)
    # for every player-color
    # ask for input and check whether it is a valid move
    for p in 1:players
        row, col = 0, 0
        while true
            # ASK player row + col
            println("Where should a hex of player ", PLAYERCOLORS[p], " be put? (Format: row, col) ")
            humanInput = chomp(readline())
            row, col = parse(Int, split(humanInput)[1]), parse(Int, split(humanInput)[end])
            # if valid hexfield --> leave while-loop
            if getGridValue(grid, row, col) == 1
                break
            end
            println("Please enter a valid Hexfield! It must be free and the indices between 1 and ", size(grid)[1], ".")
            # ask again

        end
        setGridValue!(grid, row, col, p+1)
        println(PLAYERCOLORS[p], " stone set on (", row, ", ", col, ")")
        printBoard(grid)

    end

end
