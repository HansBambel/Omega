include("grid.jl")
include("humanPlayer.jl")
include("randomPlayer.jl")

# https://unicode-table.com/en/

# const global PLAYERCOLORS = ["W", "B", "R", "G"]
const global PLAYERCOLORS = ["\U2715", "\U25B3", "\U26C4", "\U2661"]
players = 2
gridSize = 4
if length(ARGS) == 0
    print(" How big shall the grid be? Should be between 5-10: ")
    gridSize = parse(Int, chomp(readline()))
    # print(" How many players? ")
    # players = parse(Int, chomp(readline()))
elseif length(ARGS) == 1
    gridSize = parse(Int, ARGS[1])
    print(" How many players? ")
    players = parse(Int, chomp(readline()))
elseif length(ARGS) == 2
    gridSize = parse(Int, ARGS[1])
    players = parse(Int, ARGS[2])
end

hexgrid = initializeGrid(gridSize)

printBoard(hexgrid)

# TODO ask whether human goes first or second
# NOTE AI needs to know which player it is (2, 3, 4, 5) to maximize
turn = 0
while(!gameOver(hexgrid, players))
    # each player after the other
    for p in 1:players
        global turn += 1
        # Player 1 Turn
        println("####   TURN ", turn, ": PLAYER ", PLAYERCOLORS[p], "   ####")
        # if p == 1
        #     makeTurn(hexgrid, players)
        # else
        makeRandomTurn(hexgrid, players)
        # end
        # print current board --> moved to players
        # # Player 2 Turn
        # println("####   TURN: PLAYER 2   ####")
        # makeTurn(hexgrid, players)
        # # print current board
    end
end
println("### Game ended ###")
scores = calculateScores(hexgrid)
println("Scores: ")
for p in 1:players
    println(PLAYERCOLORS[p], " has scored: ", scores[p], " points")
end
# print Scores and declare winner
