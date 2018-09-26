import Base:convert

using Printf
using DataStructures

function Grid()
    grid = Array{Int8}
    offset = 0
    numPossibleMoves = 0

    # The grid is saved as an array with default value 0. The allowed hexagons are where a 1 is.
    function initializeGrid(gridSize::Int)
        grid = zeros(Int8, 2*gridSize-1,2*gridSize-1)
        q_shift = gridSize-1
        for row in range(1, stop=size(grid)[1])
            # print(q_shift)
            for col = max(1, q_shift+1):min(length(grid[row, :]),length(grid[row, :])+q_shift)
                grid[row, col] = 1
                numPossibleMoves += 1
            end
            q_shift = q_shift - 1
        end
        offset = Int((size(grid)[1]-1)/2)
        # # println(length(size(hexarray)))
        # return hexarray
    end

    # getter for getting value of hexgrid
    function getGridValue(row::Int, col::Int)::Int8
        @assert row >= 0 "row can't be smaller than 0"
        @assert col >= 0 "col can't be smaller than 0"
        # if something is asked that is outside the grid
        if (row > size(grid)[1]) || (col > size(grid)[2]) || (row == 0) || (col == 0)
            return 0
        elseif col+max(0, offset-(row-1)) > size(grid)[2]
            return 0
        else
            return grid[row, col+max(0, offset-(row-1))]
        end
    end

    # set function for the grid
    function setGridValue!(row::Int, col::Int, value)
        @assert row >= 0 "row can't be smaller than 0"
        @assert col >= 0 "col can't be smaller than 0"
        # if something is asked that is outside the grid
        if (row > size(grid)[1]) || (col > size(grid)[2]) || (row == 0) || (col == 0)
            return 0
        elseif col+max(0, offset-(row-1)) > size(grid)[2]
            return 0
        elseif value > 1
            grid[row, col+max(0, offset-(row-1))] = value
            numPossibleMoves -= 1
            # TODO introduce a GROUPS variable that gets updated?
            return grid
        else
            grid[row, col+max(0, offset-(row-1))] = value
            numPossibleMoves += 1
        end
    end

    function printArray(a)
        for row = 1:size(a)[1]
            println(a[row,:])
        end
    end

    function printBoard()
        # PLAYERCOLORS = ["W", "B", "R", "G"]
        for row = 1:size(grid)[1]
            @printf("%2.0f : ", row)
            # indentation needed for lower half of grid
            indent = "  "
            toShift = Int(max(0, row-(size(grid)[1]+1)/2))
            print(indent ^ toShift) # ^ operator calls repeat function

            for val in grid[row,:]
                if val == 0
                    print(indent)
                elseif val>=2 && val <=5
                    print(" ", PLAYERCOLORS[val-1], indent)
                else
                    # Free field (used to be val)
                    print(" ", "\U2B22", indent)
                end
            end
            println()
        end
    end


    # useful function to count occurences of a number in array
    function countNum(pred::Int, a::Array)::Int
        n = 0
        for i in eachindex(a)
            @inbounds n += pred == a[i]
        end
        return n
    end

    # TODO have a counter that has the number of free tiles and dex/inc when setting
    # check whether another round can be played
    function gameOver(players::Int)::Bool
        # freeHexagons = countNum(1, grid)
        # println("Free hexes: ", freeHexagons, " needed Moves: ", players^2)
        return numPossibleMoves < players^2
    end

    # list all possible moves
    function possibleMoves()::Array
        moves = []
        for row = 1:size(grid)[1]
            for col = 1:size(grid)[1]
                value = getGridValue(row, col)
                if value == 0
                    break
                elseif value == 1
                    push!(moves, [row col])
                end
            end
        end
        return moves
    end

    # hard coding is faster than a for-loop
    function getNeighbors(row::Int, col::Int)::Array
        # The order is the following: left, right, top left, top right, bottom left, bottom right
        IN = [[ 0, -1],                    # left
              [ 0,  1],                    # right
              [-1, -1*Int(row <= offset)], # top left
              [-1,  1*Int(row > offset)],  # top right
              [ 1, -1*Int(row >= offset)], # bottom left
              [ 1,  1*Int(row < offset)]]  # bottom right
        neighbors = [[row+IN[1][1], col+IN[1][2]],
                     [row+IN[2][1], col+IN[2][2]],
                     [row+IN[3][1], col+IN[3][2]],
                     [row+IN[4][1], col+IN[4][2]],
                     [row+IN[5][1], col+IN[5][2]],
                     [row+IN[6][1], col+IN[6][2]]
                    ]
        return neighbors
    end

    function calculateScores(numPlayers)::Array{Float64}
        scores = [1.0, 1.0, 1.0, 1.0]
        # create a copy of the current grid and check groups
        gridSize = size(grid)[1]
        gridCopy = copy(grid)
        for row = 1:gridSize
            for col = 1:gridSize
                gridValue = getGridValue(row, col)
                if gridValue == 0
                    break
                elseif gridValue > 1
                    scores[gridValue-1] *= checkGroup(row, col, gridValue)
                    # check if neighbors belong to same group and make this field free
                end
            end
        end
        grid = gridCopy
        return scores
    end

    # calculates the size of the group of the value
    # NOTE: THIS CHANGES THE GIVEN ARRAY!!!
    function checkGroup(row::Int, col::Int, value::Int8)::Float64
        # if the new field is not of the same player --> stop
        if getGridValue(row, col) != value
            return 0.0
        else # otherwise set it free and look whether there are more belonging to the group
            # TODO check whether calculations are still correct in big groups
            # --> may overwrite each other
            # grid = copy(hexgrid)
            setGridValue!(row, col, 1)
            groupSize = 0.0
            neighbors = getNeighbors(row, col)
            for n in neighbors
                groupSize += checkGroup(n[1], n[2], value)
            end
            return 1.0 + groupSize
        end
    end

    # hardcoding requires less memory
    function getNumFreeNeighbors(row::Int, col::Int)::Int
        neighbors = getNeighbors(row, col)
        total = (Int(getGridValue(neighbors[1][1], neighbors[1][2])==1) +
                Int(getGridValue(neighbors[2][1], neighbors[2][2])==1) +
                Int(getGridValue(neighbors[3][1], neighbors[3][2])==1) +
                Int(getGridValue(neighbors[4][1], neighbors[4][2])==1) +
                Int(getGridValue(neighbors[5][1], neighbors[5][2])==1) +
                Int(getGridValue(neighbors[6][1], neighbors[6][2])==1))
        return total
    end

    function heuristic()::Array{Float64}
        # idea: go over the array and count the free spaces for every player
        # TODO calc num of safe groups : a safe group exists when the stones have no free neighbors and borders with its own color
        freeSpaces = [0.0, 0.0, 0.0]

        gridSize = size(grid)[1]
        for row = 1:gridSize
            for col = 1:gridSize
                gridValue = getGridValue(row, col)
                if gridValue == 0
                    break
                end
                numFree = getNumFreeNeighbors(row, col)
                freeSpaces[gridValue] += numFree
                if numFree == 0
                    # check if it has neighbors of same color group / add somewhere
                end
            end
        end
        return freeSpaces
    end

