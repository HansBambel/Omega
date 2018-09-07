import Base:convert

# Create a hexagonal grid of size SIZE
# https://github.com/GiovineItalia/Hexagons.jl/blob/master/src/Hexagons.jl

struct HexagonAxial# <: Hexagon
    q::Int
    r::Int
end

struct HexagonCubic# <: Hexagon
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

##### Initializing #####
# https://www.redblobgames.com/grids/hexagons/#map-storage
# use cube coordinates x, y, z where x+y+z=0

SIZE = 5
map_radius = SIZE-1

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

hexgrid = initializeGrid(5)
hexgrid[5, 5] = 5
printArray(hexgrid)

printBoard(hexgrid)
