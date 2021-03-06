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
    # Random.seed!(42)
    grid = Array{Int}
    gridMapping = Dict{Array{Int, 1}, Int}()
    gridMappingBackwards = Array{Array{Int, 1}, 1}()
    groups = Array{Int}
    groupSize = Array{Int}
    offset::Int = 0
    numPossibleMoves::Int = 0
    maxNumberMoves::Int = 0
    currentHash::Int64 = 1337
    playerSwap::Int64 = 1
    hashArray = Array
    history = Array{Array{Array{Array{Int64,1},1},1},1}(undef, 1)

    function getArray()::Array{Array{Int, 1},1}
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
                push!(gridMappingBackwards, [row, mapCol])
                mapCol += 1
            end
            q_shift = q_shift - 1
        end
        offset = Int((size(grid)[1]-1)/2)
        for i = 1:2*gridSize-1
            for j = 1:2*gridSize-1
                for k = 1:3
                    hashArray[i, j, k] = rand(Int64)
                end
            end
        end
        maxNumberMoves = numPossibleMoves
        currentHash = rand(Int64)
        playerSwap = rand(Int64)
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
            return @inbounds grid[row, col+max(0, offset-(row-1))]
        end
    end

    # set function for the grid
    function setGridValue!(row::Int, col::Int, value::Int)
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
            # oldValue = getGridValue(row, col)
            oldValue = grid[row, col+max(0, offset-(row-1))]
            currentHash = currentHash ⊻ hashArray[row, col, oldValue]
            currentHash = currentHash ⊻ hashArray[row, col, value]

            @inbounds grid[row, col+max(0, offset-(row-1))] = value
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

    function changePlayer()
        currentHash = currentHash ⊻ playerSwap
    end

    function unifySameNeighbors(hexfield::Array{Int}, value::Int)
        neighbors = getNeighbors(hexfield[1], hexfield[2])
        sameNeighbors = [n for n in neighbors if getGridValue(n[1], n[2]) == value]
        for n in sameNeighbors
            union(hexfield, n, value-1)
        end
    end

    function union(x::Array{Int}, y::Array{Int}, player::Int)
        xRoot = findRoot(gridMapping[x], player)
        yRoot = findRoot(gridMapping[y], player)

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

    function findRoot(x::Int, player::Int)::Int
        # union find with path splitting:
        while groups[player][x] != x
            x, groups[player][x] = groups[player][x], groups[player][groups[player][x]]
        end
        return x
    end

    function getHash()::Int64
        return currentHash
    end

    function getOffset()::Int
        return offset
    end

    function getNumPosMoves()::Int
        return numPossibleMoves
    end

    function getMaxNumMoves()::Int
        return maxNumberMoves
    end

    function printArray()
        for row = 1:size(grid)[1]
            println(grid[row,:])
        end
    end

    function printBoard()
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
    function possibleMoves()::Array{Array{Int,1},1}
        moves = []
        for row = 1:size(grid)[1]
            for col = 1:size(grid)[1]
                value = getGridValue(row, col)
                if value == 0
                    break
                elseif value == 1
                    push!(moves, [row, col])
                end
            end
        end
        return moves
    end

    # hard coding is faster than a for-loop
    function getNeighbors(row::Int, col::Int)::Array{Array{Int, 1}, 1}
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

    function calculateScores()::Array{Float64}
        # multiplies the groupSizes (aka the size that is in each root) of each player together
        scoreP1 = prod([groupSize[1][g] for g in Set(groups[1])])
        scoreP2 = prod([groupSize[2][g] for g in Set(groups[2])])
        return [scoreP1, scoreP2]
    end

    # hardcoding requires less memory
    function getNumNeighborsWithValue(row::Int, col::Int, value::Int)::Int64
        neighbors = getNeighbors(row, col)
        total = (Int(getGridValue(neighbors[1][1], neighbors[1][2])==value) +
                Int(getGridValue(neighbors[2][1], neighbors[2][2])==value) +
                Int(getGridValue(neighbors[3][1], neighbors[3][2])==value) +
                Int(getGridValue(neighbors[4][1], neighbors[4][2])==value) +
                Int(getGridValue(neighbors[5][1], neighbors[5][2])==value) +
                Int(getGridValue(neighbors[6][1], neighbors[6][2])==value))
        return total
    end

    function getFreeFieldsAroundGroup(hex::Array{Int, 1}, seen::Array{Array{Int,1}, 1})::Float64
        freeFields = 0.0
        hexValue = getGridValue(hex[1], hex[2])
        neighbors = getNeighbors(hex[1], hex[2])
        for n in neighbors
            nValue = getGridValue(n[1], n[2])
            if nValue == 1
                freeFields += 1.0
            elseif (nValue == hexValue) & !(n in seen)
                freeFields += getFreeFieldsAroundGroup(n, push!(seen, n))
            end
        end
        return freeFields
    end

    function getFreeFieldsAroundGroup(hex::Array{Int, 1})::Float64
        freeFields = 0.0
        hexValue = getGridValue(hex[1], hex[2])
        neighbors = getNeighbors(hex[1], hex[2])
        for n in neighbors
            nValue = getGridValue(n[1], n[2])
            if nValue == 1
                freeFields += 1.0
            elseif nValue == hexValue
                freeFields += getFreeFieldsAroundGroup(n, [hex, n])
            end
        end
        return freeFields
    end

    function heuristic()::Array{Float64}
        # just look at the number of 2-3 groups and substract the surrounding free tiles as punishment
        freeFields1 = 0.0
        freeFields2 = 0.0
        # get groups of 2 and 3 and their roots
        roots1Mask = (groupSize[1] .== 2) .| (groupSize[1] .== 3)
        roots1 = findall(roots1Mask)
        roots2Mask = (groupSize[2] .== 2) .| (groupSize[2] .== 3)
        roots2 = findall(roots2Mask)
        # go through roots and check how many free tiles are around that group
        # the minus 2 is the least number of overlapping tiles (groups of 3 have 3-4 overlapping)
        # if there are no free fields he'll get a bonus of 2 even! (we want to encourage safe groups)
        for r in roots1
            @inbounds hex = gridMappingBackwards[r]
            freeFields1 += getFreeFieldsAroundGroup(hex)-2.0
        end
        for r in roots2
            @inbounds hex = gridMappingBackwards[r]
            freeFields2 += getFreeFieldsAroundGroup(hex)-2.0
        end
        # multiply the optimal groups and substract the freefields as punishment
        # IDEA maybe also the others?
        player1Score = prod(groupSize[1][roots1Mask]) - freeFields1
        player2Score = prod(groupSize[2][roots2Mask]) - freeFields2
        return [player1Score, player2Score]
    end

    # these functions will be exported
    () -> (getArray;
           getNumPosMoves;
           getMaxNumMoves;
           initializeGrid;
           getGridValue;
           setGridValue!;
           changePlayer;
           printBoard;
           printArray;
           gameOver;
           getHash;
           possibleMoves;
           calculateScores;
           heuristic;
           getNeighbors;
           checkGroup;
           getFreeFieldsAroundGroup;
           getOffset;
           groups;
           groupSize;
           history)
end