# these functions will be exported
() -> (initializeGrid;
       getGridValue;
       setGridValue!;
       printBoard;
       printArray;
       gameOver;
       possibleMoves;
       getNeighbors;
       calculateScores;
       heuristic)
end


    const global PLAYERCOLORS = ["\U2715", "\U25B3", "\U26C4", "\U2661"]
    myGrid = Grid()
    myGrid.initializeGrid(5)
    myGrid.setGridValue!(1, 1, 2)
    myGrid.setGridValue!(1, 2, 2)
    myGrid.setGridValue!(1, 3, 2)
    myGrid.setGridValue!(1, 5, 2)
    myGrid.setGridValue!(2, 6, 2)
    myGrid.setGridValue!(3, 1, 2)
    myGrid.setGridValue!(3, 2, 2)
    myGrid.setGridValue!(5, 1, 2)
    myGrid.setGridValue!(5, 4, 3)
    myGrid.setGridValue!(5, 5, 3)
    myGrid.setGridValue!(5, 6, 3)
    myGrid.setGridValue!(6, 3, 3)
    myGrid.setGridValue!(7, 1, 3)
    myGrid.setGridValue!(7, 2, 3)
    myGrid.setGridValue!(9, 3, 3)
    myGrid.setGridValue!(9, 4, 3)
    myGrid.printBoard()
    # myGrid.calculateScores(2)
    @time myGrid.calculateScores(2)
    @time myGrid.heuristic()
    myGrid.printBoard()

    # @time getNumFreeNeighbors(grid, 1 , 3)
    # println(getNumFreeNeighbors(grid, 1, 3))
    # @time getNeighbors(grid, 5, 5)
    # println("Neighbors of 5 5: ", getNeighbors(grid, 5, 5))
    # println("Scores: ", calculateScores(grid, 2))
    # println("heuristic: ", heuristic(grid))
    # posMoves = [[1,1],[1,2],[1,3],[2,1],[2,2],[2,3]]
    # posTurns = [[i, j] for i in posMoves for j in posMoves if i!=j]
    # println("Length: ", length(posTurns))
    # println(posTurns)
