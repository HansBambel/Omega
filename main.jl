include("gridObject.jl")
include("humanPlayer.jl")
include("randomPlayer.jl")
include("aiPlayer.jl")

# https://unicode-table.com/en/

# const global PLAYERCOLORS = ["W", "B", "R", "G"]
const global PLAYERCOLORS = ["\U2715", "\U25B3", "\U26C4", "\U2661"]
numPlayers = 2
gridSize = 4
if length(ARGS) == 0
    print(" How big shall the grid be? Should be between 5-10: ")
    gridSize = parse(Int, chomp(readline()))
    print(" Who are the players and what is the order? Ex.: rah = Random, AI, Human")
    players = chomp(readline())
    numPlayers = length(players)
    # numPlayers = parse(Int, chomp(readline()))
elseif length(ARGS) == 1
    gridSize = parse(Int, ARGS[1])
    print(" Who are the players and what is the order? Ex.: rah = Random, AI, Human")
    players = chomp(readline())
    numPlayers = length(players)
elseif length(ARGS) == 2
    gridSize = parse(Int, ARGS[1])
    players = ARGS[2]
    numPlayers = length(players)
end

hexgrid = Grid()
hexgrid.initializeGrid(gridSize)
# setGridValue!(hexgrid, 1, 1, 2)
# setGridValue!(hexgrid, 1, 2, 2)
# setGridValue!(hexgrid, 1, 3, 2)
# setGridValue!(hexgrid, 1, 5, 2)
# setGridValue!(hexgrid, 2, 6, 2)
# setGridValue!(hexgrid, 3, 1, 2)
# setGridValue!(hexgrid, 3, 2, 2)
# setGridValue!(hexgrid, 5, 1, 2)
#
# setGridValue!(hexgrid, 5, 4, 3)
# setGridValue!(hexgrid, 5, 5, 3)
# setGridValue!(hexgrid, 5, 6, 3)
# setGridValue!(hexgrid, 6, 3, 3)
# setGridValue!(hexgrid, 7, 1, 3)
# setGridValue!(hexgrid, 7, 2, 3)
# setGridValue!(hexgrid, 9, 3, 3)
# setGridValue!(hexgrid, 9, 4, 3)
hexgrid.printBoard()

### This is the time the AI is allowed to have
totalTurnTime = 5*60.0
totalTurns = countNum(1, hexgrid.getArray()) ÷ numPlayers
aiTurns = totalTurns ÷ 2
# TODO this time assumes every turn needs the same amount
# idea: find out when/how deep the AI can look into endstate in a reasonable time
# NOTE later AI needs only a little bit of time because he doesn't need to look deep
# the last 4 turns can be calculated within 1s
timePerTurn = totalTurnTime / aiTurns
timeAIneeded = 0
turn = 0
while(!hexgrid.gameOver(numPlayers))
    # each player after the other
    for p in 1:numPlayers
        global turn += 1

        if (players[p] == 'r') | (players[p] == 'R')
            println("####   TURN ", turn, ": RANDOM PLAYER ", PLAYERCOLORS[p], "   ####")
            makeRandomTurn(hexgrid, numPlayers)
        elseif (players[p] == 'a') | (players[p] == 'A')
            println("####   TURN ", turn, ": AI PLAYER ", PLAYERCOLORS[p], "   ####")
            timeForTurn = @elapsed makeSmartTurn(hexgrid, p, timePerTurn, turn)
            global timeAIneeded += timeForTurn
            println("AI needed ", timeForTurn, "s of its given ", timePerTurn, "s")
        elseif (players[p] == 'h') | (players[p] == 'H')
            println("####   TURN ", turn, ": HUMAN PLAYER ", PLAYERCOLORS[p], "   ####")
            makeTurn(hexgrid, numPlayers)
        end
        println("Current Score: ", hexgrid.calculateScores(numPlayers))
        println("Current Heuristic: ", hexgrid.heuristic())
    end
end
println("Calculated TOTAL_TURNS: ", totalTurns)
if 'a' in players
    println("AI needed ", timeAIneeded, "s of its ", totalTurnTime, "s.")
end
println("### Game ended ###")
scores = hexgrid.calculateScores(numPlayers)
println("Scores: ")
for p in 1:numPlayers
    println(PLAYERCOLORS[p], " has scored: ", scores[p], " points")
end
println(PLAYERCOLORS[findmax(scores)[2]], " is the Winner!")
# print Scores and declare winner
