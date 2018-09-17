import Base:convert

using Printf

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
                print(" ", "\U2B23", indent)
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
function getGridValue(grid::Array, row::Int, col::Int)
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
        return grid
    end
end

# useful function to count occurences of a number in array
function countNum(pred::Int, a::Array)
    n = 0
    for i in eachindex(a)
        @inbounds n += pred == a[i]
    end
    return n
end

# check whether another round can be played
function gameOver(hexgrid::Array, players::Int)
    freeHexagons = countNum(1, hexgrid)
    # println("Free hexes: ", freeHexagons, " needed Moves: ", players^2)
    return freeHexagons < players^2
end

# list all possible moves
# NOTE maybe make this array from the beginning and remove the made move
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

function getNeighbors(grid:: Array, row::Int, col::Int)
    offset = Int((size(grid)[1]+1)/2)
    # The order is the following: left, right, top left, top right, bottom left, bottom right
    IMMEDIATE_NEIGHBORS = [[ 0, -1],                    # left
                           [ 0,  1],                    # right
                           [-1, -1*Int(row <= offset)], # top left
                           [-1,  1*Int(row > offset)],  # top right
                           [ 1, -1*Int(row >= offset)], # bottom left
                           [ 1,  1*Int(row < offset)]]  # bottom right
    # println("Hex: ", row, " ", col)
    # for n in IMMEDIATE_NEIGHBORS
    #     println("Neighbor ", " [", row+n[1],", ", col+n[2], "]")
    # end
    return [[row+n[1], col+n[2]] for n in IMMEDIATE_NEIGHBORS]
end


function calculateScores(hexgrid::Array, numPlayers)
    scores = [1, 1, 1, 1]
    # create a copy of the current grid and check groups
    gridSize = size(hexgrid)[1]
    for player = 2:numPlayers+1
        grid = copy(hexgrid)
        for row = 1:gridSize
            for col = 1:gridSize
                gridValue = getGridValue(grid, row, col)
                if gridValue == 0
                    break
                elseif gridValue == player
                    scores[player-1] *= checkGroup(grid, row, col, player)
                    # check if neighbors belong to same group and make this field free
                end
            end
        end
    end
    return scores
end

# calculates the size of the group of the value
# NOTE: THIS CHANGES THE GIVEN ARRAY!!!
function checkGroup(hexgrid::Array, row, col, value)
    # if the new field is not of the same player --> stop
    if getGridValue(hexgrid, row, col) != value
        return 0
    else # otherwise set it free and look whether there are more belonging to the group
        # TODO check whether calculations are still correct in big groups
        # --> may overwrite each other
        # grid = copy(hexgrid)
        setGridValue!(hexgrid, row, col, 1)
        groupSize = 0
        neighbors = getNeighbors(hexgrid, row, col)
        for n in neighbors
            groupSize += checkGroup(hexgrid, n[1], n[2], value)
        end
        return 1 + groupSize
    end
end
