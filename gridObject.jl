import Base:convert

using Random
using Printf
using DataStructures

# useful function to count occurences of a number in array
function countNum(pred::Int, a::Array)::Int
    n = 0
    for i in eachindex(a)
        @inbounds n += pred == a[i]
    end
    return n
end


function Grid()
    Random.seed!(42)
    grid = Array{Int}
    gridMapping = Dict{Array{Int, 1}, Int}()
    groups = Array{Int}
    groupSize = Array{Int}
    offset = 0
    numPossibleMoves = 0
    currentHash = 1337
    hashArray = Array
    history = Array{Array{Array{Array{Int64,1},1},1},1}(undef, 1)

    function getArray()
        return grid
    end

    # The grid is saved as an array with default value 0. The allowed hexagons are where a 1 is.
    function initializeGrid(gridSize::Int)
        grid = zeros(Int, 2*gridSize-1,2*gridSize-1)
        hashArray = Array{Int64}(undef, 2*gridSize-1,2*gridSize-1,5)
        q_shift = gridSize-1
        for row in range(1, stop=size(grid)[1])
            mapCol = 1
            for col = max(1, q_shift+1):min(length(grid[row, :]),length(grid[row, :])+q_shift)
                grid[row, col] = 1
                numPossibleMoves += 1
                gridMapping[[row, mapCol]] = numPossibleMoves
                mapCol += 1
            end
            q_shift = q_shift - 1
        end
        offset = Int((size(grid)[1]-1)/2)
        for i = 1:2*gridSize-1
            for j = 1:2*gridSize-1
                for k = 1:5
                    hashArray[i, j, k] = rand(Int64)
                end
            end
        end
        currentHash = rand(Int64)
        groups = [collect(1:numPossibleMoves), collect(1:numPossibleMoves)]
        groupSize = [ones(Int, numPossibleMoves), ones(Int, numPossibleMoves)]
        history = [deepcopy([groups, groupSize])]
    end

    # getter for getting value of hexgrid
    function getGridValue(row::Int, col::Int)::Int
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
        else
            # update hash: current XOR old value XOR new value
            # remove old value from hashvalue and add new one
            oldValue = getGridValue(row, col)
            currentHash = currentHash ⊻ hashArray[row, col, oldValue]
            currentHash = currentHash ⊻ hashArray[row, col, value]

            grid[row, col+max(0, offset-(row-1))] = value
            if value > 1
                # look at neighbors and unify the ones with the same value --> unionfind
                numPossibleMoves -= 1
                unifySameNeighbors([row, col], value)
                # save this to history
                push!(history, [deepcopy(groups), deepcopy(groupSize)])
            else
                # delete the latest entry of history and get the previous one again
                pop!(history)
                previousEntry = deepcopy(last(history))
                groups, groupSize = previousEntry[1], previousEntry[2]
                numPossibleMoves += 1
            end
            return grid
        end
    end

    function unifySameNeighbors(hexfield::Array{Int}, value::Int)
        neighbors = getNeighbors(hexfield[1], hexfield[2])
        sameNeighbors = [n for n in neighbors if getGridValue(n[1], n[2]) == value]
        for n in sameNeighbors
            union(hexfield, n, value-1)
        end
        # println("New group:", groups)
        # println("groupsize: ", groupSize)
    end

    function union(x::Array{Int}, y::Array{Int}, player::Int)
        xRoot = find(gridMapping[x], player)
        # println("Found xroot: ", xRoot, " size: ", groupSize[player][xRoot])
        yRoot = find(gridMapping[y], player)
        # println("Found yroot: ", yRoot, " size: ", groupSize[player][yRoot])

        # if they are already in the same set --> stop
        if xRoot == yRoot
            return
        end
        # if y is the bigger group --> swap
        if groupSize[player][xRoot] < groupSize[player][yRoot]
            xRoot, yRoot = yRoot, xRoot
        end
        groups[player][yRoot] = xRoot
        groupSize[player][xRoot] = groupSize[player][xRoot]+groupSize[player][yRoot]
        groupSize[player][yRoot] = 1 # need to set the smaller groups size to one for score calculation
    end

    function find(x::Int, player::Int)::Int
        # path splitting:
        while groups[player][x] != x
            x, groups[player][x] = groups[player][x], groups[player][groups[player][x]]
        end
        return x
    end

    function getHash()
        return currentHash
    end

    function getNumPosMoves()
        return numPossibleMoves
    end

    function printArray()
        for row = 1:size(grid)[1]
            println(grid[row,:])
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

    # check whether another round can be played
    function gameOver(players::Int)::Bool
        return numPossibleMoves < players^2
    end

    # list all possible moves
    # TODO make it a list that gets updated at setindex
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
              [-1, -1*Int(row <= offset+1)], # top left
              [-1,  1*Int(row > offset+1)],  # top right
              [ 1, -1*Int(row > offset)], # bottom left
              [ 1,  1*Int(row <= offset)]]  # bottom right
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
        # println("Set1: ", Set(groups[1]))
        # group1 = [find(g, 1) for g in Set(groups[1])]
        # group2 = [find(g, 2) for g in Set(groups[2])]
        # println([find(g, 1) for g in Set(groups[1])])
        # [find(g, 1) for g in groups[1]]
        # [find(g, 2) for g in groups[2]]
        # println(typeof(Set(groups[1])))
        # println(groupSize[1])
        # println("Is node 12 in the same set as 3? ", find(12, 1) == find(3, 1))
        scores[1] = prod([groupSize[1][g] for g in Set(groups[1])])
        scores[2] = prod([groupSize[2][g] for g in Set(groups[2])])
        return scores
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
        # use have a counter for the groupsize
        freeSpaces = [0.0, 0.0]
        safeHexes = [Array{Tuple{Int,Int}, 1}(), Array{Tuple{Int, Int}, 1}()]
        safeGroups = [1.0, 1.0]

        ## Look in safeHexes and find safe groups
        println(safeHexes)
        for playerHexes in safeHexes
            checkSafeHexes(playerHexes)
        end
        return freeSpaces
    end

    function checkSafeHexes(safeHexes::Array{Tuple{Int, Int}})
        # look at entry (remove it?): check if neighbors are in list and repeat for them
    end

    function checkGroup(row::Int, col::Int, value::Int, seen::Array)::Float64
        # if the new field is not of the same player --> stop
        if (getGridValue(row, col) != value) | ([row, col] in seen)
            return 0.0
        else
            push!(seen, [row, col])
            # println("seen:", seen)
            size = 0.0
            neighbors = getNeighbors(row, col)
            for n in neighbors
                size += checkGroup(n[1], n[2], value, seen)
            end
            return 1.0 + size
        end
    end

    # these functions will be exported
    () -> (getArray;
           getNumPosMoves;
           initializeGrid;
           getGridValue;
           setGridValue!;
           printBoard;
           printArray;
           gameOver;
           possibleMoves;
           getNeighbors;
           calculateScores;
           heuristic;
           checkGroup;
           getHash;
           groups;
           groupSize;
           history)
