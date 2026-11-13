# Benchmark of the paper: every solver and figure. The code shared with R2N_quick_benchmark.jl,
# including the other settings, is in benchmark_common.jl.
include("benchmark_common.jl")

run_benchmark(
  problem_names = r2n_problems(max_var = Inf),  # problems of any size
  max_time = 600.0,                             # time limit per solve, in seconds
  output_dir = "R2N_results",                   # where the .jld2 file, the tables and the figures are written
)
