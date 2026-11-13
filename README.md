# R2N numerical experiments

Scripts that reproduce the performance profiles of the paper on R2N, and a quick version of
them for checking that everything works.

| Script | Problems | Output |
|---|---|---|
| [`R2N_quick_benchmark.jl`](R2N_quick_benchmark.jl) | unconstrained CUTEst problems with at most 100 variables | in `R2N_quick_results/`: same files as `R2N_paper_benchmark.jl` |
| [`R2N_paper_benchmark.jl`](R2N_paper_benchmark.jl) | unconstrained CUTEst problems | in `R2N_results/`: `R2N_stats.jld2`, `R2N_<solver>.md` / `.tex`, `R2N_<figure>_<cost>.pdf` |

Start with the quick benchmark: it finishes much faster than the paper benchmark, which takes
many hours (see [Quick benchmark](#quick-benchmark)).

An HSL licence is optional: without it, every solver runs except the two that use MA57
(see [HSL (optional)](#hsl-optional)).

Both scripts include [`benchmark_common.jl`](benchmark_common.jl), which holds the code they
share and follows SolverBenchmark's
[`bmark_cutest.jl`](https://github.com/JuliaSmoothOptimizers/SolverBenchmark.jl/blob/main/examples/bmark_cutest.jl)
example:

1. select the problems with `CUTEst.select_sif_problems`;
2. run every solver on every problem with `SolverBenchmark.bmark_solvers`;
3. save the statistics with `JLD2.@save`;
4. write one table per solver (problem, size, objective, gradient norm, evaluation counts,
   iterations, time, status) with `SolverBenchmark.pretty_stats` (`.md`) and
   `SolverBenchmark.pretty_latex_stats` (`.tex`);
5. plot one performance profile per figure and cost with `SolverBenchmark.performance_profile`.

## First-time setup

These steps are needed once per machine.

1. **Julia.** Install Julia 1.11 or later from [julialang.org](https://julialang.org/downloads/).
2. **gfortran.** CUTEst.jl needs it; follow the
   [CUTEst.jl installation instructions](https://github.com/JuliaSmoothOptimizers/CUTEst.jl#installing).
3. **HSL (optional).** With an academic licence, download `HSL_jll.jl` from
   [STFC](https://licences.stfc.ac.uk/product/libhsl) and unpack it. Without a licence, skip
   this step: the scripts detect it and leave out the MA57 solvers
   (see [HSL (optional)](#hsl-optional)).
4. **Packages.** Clone this repository, start Julia in its root folder and run, with internet
   access:

   ```julia
   using Pkg
   Pkg.activate(".")
   Pkg.develop(path = "/path/to/HSL_jll.jl")  # only with the HSL licence of step 3
   Pkg.instantiate()
   ```

5. **Check** that everything works by running the quick benchmark in the same Julia session:

   ```julia
   include("R2N_quick_benchmark.jl")
   ```

   The first run also downloads the CUTEst problem collection. The tables and figures are
   written to `R2N_quick_results/`; compare them with ours in
   [`R2N_quick_reference/`](R2N_quick_reference/) (see [Reference results](#reference-results)).

> [!WARNING]
> Do not run `Pkg.update()`: the pins in `Project.toml` keep its packages fixed, but it would
> still upgrade their dependencies.

## HSL (optional)

Without an HSL licence, the scripts leave out:

| Script | Solvers not run | Figures not produced |
|---|---|---|
| `R2N_paper_benchmark.jl` | `R2N_ma57`, `R2N_ma57_fast` | `ma57`, `exact_vs_krylov` |
| `R2N_quick_benchmark.jl` | `R2N_ma57_fast` | `exact_vs_krylov` |

## Running

From the root of this repository, the quick benchmark:

```
julia --project=. R2N_quick_benchmark.jl
```

and the paper benchmark:

```
julia --project=. R2N_paper_benchmark.jl
```

In the paper benchmark each solve is limited to 600 seconds, so a full run takes many hours.
The plots use the default Plots.jl style, so they may look slightly different on another machine.

## Reference results

[`R2N_quick_reference/`](R2N_quick_reference/) and [`R2N_paper_reference/`](R2N_paper_reference/)
hold the tables (`.md`, `.tex`) and figures (`.pdf`) that we obtained with `R2N_quick_benchmark.jl`
and `R2N_paper_benchmark.jl`, so you can compare them with those in your `R2N_quick_results/` and
`R2N_results/`. Times depend on the machine, so the `time` profiles are the most likely to differ.

## Quick benchmark

`R2N_quick_benchmark.jl` runs the same code as the paper benchmark, with the same tolerances,
solver options, costs and `to_skip` list, on fewer problems and with a shorter time limit.
It writes the same kind of tables and figures, under the paper's figure names.

| | `R2N_quick_benchmark.jl` |
|---|---|
| Problems | those of the [R2N experiment](#r2n-experiment) with at most 100 variables |
| `max_time` | 60 seconds |
| `output_dir` | `R2N_quick_results` |
| Solvers | `R2N_Minres_qlp_ag`, `R2N_Minres_qlp_ag_fast`, `R2N_cg_ag`, `R2N_cg_ag_fast`, `trunk_cg`, and `R2N_ma57_fast` when `use_hsl = true` |
| Figures | `cg_vs_minresqlp`, `variants` (only `R2N_Minres_qlp_ag` and `_ag_fast`), `exact_vs_krylov` (when `use_hsl = true`), `cg_vs_trunk` |

The quick run uses only the small problems, so its profiles are not identical to the
figures of the paper.

## Settings

Each script sets only `max_var`, `max_time`, `output_dir` and, for the quick benchmark,
`solver_names`. The other settings are shared and sit at the top of
[`benchmark_common.jl`](benchmark_common.jl). All are set to the values used in the paper,
except where the quick benchmark differs.

| Setting | Meaning | Value |
|---|---|---|
| `min_var`, `max_var` | range of the number of variables | 1, `Inf` (quick: 1, 100) |
| `solver_names` | solvers run; figures left with fewer than two of their solvers are skipped | all (quick: the 6 of [Quick benchmark](#quick-benchmark)) |
| `to_skip` | problems left out | 7 problems |
| `atol`, `rtol` | absolute and relative stopping tolerances | 1e-6, 1e-6 |
| `max_time` | time limit per solve, in seconds | 600 (quick: 60) |
| `use_hsl` | run the MA57 solvers | `LIBHSL_isfunctional()`: `true` with a licensed HSL_jll, `false` otherwise |
| `solved_statuses` | statuses counted as solved in the profiles | `first_order`, `acceptable` |
| `output_dir` | where the `.jld2` file, the tables and the figures are written (relative to where Julia is launched) | `R2N_results` (quick: `R2N_quick_results`) |
| `figure_format` | file format of the figures | `pdf` |

## R2N experiment

**Problems.** CUTEst problems with no constraints, free variables and an objective classified
as `other` (general nonlinear), without the 7 problems listed in `to_skip` in `benchmark_common.jl`
(5 time out, 2 are too dense).

**Stopping.** `atol = rtol = 1e-6`, `max_time = 600` seconds.

**Solvers.** Each name in `benchmark_common.jl`, which is also the legend label in the plots, encodes its options:

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
