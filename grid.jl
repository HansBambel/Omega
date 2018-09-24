import Base:convert

using Printf
using DataStructures

function printArray(a)
    for row = 1:size(a)[1]
        println(a[row,:])
    end
end

function printBoard(a::Array)
    # PLAYERCOLORS = ["W", "B", "R", "G"]
    for row = 1:size(a)[1]
        @printf("%2.0f : ", row)
        # indentation needed for lower half of grid
        indent = "  "
        toShift = Int(max(0, row-(size(a)[1]+1)/2))
        print(indent ^ toShift) # ^ operator calls repeat function

        for val in a[row,:]
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

# The grid is saved as an array with default value 0. The allowed hexagons are where a 1 is.
function initializeGrid(gridSize::Int)
    hexarray = zeros(Int8, 2*gridSize-1,2*gridSize-1)
    q_shift = gridSize-1
    for row in range(1, stop=size(hexarray)[1])
        # print(q_shift)
        for col = max(1, q_shift+1):min(length(hexarray[row, :]),length(hexarray[row, :])+q_shift)
            hexarray[row, col] = 1
        end
        q_shift = q_shift - 1
    end
    # println(length(size(hexarray)))
    return hexarray
end

# getter for getting value of hexgrid
function getGridValue(grid::Array, row::Int, col::Int)::Int8
    @assert row >= 0 "row can't be smaller than 0"
    @assert col >= 0 "col can't be smaller than 0"
    offset = Int((size(grid)[1]-1)/2)
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
function setGridValue!(grid::Array, row::Int, col::Int, value)
    @assert row >= 0 "row can't be smaller than 0"
    @assert col >= 0 "col can't be smaller than 0"
    offset = Int((size(grid)[1]-1)/2)
    # if something is asked that is outside the grid
    if (row > size(grid)[1]) || (col > size(grid)[2]) || (row == 0) || (col == 0)
        return 0
    elseif col+max(0, offset-(row-1)) > size(grid)[2]
        return 0
    else
        grid[row, col+max(0, offset-(row-1))] = value
        # TODO introduce a GROUPS variable that gets updated?
        # TODO unionfind
        return grid
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

# check whether another round can be played
function gameOver(hexgrid::Array, players::Int)::Bool
    freeHexagons = countNum(1, hexgrid)
    # println("Free hexes: ", freeHexagons, " needed Moves: ", players^2)
    return freeHexagons < players^2
end

# list all possible moves
function possibleMoves(hexgrid::Array)::Array
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

# hard coding is faster than a for-loop
function getNeighbors(grid:: Array, row::Int, col::Int)::Array
    offset = Int((size(grid)[1]+1)/2)
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

function calculateScores(hexgrid::Array, numPlayers)::Array{Float64}
    scores = [1.0, 1.0, 1.0, 1.0]
    # create a copy of the current grid and check groups
    gridSize = size(hexgrid)[1]
        grid = copy(hexgrid)
        for row = 1:gridSize
            for col = 1:gridSize
                gridValue = getGridValue(grid, row, col)
                if gridValue == 0
                    break
                elseif gridValue > 1
                    scores[gridValue-1] *= checkGroup(grid, row, col, gridValue)#, [[0,0]])
                    # check if neighbors belong to same group and make this field free
                end
            end
        end
    return scores
end

# hardcoding requires less memory
function getNumFreeNeighbors(grid::Array, row::Int, col::Int)::Int
    neighbors = getNeighbors(grid, row, col)
    total = (Int(getGridValue(grid, neighbors[1][1], neighbors[1][2])==1) +
            Int(getGridValue(grid, neighbors[2][1], neighbors[2][2])==1) +
            Int(getGridValue(grid, neighbors[3][1], neighbors[3][2])==1) +
            Int(getGridValue(grid, neighbors[4][1], neighbors[4][2])==1) +
            Int(getGridValue(grid, neighbors[5][1], neighbors[5][2])==1) +
            Int(getGridValue(grid, neighbors[6][1], neighbors[6][2])==1))
    return total
end

function heuristic(grid::Array)::Array{Float64}
    # idea: go over the array and count the free spaces for every player
    # TODO calc num of safe groups : a safe group exists when the stones have no free neighbors and borders with its own color
    freeSpaces = [0.0, 0.0, 0.0]

    gridSize = size(grid)[1]
    for row = 1:gridSize
        for col = 1:gridSize
            gridValue = getGridValue(grid, row, col)
            if gridValue == 0
                break
            end
            numFree = getNumFreeNeighbors(grid, row, col)
            freeSpaces[gridValue] += numFree
            if numFree == 0
                # check if it has neighbors of same color group / add somewhere
            end
        end
    end
    return freeSpaces
end

