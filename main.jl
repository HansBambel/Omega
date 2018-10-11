include("grid.jl")
include("humanPlayer.jl")
include("randomPlayer.jl")
include("bestAiPlayer.jl")
include("alphaBetaAiPlayer.jl")

# https://unicode-table.com/en/
# const global PLAYERCOLORS = ["W", "B", "R", "G"]
const global PLAYERCOLORS = ["\U2715", "\U25B3", "\U26C4", "\U2661"]
numPlayers = 2
gridSize = 4
if length(ARGS) == 0
    print(" How big shall the grid be? Should be between 5-10: ")
    gridSize = parse(Int, chomp(readline()))
    print(" Who are the players and what is the order? Ex.: ah = AI, Human")
    players = chomp(readline())
elseif length(ARGS) == 1
    gridSize = parse(Int, ARGS[1])
    print(" Who are the players and what is the order? Ex.: ah = AI, Human")
    players = chomp(readline())
elseif length(ARGS) == 2
    gridSize = parse(Int, ARGS[1])
    players = ARGS[2]
end

hexgrid = Grid()
hexgrid.initializeGrid(gridSize)
hexgrid.printBoard()

bestAI = BestAI()
alphaBetaAI = simpleAlphaBetaAI()
### This is the time the AI is allowed to have
totalTurnTime = 10*60.0
timeBestAIneeded = 0
timeAlphaBetaAIneeded = 0
turn = 0
while(!hexgrid.gameOver(numPlayers))
    # each player after the other
    for p in 1:numPlayers
        global turn += 1

        if (players[p] == 'r') | (players[p] == 'R')
            println("####   TURN ", turn, ": RANDOM PLAYER ", PLAYERCOLORS[p], "   ####")
            makeRandomTurn(hexgrid, numPlayers)
        elseif (players[p] == 'a') | (players[p] == 'A')
            println("####   TURN ", turn, ": Best AI PLAYER ", PLAYERCOLORS[p], "   ####")
            timeForTurn = @elapsed bestAI.makeSmartTurn(hexgrid, p, totalTurnTime-timeBestAIneeded, turn)
            global timeBestAIneeded += timeForTurn
            println("Best AI needed ", timeBestAIneeded, "s of its given ", totalTurnTime, "s")
        elseif (players[p] == 'd') | (players[p] == 'D')
            println("####   TURN ", turn, ": Alpha-Beta AI PLAYER ", PLAYERCOLORS[p], "   ####")
            timeForTurn = @elapsed alphaBetaAI.makeSmartTurn(hexgrid, p, totalTurnTime-timeAlphaBetaAIneeded, turn)
            global timeAlphaBetaAIneeded += timeForTurn
            println("Alpha-Beta AI needed ", timeAlphaBetaAIneeded, "s of its given ", totalTurnTime, "s")
        elseif (players[p] == 'h') | (players[p] == 'H')
            println("####   TURN ", turn, ": HUMAN PLAYER ", PLAYERCOLORS[p], "   ####")
            makeTurn(hexgrid, numPlayers)
        else
            println("No player such player: ", players[p])
            break
        end
        println("Current Score: ", hexgrid.calculateScores())
        println("Current Heuristic: ", hexgrid.heuristic())
    end
end

if 'a' in players
    println("Best AI needed ", timeBestAIneeded, "s of its ", totalTurnTime, "s.")
end
if 'd' in players
    println("Alpha Beta AI needed ", timeAlphaBetaAIneeded, "s of its ", totalTurnTime, "s.")
end
println("### Game ended ###")
scores = hexgrid.calculateScores()
println("Scores: ")
for p in 1:numPlayers
    println(PLAYERCOLORS[p], " has scored: ", scores[p], " points")
end
println(PLAYERCOLORS[findmax(scores)[2]], " is the Winner!")
# print Scores and declare winner
