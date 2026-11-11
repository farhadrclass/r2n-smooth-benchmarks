# Quick version of R2NLS_paper_benchmark.jl: the same problems restricted to at most 100 variables
# and a 60-second time limit, with all the solvers and figures of the paper.
# Use it to check the installation and the shape of the profiles before the full run.
using JLD2, Plots
using CUTEst, JSOSolvers, NLPModelsModifiers, SolverBenchmark

# settings (only max_var, max_time and output_dir differ from R2NLS_paper_benchmark.jl)
min_var = 1       # smallest number of variables
max_var = 100     # largest number of variables (5000 in the paper)
to_skip = ["PATTERNNE", "KSS", "DMN37142", "ARGLCLE", "DMN37143", "DIAMON3D", "DMN15103"]  # problems left out
atol = 1.0e-8     # absolute stopping tolerance
rtol = 1.0e-6     # relative stopping tolerance
Fatol = √eps()    # absolute stopping tolerance on the residual
Frtol = eps()     # relative stopping tolerance on the residual
max_time = 60.0   # time limit per solve, in seconds (600 in the paper)
solved_statuses = [:first_order, :unbounded]  # statuses counted as solved in the profiles
output_dir = "R2NLS_quick_results"  # where the .jld2 file, the tables and the figures are written
figure_format = "pdf"               # any format supported by Plots.savefig, e.g. "png" or "svg"

# define problems: CUTEst feasibility problems (no objective, only equality constraints,
# free variables) solved as least squares on the constraint residual
problem_names = CUTEst.select_sif_problems(
  objtype = "none",
  min_con = 1,
  only_equ_con = true,
  only_free_var = true,
  min_var = min_var,
  max_var = max_var,
)
filter!(p -> p ∉ to_skip, problem_names)
problems = (FeasibilityResidual(CUTEstModel(p)) for p in problem_names)

# define solvers (same options as in the paper)
solvers = Dict(
  :R2NLS_LSMR => nls -> R2NLS(nls; subsolver = LSMRSubsolver, η1 = 1.0e-6, η2 = 0.9, γ1 = 1.9, γ2 = 10.0, γ3 = 0.9, atol, rtol, Fatol, Frtol, max_time),
  :R2NLS_QRMumps => nls -> R2NLS(nls; subsolver = QRMumpsSubsolver, η1 = 1.0e-7, η2 = 0.1, γ1 = 1.1, γ2 = 10.0, γ3 = 0.9, atol, rtol, Fatol, Frtol, max_time),
  :trunk_lsmr => nls -> trunk(nls; atol, rtol, Fatol, Frtol, max_time),
)

# solve problems
stats = bmark_solvers(solvers, problems)

# save DataFrames for later
mkpath(output_dir)
stats_file = joinpath(output_dir, "R2NLS_stats.jld2")
@save stats_file stats

# write one table per solver, as Markdown and LaTeX
cols = [:id, :name, :nvar, :nequ, :objective, :dual_feas, :neval_residual, :neval_jac_residual, :neval_jprod_residual, :neval_jtprod_residual, :iter, :elapsed_time, :status]
headers = Dict(
  :nvar => "n",
  :nequ => "m",
  :objective => "f(x)",
  :dual_feas => "‖∇f(x)‖",
  :neval_residual => "# r",
  :neval_jac_residual => "# J",
  :neval_jprod_residual => "# Jp",
  :neval_jtprod_residual => "# Jtp",
  :iter => "# iter",
  :elapsed_time => "t",
)
for (solver, df) in stats
  open(joinpath(output_dir, "R2NLS_$(solver).md"), "w") do io
    pretty_stats(io, df[!, cols], hdr_override = headers, tf = tf_markdown)
  end
  open(joinpath(output_dir, "R2NLS_$(solver).tex"), "w") do io
    pretty_latex_stats(io, df[!, cols], hdr_override = headers)
  end
end

# plot profiles, one file per figure and cost (figure names as in the paper)
solved(df) = in.(df.status, Ref(solved_statuses))
costs = [
  "time" => df -> .!solved(df) .* Inf .+ df.elapsed_time,
  "iter" => df -> .!solved(df) .* Inf .+ df.iter,
  "residual" => df -> .!solved(df) .* Inf .+ df.neval_residual,
  # a product with J counts as 1/n and a product with Jᵀ as 1/m Jacobian evaluation
  "jacobian" => df -> .!solved(df) .* Inf .+ df.neval_jac_residual .+ df.neval_jprod_residual ./ df.nvar .+ df.neval_jtprod_residual ./ df.nequ,
]
figures = [
  "matrix_free_vs_direct" => [:R2NLS_LSMR, :R2NLS_QRMumps],
  "lsmr_vs_trunk" => [:R2NLS_LSMR, :trunk_lsmr],
]
for (figure, names) in figures, (costname, cost) in costs
  p = performance_profile(Dict(s => stats[s] for s in names), cost, title = costname)
  savefig(p, joinpath(output_dir, "R2NLS_$(figure)_$(costname).$(figure_format)"))
end
