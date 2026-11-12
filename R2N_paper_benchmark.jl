using JLD2, Plots
using CUTEst, NLPModelsModifiers, SolverBenchmark
using HSL  # activates MA57R2NSubsolver; loads with the public stub if there is no licence
using JSOSolvers

# settings (the values below are those used in the paper)
min_var = 1       # smallest number of variables
max_var = Inf     # largest number of variables
to_skip = [       # problems left out
  "FLETCBV2", "NONMSQRT", "FLETCBV3", "FLETCHBV", "LRCOVTYPE",  # time out
  "VAREIGVL", "PENALTY1",  # too dense
]
atol = 1.0e-6     # absolute stopping tolerance
rtol = 1.0e-6     # relative stopping tolerance
max_time = 600.0  # time limit per solve, in seconds
use_hsl = LIBHSL_isfunctional()  # true only with a licensed HSL_jll; otherwise the MA57 solvers and their figures are skipped
solved_statuses = [:first_order, :acceptable]  # statuses counted as solved in the profiles
output_dir = "R2N_results"  # where the .jld2 file, the tables and the figures are written
figure_format = "pdf"       # any format supported by Plots.savefig, e.g. "png" or "svg"

# define problems: unconstrained CUTEst problems with a general nonlinear objective
problem_names = CUTEst.select_sif_problems(objtype = ["other"], max_con = 0, only_free_var = true, min_var = min_var, max_var = max_var)
filter!(p -> p ∉ to_skip, problem_names)
problems = (CUTEstModel(p) for p in problem_names)

# define solvers
solvers = Dict(
  # MINRES-QLP subsolver, one per nonpositive-curvature handler
  :R2N_Minres_qlp_ag => nlp -> R2N(nlp; subsolver = MinresQlpR2NSubsolver(nlp), npc_handler = :ag, fast_local_convergence = false, atol, rtol, max_time),
  :R2N_Minres_qlp_prev => nlp -> R2N(nlp; subsolver = MinresQlpR2NSubsolver(nlp), npc_handler = :prev, fast_local_convergence = false, atol, rtol, max_time),
  :R2N_Minres_qlp_sigma => nlp -> R2N(nlp; subsolver = MinresQlpR2NSubsolver(nlp), npc_handler = :sigma, fast_local_convergence = false, atol, rtol, max_time),
  :R2N_Minres_qlp_cp => nlp -> R2N(nlp; subsolver = MinresQlpR2NSubsolver(nlp), npc_handler = :cp, fast_local_convergence = false, atol, rtol, max_time),
  # MINRES-QLP variants
  :R2N_Minres_qlp_ag_fast => nlp -> R2N(nlp; subsolver = MinresQlpR2NSubsolver(nlp), npc_handler = :ag, fast_local_convergence = true, atol, rtol, max_time),
  :R2N_Minres_qlp_ag_skip_rho => nlp -> R2N(nlp; subsolver = MinresQlpR2NSubsolver(nlp), npc_handler = :ag, always_accept_npc_ag = true, fast_local_convergence = false, atol, rtol, max_time),
  :R2N_Minres_qlp_ag_skip_rho_fast => nlp -> R2N(nlp; subsolver = MinresQlpR2NSubsolver(nlp), npc_handler = :ag, always_accept_npc_ag = true, fast_local_convergence = true, atol, rtol, max_time),
  # CG subsolver
  :R2N_cg_ag => nlp -> R2N(nlp; subsolver = CGR2NSubsolver(nlp), npc_handler = :ag, fast_local_convergence = false, atol, rtol, max_time),
  :R2N_cg_ag_fast => nlp -> R2N(nlp; subsolver = CGR2NSubsolver(nlp), npc_handler = :ag, fast_local_convergence = true, atol, rtol, max_time),
  # L-BFGS Hessian approximation
  :R2N_LBFGS_Minres_qlp_fast_variant => nlp -> R2N(LBFGSModel(nlp); subsolver = MinresQlpR2NSubsolver, fast_local_convergence = true, atol, rtol, max_time),
  :R2N_LBFGS_shifted_fast_variant => nlp -> R2N(LBFGSModel(nlp); subsolver = ShiftedLBFGSSolver, fast_local_convergence = true, atol, rtol, max_time),
  :R2N_LBFGS_cg_fast_variant => nlp -> R2N(LBFGSModel(nlp); subsolver = CGR2NSubsolver, fast_local_convergence = true, atol, rtol, max_time),
  # trunk baselines
  :trunk_cg => nlp -> trunk(nlp; subsolver = :cg, atol, rtol, max_time),
  :Trunk_LBFGS_cg => nlp -> trunk(LBFGSModel(nlp); subsolver = :cg, atol, rtol, max_time),
)
# MA57 subsolver (needs a licensed HSL_jll; defined in the HSL extension of JSOSolvers, not exported)
if use_hsl
  solvers[:R2N_ma57] = nlp -> R2N(nlp; subsolver = JSOSolvers.MA57R2NSubsolver(nlp), npc_handler = :ag, fast_local_convergence = false, atol, rtol, max_time)
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

# plot profiles of the paper, one file per figure and cost
solved(df) = in.(df.status, Ref(solved_statuses))
costs = [
  "time" => df -> .!solved(df) .* Inf .+ df.elapsed_time,
  "obj" => df -> .!solved(df) .* Inf .+ df.neval_obj,
  "grad" => df -> .!solved(df) .* Inf .+ df.neval_grad,
  # a Hessian-vector product counts as 1/n Hessian evaluation
  "hess" => df -> .!solved(df) .* Inf .+ df.neval_hprod ./ df.nvar .+ df.neval_hess,
]
figures = [
  "npc" => [:R2N_Minres_qlp_ag, :R2N_Minres_qlp_prev, :R2N_Minres_qlp_sigma, :R2N_Minres_qlp_cp],
  "ma57" => [:R2N_ma57, :R2N_ma57_fast],
  "cg_vs_minresqlp" => [:R2N_cg_ag, :R2N_Minres_qlp_ag],
  "variants" => [:R2N_Minres_qlp_ag, :R2N_Minres_qlp_ag_fast, :R2N_Minres_qlp_ag_skip_rho, :R2N_Minres_qlp_ag_skip_rho_fast],
  "exact_vs_krylov" => [:R2N_Minres_qlp_ag_fast, :R2N_ma57_fast],
  "cg_vs_trunk" => [:R2N_cg_ag_fast, :trunk_cg],
  "lbfgs_hessian" => [:R2N_LBFGS_Minres_qlp_fast_variant, :R2N_LBFGS_shifted_fast_variant],
  "trunk_vs_lbfgs_cg" => [:R2N_LBFGS_cg_fast_variant, :Trunk_LBFGS_cg],
]
# skip figures with a solver that was not run (MA57 when use_hsl = false)
filter!(f -> all(s -> haskey(stats, s), last(f)), figures)
for (figure, names) in figures, (costname, cost) in costs
  p = performance_profile(Dict(s => stats[s] for s in names), cost, title = costname)
  savefig(p, joinpath(output_dir, "R2N_$(figure)_$(costname).$(figure_format)"))
end
