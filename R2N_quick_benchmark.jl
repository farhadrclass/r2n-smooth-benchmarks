# Quick version of R2N_paper_benchmark.jl: the same solvers, tables and figures, on the problems
# with at most 100 variables and with a 60-second time limit.
# Use it to check the installation and the shape of the profiles before the full run.
# The code shared with R2N_paper_benchmark.jl, including the other settings, is in benchmark_common.jl.
include("benchmark_common.jl")

run_benchmark(
  problem_names = r2n_problems(max_var = 100),  # problems with at most 100 variables (any size in the paper)
  max_time = 60.0,                              # time limit per solve, in seconds (600 in the paper)
  output_dir = "R2N_quick_results",             # where the .jld2 file, the tables and the figures are written
)
