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
  - ProgressMeter
- exit julia (Ctrl + D)
- Switch to the Omega folder
- run "julia main.jl" and play Omega

Furthermore you can run the main.jl using keyword arguments:
  - "julia main.jl 4 2" creates a game of omega of grid size 4 and 2 players
  - Note: these arguments may change later
