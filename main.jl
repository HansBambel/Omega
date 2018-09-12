include("grid.jl")
include("humanPlayer.jl")

const global PLAYERCOLORS = ["W", "B", "R", "G"]
players = 2
gridSize = 4
print(" How big shall the grid be? Should be between 5-10: ")
gridSize = parse(Int, chomp(readline()))
# print(" How many players? ")
# players = parse(Int, chomp(readline()))

hexgrid = initializeGrid(gridSize)
# setGridValue!(hexgrid, 7, 7, 2)
# setGridValue!(hexgrid, 3, 4, 2)
# setGridValue!(hexgrid, 4, 4, 2)
# setGridValue!(hexgrid, 4, 5, 2)
# setGridValue!(hexgrid, 5, 5, 2)
# setGridValue!(hexgrid, 7, 6, 2)
# setGridValue!(hexgrid, 8, 6, 2)
# setGridValue!(hexgrid, 9, 1, 2)
#
# setGridValue!(hexgrid, 5, 1, 3)
# setGridValue!(hexgrid, 5, 2, 3)
# setGridValue!(hexgrid, 5, 3, 3)
# setGridValue!(hexgrid, 6, 7, 3)
# setGridValue!(hexgrid, 6, 8, 3)
# setGridValue!(hexgrid, 2, 3, 3)
# setGridValue!(hexgrid, 1, 3, 3)
# setGridValue!(hexgrid, 1, 2, 3)
# printArray(hexgrid)

printBoard(hexgrid)
# println("Scores: ", calculateScores(hexgrid))

# TODO ask whether human goes first or second
# NOTE AI needs to know which player it is (2, 3, 4, 5) to maximize
while(!gameOver(hexgrid, players))
    # each player after the other
    # Player 1 Turn
    println("####   TURN: PLAYER 1   ####")
    makeTurn(hexgrid, players)
    # print current board --> moved to players
    # Player 2 Turn
    println("####   TURN: PLAYER 2   ####")
    makeTurn(hexgrid, players)
    # print current board
end

scores = calculateScores(hexgrid)
println("Scores: ")
for p in 1:players
    println(PLAYERCOLORS[p], " has scored: ", scores[p], " points")
end
# print Scores and declare winner
