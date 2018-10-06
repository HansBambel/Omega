
function makeTurn(grid, players::Int)
    # for every player-color
    # ask for input and check whether it is a valid move
    humanMoves = Array{Array{Int,1},1}()
    for p in 1:players
        row, col = 0, 0
        while true
            # ASK player row + col
            println("Where should a stone of player ", PLAYERCOLORS[p], " be put? (Format: row, col or row col) ")
            humanInput = chomp(readline())
            try
                row, col = parse(Int, split(humanInput)[1]), parse(Int, split(humanInput)[end])
            catch
                row, col = 0, 0
            end
            # if valid hexfield --> leave while-loop
            if grid.getGridValue(row, col) == 1
                push!(humanMoves, [row, col])
                break
            end
            println("Please enter a valid Hexfield! It must be free and the indices between 1 and ", 2*grid.getOffset() +1, ".")
            # ask again

        end
        grid.setGridValue!(row, col, p+1)
        println(PLAYERCOLORS[p], " stone set on (", row, ", ", col, ")")
        grid.printBoard()
    end
    println("Are you ok with these moves? 'No' will undo them and you can enter new ones.")
    humanInput = chomp(readline())
    if (humanInput == "No") | (humanInput == "no")
        grid.setGridValue!(humanMoves[2][1], humanMoves[2][2], 1)
        grid.setGridValue!(humanMoves[1][1], humanMoves[1][2], 1)
        grid.printBoard()
        makeTurn(grid, players)
    end

end
