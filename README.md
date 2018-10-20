# Omega
## Requirements:
- Install Julia v1.0 from https://julialang.org/downloads/
- Add julia to your PATH variable (makes things easier)
- run julia in a bash or the REPL (read-eval-print loop)
- type "using Pkg" <--- this is the package installer for Julia
- install the following packages using Pkg.add("\<packagename\>")
  - Printf
  - IterTools
  - DataStructures
- exit julia (Ctrl + D)
- Switch to the Omega folder
- run "julia main.jl" and play Omega

Furthermore you can run the main.jl using keyword arguments:
  - "julia main.jl 4 ar" creates a game of omega of grid size 4 and players AI and Random
  - "julia main.jl 4 hr" creates a game of omega of grid size 4 and players Human and Random
  - Note: these arguments may change later

Not yet implemented (on master):
  - you can run the game with multiple threads. To do this write "export JULIA_NUM_THREADS=4" on the bash to start julia with 4 threads
