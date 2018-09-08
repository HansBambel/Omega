import Base:convert

# Create a hexagonal grid of size SIZE
# https://github.com/GiovineItalia/Hexagons.jl/blob/master/src/Hexagons.jl

struct HexagonAxial
    q::Int
    r::Int
end

struct HexagonCubic
    x::Int
    y::Int
    z::Int
end
# Constructors
hexagon(x::Int, y::Int, z::Int) = HexagonCubic(x, y, z)
hexagon(q::Int, r::Int) = HexagonAxial(q, r)

# Conversions
function convert(::Type{HexagonAxial}, hex::HexagonCubic)
    HexagonAxial(hex.x, hex.z)
end

function convert(::Type{HexagonCubic}, hex::HexagonAxial)
    HexagonCubic(hex.q, hex.r, -hex.q - hex.r)
end

function printArray(a)
    for row = 1:size(a)[1]
        println(a[row,:])
    end
end

function printBoard(a::Array)
    for row = 1:size(a)[1]
        print(row, ": ")
        # indentation needed for lower half of grid
        indent = "  "
        toShift = Int(max(0, row-(size(a)[1]+1)/2))
        print(indent ^ toShift) # ^ operator calls repeat function

        for val in a[row,:]
            if val == 0
                print(indent)
            else
                print(" ", val, indent)
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

##### Initializing #####

# TODO: add these when user input required
# print(" How big shall the grid be? Number between 5-10: ")
# gridSize = parse(Int, chomp(readline()))
# print(" How many players? ")
# players = parse(Int, chomp(readline()))
hexgrid = initializeGrid(5)
hexgrid[5, 5] = 5
hexgrid[9, 5] = 6
hexgrid[5, 8] = 7
hexgrid[6, 8] = 7
printArray(hexgrid)
printBoard(hexgrid)

getGridValue(hexgrid, 1, 1)

setGridValue!(hexgrid, 1, 1, 4)
getGridValue(hexgrid, 1, 1)

gameOver(hexgrid, 7)
