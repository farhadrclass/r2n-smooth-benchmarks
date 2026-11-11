# R2N / R2NLS numerical experiments

Scripts that reproduce the performance profiles of the paper on R2N and R2NLS, and quick
versions of them for checking that everything works.

| Script | Problems | Output |
|---|---|---|
| [`R2N_quick_benchmark.jl`](R2N_quick_benchmark.jl) | unconstrained CUTEst problems with at most 100 variables | in `R2N_quick_results/`: same files as `R2N_paper_benchmark.jl` |
| [`R2NLS_quick_benchmark.jl`](R2NLS_quick_benchmark.jl) | CUTEst feasibility problems with at most 100 variables, as least squares | in `R2NLS_quick_results/`: same files as `R2NLS_paper_benchmark.jl` |
| [`R2N_paper_benchmark.jl`](R2N_paper_benchmark.jl) | unconstrained CUTEst problems | in `R2N_results/`: `R2N_stats.jld2`, `R2N_<solver>.md` / `.tex`, `R2N_<figure>_<cost>.pdf` |
| [`R2NLS_paper_benchmark.jl`](R2NLS_paper_benchmark.jl) | CUTEst feasibility problems as least squares | in `R2NLS_results/`: `R2NLS_stats.jld2`, `R2NLS_<solver>.md` / `.tex`, `R2NLS_<figure>_<cost>.pdf` |