function heuristic2(grid::Array)::Array{Float64}
    # idea: go over the array and count the free spaces for every player
    # TODO calc num of safe groups : a safe group exists when the stones have no free neighbors and borders with its own color
    # TODO have a counter for the groupsize
    freeSpaces = [0.0, 0.0]
    safeHexes = [Array{Tuple{Int,Int}, 1}(), Array{Tuple{Int, Int}, 1}()]
    safeGroups = [1.0, 1.0]

    gridSize = size(grid)[1]
    for row = 1:gridSize
        for col = 1:gridSize
            gridValue = getGridValue(grid, row, col)
            if gridValue == 0
                break
            elseif gridValue > 1
                numFree = getNumFreeNeighbors(grid, row, col)
                freeSpaces[gridValue-1] += numFree
                if numFree == 0
                    push!(safeHexes[gridValue-1], (row, col))
                    # check if it has neighbors of same color group / add somewhere
                end
            end
        end
    end
    ## Look in safeHexes and find safe groups
    println(safeHexes)
    for playerHexes in safeHexes
        checkSafeHexes(grid, playerHexes)
    end
    return freeSpaces
end

function checkSafeHexes(grid::Array, safeHexes::Array{Tuple{Int, Int}})
    # look at entry (remove it?): check if neighbors are in list and repeat for them
end

# calculates the size of the group of the value
# NOTE: THIS CHANGES THE GIVEN ARRAY!!!
function checkGroup(hexgrid::Array, row::Int, col::Int, value::Int8)::Float64
    # if the new field is not of the same player --> stop
    if getGridValue(hexgrid, row, col) != value
        return 0.0
    else # otherwise set it free and look whether there are more belonging to the group
        # TODO check whether calculations are still correct in big groups
        # --> may overwrite each other
        # grid = copy(hexgrid)
        setGridValue!(hexgrid, row, col, 1)
        groupSize = 0.0
        neighbors = getNeighbors(hexgrid, row, col)
        for n in neighbors
            groupSize += checkGroup(hexgrid, n[1], n[2], value)
        end
        return 1.0 + groupSize
    end
end

function checkGroup(hexgrid::Array, row::Int, col::Int, value::Int8, seen::Array)::Float64
    # if the new field is not of the same player --> stop
    if (getGridValue(hexgrid, row, col) != value) | ([row, col] in seen)
        return 0.0
    else # otherwise set it free and look whether there are more belonging to the group
        # TODO check whether calculations are still correct in big groups
        # --> may overwrite each other
        # grid = copy(hexgrid)
        push!(seen, [row, col])
        # println("seen:", seen)
        groupSize = 0.0
        neighbors = getNeighbors(hexgrid, row, col)
        for n in neighbors
            groupSize += checkGroup(hexgrid, n[1], n[2], value, seen)
        end
        return 1.0 + groupSize
    end
end

# startTime = time_ns()
# sleep(1)
# println((time_ns()-startTime)/1.0e9)
# d = SortedDict()
# d[2] = "name"
# d[8] = "is tom"
# d[1] = "my"
# d[1] = "toast"
# println(d)
# const global PLAYERCOLORS = ["\U2715", "\U25B3", "\U26C4", "\U2661"]
# grid = initializeGrid(5)
# setGridValue!(grid, 1, 1, 2)
# setGridValue!(grid, 1, 2, 2)
# setGridValue!(grid, 1, 3, 2)
# setGridValue!(grid, 1, 5, 2)
# setGridValue!(grid, 2, 6, 2)
# setGridValue!(grid, 3, 1, 2)
# setGridValue!(grid, 3, 2, 2)
# setGridValue!(grid, 5, 1, 2)
#
# setGridValue!(grid, 2, 1, 3)
# setGridValue!(grid, 2, 2, 3)
# setGridValue!(grid, 2, 3, 3)
# setGridValue!(grid, 2, 4, 3)
# setGridValue!(grid, 2, 5, 3)
# setGridValue!(grid, 3, 6, 3)
# setGridValue!(grid, 3, 7, 3)
# setGridValue!(grid, 1, 4, 3)
# setGridValue!(grid, 5, 4, 3)
# setGridValue!(grid, 5, 5, 3)
# setGridValue!(grid, 5, 6, 3)
# setGridValue!(grid, 6, 3, 3)
# setGridValue!(grid, 7, 1, 3)
# setGridValue!(grid, 7, 2, 3)
# setGridValue!(grid, 9, 3, 3)
# setGridValue!(grid, 9, 4, 3)
#
# # println("CheckGroup ", checkGroup(grid, 7, 1, Int8(3)))
# printBoard(grid)
# println("CheckGroup ", checkGroup(grid, 7, 1, Int8(3), [[0,0]]))
# # # @time getNumFreeNeighbors(grid, 1 , 3)
# # # println(getNumFreeNeighbors(grid, 1, 3))
# # # @time getNeighbors(grid, 5, 5)
# # # println("Neighbors of 5 5: ", getNeighbors(grid, 5, 5))
# @time calculateScores(grid, 2)
# @time calculateScores(grid, 2)
# println("Scores: ", calculateScores(grid, 2))
# @time heuristic(grid)
# @time heuristic(grid)
# println("heuristic: ", heuristic(grid))
# @time heuristic2(grid)
# @time heuristic2(grid)
# println("heuristic2: ", heuristic2(grid))
# posMoves = [[1,1],[1,2],[1,3],[2,1],[2,2],[2,3]]
# posTurns = [[i, j] for i in posMoves for j in posMoves if i!=j]
# println("Length: ", length(posTurns))
# println(posTurns)