end

# const global PLAYERCOLORS = ["\U2715", "\U25B3", "\U26C4", "\U2661"]
# myGrid = Grid()
# myGrid.initializeGrid(5)
# myGrid.setGridValue!(2,1,2)
# myGrid.setGridValue!(1,2,3)
# myGrid.printBoard()
# println(myGrid.calculateScores(2))
# # do alot of set and back
# myGrid.setGridValue!(1, 1, 2)
# myGrid.setGridValue!(2, 2, 2)
# myGrid.setGridValue!(3, 1, 2)
# myGrid.setGridValue!(3, 2, 2)
# myGrid.setGridValue!(4, 4, 3)
# myGrid.setGridValue!(2, 4, 3)
# myGrid.setGridValue!(3, 4, 3)
# myGrid.setGridValue!(3, 4, 3)
# myGrid.calculateScores(2)
# myGrid.setGridValue!(1, 1, 1)
# myGrid.setGridValue!(2, 2, 1)
# myGrid.setGridValue!(3, 1, 1)
# myGrid.setGridValue!(3, 2, 1)
# myGrid.setGridValue!(4, 4, 1)
# myGrid.setGridValue!(2, 4, 1)
# myGrid.setGridValue!(3, 4, 1)
# myGrid.setGridValue!(3, 4, 1)
#
# myGrid.setGridValue!(1,4,2)
# myGrid.setGridValue!(1,3,3)
# myGrid.printBoard()
# println(myGrid.calculateScores(2))
# myGrid.setGridValue!(2, 2, 2)
# myGrid.setGridValue!(1, 2, 3)
# println(myGrid.calculateScores(2))
#
# myGrid.setGridValue!(7, 3, 2)
# myGrid.setGridValue!(4, 7, 3)
# println(myGrid.calculateScores(2))
#
# myGrid.setGridValue!(4, 3, 2)
# myGrid.setGridValue!(3, 1, 3)
# println(myGrid.calculateScores(2))
#
# myGrid.setGridValue!(6, 4, 2)
# myGrid.setGridValue!(4, 5, 3)
# println(myGrid.calculateScores(2))
#
# myGrid.setGridValue!(2, 5, 2)
# myGrid.setGridValue!(6, 3, 3)
# println(myGrid.calculateScores(2))
#
# myGrid.setGridValue!(1, 1, 2)
# myGrid.setGridValue!(7, 2, 3)
# println(myGrid.calculateScores(2))
#
# myGrid.setGridValue!(7, 1, 2)
# myGrid.setGridValue!(4, 4, 3)
# println(myGrid.calculateScores(2))
#
# myGrid.setGridValue!(3, 2, 2)
# myGrid.setGridValue!(5, 1, 3)
# println(myGrid.calculateScores(2))
# println(myGrid.groupSize)
#
# myGrid.setGridValue!(2, 1, 2)
# myGrid.setGridValue!(5, 3, 3)
# println(myGrid.calculateScores(2))
# println(myGrid.groupSize)
# myGrid.printBoard()
# println()
