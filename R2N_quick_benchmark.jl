# Quick version of R2N_paper_benchmark.jl: the same problems restricted to at most 100 variables,
# a 60-second time limit and the 6 solvers needed for 4 of the paper's figures.
# Use it to check the installation and the shape of the profiles before the full run.
# The code shared with R2N_paper_benchmark.jl, including the other settings, is in benchmark_common.jl.
include("benchmark_common.jl")

run_benchmark(
  problem_names = r2n_problems(max_var = 100),  # problems with at most 100 variables (any size in the paper)
  max_time = 60.0,                              # time limit per solve, in seconds (600 in the paper)
  output_dir = "R2N_quick_results",             # where the .jld2 file, the tables and the figures are written
  # only the solvers of the figures cg_vs_minresqlp, variants (2 of its 4 solvers), exact_vs_krylov
  # (R2N_ma57_fast runs only when use_hsl = true) and cg_vs_trunk
  solver_names = [:R2N_Minres_qlp_ag, :R2N_Minres_qlp_ag_fast, :R2N_cg_ag, :R2N_cg_ag_fast, :trunk_cg, :R2N_ma57_fast],
)