Start with the quick benchmarks: they finish much faster than the paper benchmarks, which take
many hours (see [Quick benchmarks](#quick-benchmarks)).

Each script follows SolverBenchmark's
[`bmark_cutest.jl`](https://github.com/JuliaSmoothOptimizers/SolverBenchmark.jl/blob/main/examples/bmark_cutest.jl)
example:

1. select the problems with `CUTEst.select_sif_problems`;
2. run every solver on every problem with `SolverBenchmark.bmark_solvers`;
3. save the statistics with `JLD2.@save`;
4. write one table per solver (problem, size, objective, gradient norm, evaluation counts,
   iterations, time, status) with `SolverBenchmark.pretty_stats` (`.md`) and
   `SolverBenchmark.pretty_latex_stats` (`.tex`);
5. plot one performance profile per figure and cost with `SolverBenchmark.performance_profile`.

## Installation

Julia 1.11 or later is required; the experiments in the paper were run with Julia 1.13.

[`Project.toml`](Project.toml) lists the packages and their versions, and
[`Manifest.toml`](Manifest.toml) records the exact versions used.

**JSOSolvers.** R2N and R2NLS are not yet in a registered release of JSOSolvers.jl, so
`Manifest.toml` takes JSOSolvers from the `<TAG>` tag of
[Farhad-phd/JSOSolvers.jl](https://github.com/Farhad-phd/JSOSolvers.jl).

**HSL.** [HSL.jl](https://github.com/JuliaSmoothOptimizers/HSL.jl) is a direct dependency of
the experiments: it is listed in `Project.toml`, because JSOSolvers no longer installs it.
The MA57 subsolver of R2N, `MA57R2NSubsolver`, is defined in a package extension of JSOSolvers
that is activated by `using HSL`, so the R2N scripts load HSL next to JSOSolvers:

```julia
using HSL  # activates MA57R2NSubsolver; loads with the public stub if there is no licence
using JSOSolvers
```

`MA57R2NSubsolver` is not exported, so the scripts call it as `JSOSolvers.MA57R2NSubsolver(nlp)`.

MA57 itself needs a licensed `HSL_jll.jl`, available free of charge for academic use from
[STFC](https://licences.stfc.ac.uk/product/libhsl).
Without it, HSL loads with the public stub of `HSL_jll` but MA57 cannot run: set
`use_hsl = false` in the R2N scripts, so that the MA57 solvers are not run and the figures that
use them (`ma57` and `exact_vs_krylov`) are not produced. R2NLS does not use HSL.

From the root of this repository:

```julia
using Pkg
Pkg.activate(".")
Pkg.develop(path = "/path/to/HSL_jll.jl")  # only with the licensed copy downloaded from STFC
Pkg.instantiate()
```

### Code written for an earlier version of the JSOSolvers fork

The scripts in this repository use the current names. Code written for an earlier version of
the fork must load HSL as above and make these changes:

| Old usage | Now |
|---|---|
| `HSLR2NSubsolver(nlp; hsl_constructor = ma57_coord)` | `JSOSolvers.MA57R2NSubsolver(nlp)` (not exported) |
| `get_operator`, `get_operator_norm` | `JSOSolvers.get_model_hessian`, `JSOSolvers.get_model_hessian_norm` (R2N) or `JSOSolvers.get_jacobian_norm` (R2NLS) |
| `is_unsupported`, `finalize_subsolver!`, `reset_subsolver!`, `initialize!`, `update_subsolver!` | the same names with the `JSOSolvers.` prefix (no longer exported) |
| `ls_min_alpha`, `ls_max_alpha` passed to `R2N` | remove them: they had no effect and were removed |
| `scp_flag` passed to `R2NLS` | remove it: it had no effect (`R2N` still accepts `scp_flag`) |

## Running

From the root of this repository, the quick benchmarks:

```
julia --project=. R2N_quick_benchmark.jl
julia --project=. R2NLS_quick_benchmark.jl
```

and the paper benchmarks:

```
julia --project=. R2N_paper_benchmark.jl
julia --project=. R2NLS_paper_benchmark.jl
```

In the paper benchmarks each solve is limited to 600 seconds, so a full run takes many hours.
The plots use the default Plots.jl style, so they may look slightly different on another machine.

## Quick benchmarks

The quick benchmarks run the same code as the paper benchmarks, with the same tolerances,
solver options, costs and `to_skip` lists, on fewer problems and with a shorter time limit.
They write the same kind of tables and figures, under the paper's figure names.

| | `R2N_quick_benchmark.jl` | `R2NLS_quick_benchmark.jl` |
|---|---|---|
| Problems | those of the [R2N experiment](#r2n-experiment) with at most 100 variables | those of the [R2NLS experiment](#r2nls-experiment) with at most 100 variables |
| `max_time` | 60 seconds | 60 seconds |
| `output_dir` | `R2N_quick_results` | `R2NLS_quick_results` |
| Solvers | `R2N_Minres_qlp_ag`, `R2N_Minres_qlp_ag_fast`, `R2N_cg_ag`, `R2N_cg_ag_fast`, `trunk_cg`, and `R2N_ma57_fast` when `use_hsl = true` | all three solvers of the paper |
| Figures | `cg_vs_minresqlp`, `variants` (only `R2N_Minres_qlp_ag` and `_ag_fast`), `exact_vs_krylov` (when `use_hsl = true`), `cg_vs_trunk` | `matrix_free_vs_direct`, `lsmr_vs_trunk` |

The quick runs use only the small problems, so their profiles are not identical to the
figures of the paper.

## Settings

The top of each script holds the settings. Those of the paper benchmarks are set to the values
used in the paper; the quick benchmarks differ only in `max_var`, `max_time` and `output_dir`.

| Setting | Meaning | R2N | R2NLS |
|---|---|---|---|
| `min_var`, `max_var` | range of the number of variables | 1, `Inf` (quick: 1, 100) | 1, 5000 (quick: 1, 100) |
| `to_skip` | problems left out | 7 problems | 7 problems |
| `atol`, `rtol` | absolute and relative stopping tolerances | 1e-6, 1e-6 | 1e-8, 1e-6 |
| `Fatol`, `Frtol` | stopping tolerances on the residual | — | `√eps`, `eps` |
| `max_time` | time limit per solve, in seconds | 600 (quick: 60) | 600 (quick: 60) |
| `use_hsl` | run the MA57 solvers (needs a licensed HSL_jll) | `true` | — |
| `solved_statuses` | statuses counted as solved in the profiles | `first_order`, `acceptable` | `first_order`, `unbounded` |
| `output_dir` | where the `.jld2` file, the tables and the figures are written (relative to where Julia is launched) | `R2N_results` (quick: `R2N_quick_results`) | `R2NLS_results` (quick: `R2NLS_quick_results`) |
| `figure_format` | file format of the figures | `pdf` | `pdf` |

## R2N experiment

**Problems.** CUTEst problems with no constraints, free variables and an objective classified
as `other` (general nonlinear), without the 7 problems listed in `to_skip` in the script
(5 time out, 2 are too dense).

**Stopping.** `atol = rtol = 1e-6`, `max_time = 600` seconds.

**Solvers.** Each name in the script, which is also the legend label in the plots, encodes its options:

| Part of the name | Meaning |
|---|---|
| `Minres_qlp`, `cg`, `ma57` | subsolver `MinresQlpR2NSubsolver`, `CGR2NSubsolver`, `JSOSolvers.MA57R2NSubsolver` (from the HSL extension of JSOSolvers) |
| `ag`, `prev`, `sigma`, `cp` | `npc_handler` used when nonpositive curvature is detected |
| `fast` | `fast_local_convergence = true` |
| `skip_rho` | `always_accept_npc_ag = true` |
| `LBFGS` | the Hessian is replaced by `LBFGSModel(nlp)`; `shifted` uses `ShiftedLBFGSSolver` |
| `trunk`, `Trunk` | JSOSolvers' `trunk` with the CG subsolver (baseline) |

**Costs.** A problem counts as solved if the status is `first_order` or `acceptable`;
otherwise its cost is `Inf`.

| Cost | Measure |
|---|---|
| `time` | `elapsed_time` |
| `obj` | `neval_obj` |
| `grad` | `neval_grad` |
| `hess` | `neval_hess + neval_hprod / n` |

**Figures.**

| Figure | Solvers compared |
|---|---|
| `npc` | `R2N_Minres_qlp_ag`, `_prev`, `_sigma`, `_cp` |
| `ma57` | `R2N_ma57`, `R2N_ma57_fast` |
| `cg_vs_minresqlp` | `R2N_cg_ag`, `R2N_Minres_qlp_ag` |
| `variants` | `R2N_Minres_qlp_ag`, `_ag_fast`, `_ag_skip_rho`, `_ag_skip_rho_fast` |
| `exact_vs_krylov` | `R2N_Minres_qlp_ag_fast`, `R2N_ma57_fast` |
| `cg_vs_trunk` | `R2N_cg_ag_fast`, `trunk_cg` |
| `lbfgs_hessian` | `R2N_LBFGS_Minres_qlp_fast_variant`, `R2N_LBFGS_shifted_fast_variant` |
| `trunk_vs_lbfgs_cg` | `R2N_LBFGS_cg_fast_variant`, `Trunk_LBFGS_cg` |

L-BFGS runs evaluate no Hessian, so their `hess` profile carries no information.
BenchmarkProfiles warns that it shifts the zero costs by one.

## R2NLS experiment

**Problems.** CUTEst problems with no objective, at least one constraint, only equality
constraints, free variables and at most 5000 variables, without the 7 problems listed in
`to_skip` in the script. Each problem is wrapped in `FeasibilityResidual`, which turns it into
the least-squares problem of minimizing the norm of its constraint residual.

**Stopping.** `atol = 1e-8`, `rtol = 1e-6`, `Fatol = √eps`, `Frtol = eps`, `max_time = 600` seconds.

**Solvers.**

| Name | Solver |
|---|---|
| `R2NLS_LSMR` | R2NLS with the matrix-free `LSMRSubsolver` |
| `R2NLS_QRMumps` | R2NLS with the direct `QRMumpsSubsolver` |
| `trunk_lsmr` | JSOSolvers' `trunk` for least squares (baseline) |

The η and γ parameters of each R2NLS variant are given in the script.

**Costs.** A problem counts as solved if the status is `first_order` or `unbounded`;
otherwise its cost is `Inf`.

| Cost | Measure |
|---|---|
| `time` | `elapsed_time` |
| `iter` | `iter` |
| `residual` | `neval_residual` |
| `jacobian` | `neval_jac_residual + neval_jprod_residual / n + neval_jtprod_residual / m` |

**Figures.**

| Figure | Solvers compared |
|---|---|
| `matrix_free_vs_direct` | `R2NLS_LSMR`, `R2NLS_QRMumps` |
| `lsmr_vs_trunk` | `R2NLS_LSMR`, `trunk_lsmr` |
