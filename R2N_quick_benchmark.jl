# Quick version of R2N_paper_benchmark.jl: the same problems restricted to at most 100 variables,
# a 60-second time limit and the 6 solvers needed for 4 of the paper's figures.
# Use it to check the installation and the shape of the profiles before the full run.
using JLD2, Plots
using CUTEst, SolverBenchmark
using HSL  # activates MA57R2NSubsolver; loads with the public stub if there is no licence
using JSOSolvers

# settings (only max_var, max_time and output_dir differ from R2N_paper_benchmark.jl)
min_var = 1       # smallest number of variables
max_var = 100     # largest number of variables (Inf in the paper)
to_skip = [       # problems left out
  "FLETCBV2", "NONMSQRT", "FLETCBV3", "FLETCHBV", "LRCOVTYPE",  # time out
  "VAREIGVL", "PENALTY1",  # too dense
]
atol = 1.0e-6     # absolute stopping tolerance
rtol = 1.0e-6     # relative stopping tolerance
max_time = 60.0   # time limit per solve, in seconds (600 in the paper)
use_hsl = LIBHSL_isfunctional()  # true only with a licensed HSL_jll; otherwise the MA57 solver and its figure are skipped
solved_statuses = [:first_order, :acceptable]  # statuses counted as solved in the profiles
output_dir = "R2N_quick_results"  # where the .jld2 file, the tables and the figures are written
figure_format = "pdf"             # any format supported by Plots.savefig, e.g. "png" or "svg"

# define problems: unconstrained CUTEst problems with a general nonlinear objective
problem_names = CUTEst.select_sif_problems(objtype = ["other"], max_con = 0, only_free_var = true, min_var = min_var, max_var = max_var)
filter!(p -> p ∉ to_skip, problem_names)
problems = (CUTEstModel(p) for p in problem_names)

# define solvers: those of the figures below, with the same options as in the paper
solvers = Dict(
  # MINRES-QLP subsolver
  :R2N_Minres_qlp_ag => nlp -> R2N(nlp; subsolver = MinresQlpR2NSubsolver(nlp), npc_handler = :ag, fast_local_convergence = false, atol, rtol, max_time),
  :R2N_Minres_qlp_ag_fast => nlp -> R2N(nlp; subsolver = MinresQlpR2NSubsolver(nlp), npc_handler = :ag, fast_local_convergence = true, atol, rtol, max_time),
  # CG subsolver
  :R2N_cg_ag => nlp -> R2N(nlp; subsolver = CGR2NSubsolver(nlp), npc_handler = :ag, fast_local_convergence = false, atol, rtol, max_time),
  :R2N_cg_ag_fast => nlp -> R2N(nlp; subsolver = CGR2NSubsolver(nlp), npc_handler = :ag, fast_local_convergence = true, atol, rtol, max_time),
  # trunk baseline
  :trunk_cg => nlp -> trunk(nlp; subsolver = :cg, atol, rtol, max_time),
)
# MA57 subsolver (needs a licensed HSL_jll; defined in the HSL extension of JSOSolvers, not exported)
if use_hsl
  solvers[:R2N_ma57_fast] = nlp -> R2N(nlp; subsolver = JSOSolvers.MA57R2NSubsolver(nlp), npc_handler = :ag, fast_local_convergence = true, atol, rtol, max_time)
end

# solve problems
stats = bmark_solvers(solvers, problems)

# save DataFrames for later
mkpath(output_dir)
stats_file = joinpath(output_dir, "R2N_stats.jld2")
@save stats_file stats

# write one table per solver, as Markdown and LaTeX
cols = [:id, :name, :nvar, :objective, :dual_feas, :neval_obj, :neval_grad, :neval_hess, :neval_hprod, :iter, :elapsed_time, :status]
headers = Dict(
  :nvar => "n",
  :objective => "f(x)",
  :dual_feas => "‖∇f(x)‖",
  :neval_obj => "# f",
  :neval_grad => "# ∇f",
  :neval_hess => "# ∇²f",
  :neval_hprod => "# ∇²f·v",
  :elapsed_time => "t",
)
for (solver, df) in stats
  open(joinpath(output_dir, "R2N_$(solver).md"), "w") do io
    pretty_stats(io, df[!, cols], hdr_override = headers, tf = tf_markdown)
  end
  open(joinpath(output_dir, "R2N_$(solver).tex"), "w") do io
    pretty_latex_stats(io, df[!, cols], hdr_override = headers)
  end
end

# plot profiles, one file per figure and cost (figure names as in the paper)
solved(df) = in.(df.status, Ref(solved_statuses))
costs = [
  "time" => df -> .!solved(df) .* Inf .+ df.elapsed_time,
  "obj" => df -> .!solved(df) .* Inf .+ df.neval_obj,
  "grad" => df -> .!solved(df) .* Inf .+ df.neval_grad,
  # a Hessian-vector product counts as 1/n Hessian evaluation
  "hess" => df -> .!solved(df) .* Inf .+ df.neval_hprod ./ df.nvar .+ df.neval_hess,
]
figures = [
  "cg_vs_minresqlp" => [:R2N_cg_ag, :R2N_Minres_qlp_ag],
  "variants" => [:R2N_Minres_qlp_ag, :R2N_Minres_qlp_ag_fast],  # 2 of the 4 variants of the paper
  "exact_vs_krylov" => [:R2N_Minres_qlp_ag_fast, :R2N_ma57_fast],
  "cg_vs_trunk" => [:R2N_cg_ag_fast, :trunk_cg],
]
# skip figures with a solver that was not run (MA57 when use_hsl = false)
filter!(f -> all(s -> haskey(stats, s), last(f)), figures)
for (figure, names) in figures, (costname, cost) in costs
  p = performance_profile(Dict(s => stats[s] for s in names), cost, title = costname)
  savefig(p, joinpath(output_dir, "R2N_$(figure)_$(costname).$(figure_format)"))
end
