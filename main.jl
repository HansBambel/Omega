include("grid.jl")
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

hexgrid = initializeGrid(gridSize)
printBoard(hexgrid)

### This is the time the AI is allowed to have
totalTurnTime = 2*60
totalTurns = countNum(1, hexgrid) ÷ numPlayers
aiTurns = totalTurns ÷ 2
# TODO this time assumes every turn needs the same amount
# idea: find out when/how deep the AI can look into endstate in a reasonable time
# NOTE later AI needs only a little bit of time because he doesn't need to look deep
# the last 4 turns can be calculated within 1s
timePerTurn = totalTurnTime / aiTurns

timeAIneeded = 0
turn = 0
while(!gameOver(hexgrid, numPlayers))
    # each player after the other
    for p in 1:numPlayers
        global turn += 1

        if (players[p] == 'r') | (players[p] == 'R')
            println("####   TURN ", turn, ": RANDOM PLAYER ", PLAYERCOLORS[p], "   ####")
            makeRandomTurn(hexgrid, numPlayers)
        elseif (players[p] == 'a') | (players[p] == 'A')
            println("####   TURN ", turn, ": AI PLAYER ", PLAYERCOLORS[p], "   ####")
            timeForTurn = @elapsed makeSmartTurn(hexgrid, p, timePerTurn)
            global timeAIneeded += timeForTurn
            println("AI needed ", timeForTurn, "s of its given ", timePerTurn, "s")
        elseif (players[p] == 'h') | (players[p] == 'H')
            println("####   TURN ", turn, ": HUMAN PLAYER ", PLAYERCOLORS[p], "   ####")
            makeTurn(hexgrid, numPlayers)
        end
    end
end

println("Calculated TOTAL_TURNS: ", totalTurns)
if 'a' in players
    println("AI needed ", timeAIneeded, "s of its ", totalTurnTime, "s.")
end
println("### Game ended ###")
scores = calculateScores(hexgrid, numPlayers)
println("Scores: ")
for p in 1:numPlayers
    println(PLAYERCOLORS[p], " has scored: ", scores[p], " points")
end
println(PLAYERCOLORS[findmax(scores)[2]], " is the Winner!")
# print Scores and declare winner
