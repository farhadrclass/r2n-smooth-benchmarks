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

## First-time setup

These steps are needed once per machine; [Installation](#installation) explains each of them.

1. **Julia.** Install Julia 1.11 or later from [julialang.org](https://julialang.org/downloads/).
2. **gfortran** (Linux and macOS only, nothing to do on Windows). Install it and check that
   `gfortran --version` works in the terminal you launch Julia from
   (see [CUTEst.jl and gfortran](#cutestjl-and-gfortran)).
3. **HSL (optional).** With an academic licence, download `HSL_jll.jl` from
   [STFC](https://licences.stfc.ac.uk/product/libhsl) and unpack it. Without a licence, skip
   this step (see [HSL (optional)](#hsl-optional)).
4. **Packages.** Clone this repository, start Julia in its root folder and run, with internet
   access:

   ```julia
   using Pkg
   Pkg.activate(".")
   Pkg.develop(path = "/path/to/HSL_jll.jl")  # only with the HSL licence of step 3
   Pkg.instantiate()
   ```

5. **Without HSL**, set `use_hsl = false` at the top of `R2N_quick_benchmark.jl` and
   `R2N_paper_benchmark.jl`.
6. **Check** that everything works with the quick benchmark:

   ```
   julia --project=. R2N_quick_benchmark.jl
   ```

   The first run also downloads the CUTEst problem collection. The tables and figures are
   written to `R2N_quick_results/`.

## Installation

Julia 1.11 or later is required; the experiments in the paper were run with Julia 1.13.

[`Project.toml`](Project.toml) lists the packages and their versions, and
[`Manifest.toml`](Manifest.toml) records the exact versions used.

### CUTEst.jl and gfortran

[CUTEst.jl](https://github.com/JuliaSmoothOptimizers/CUTEst.jl) is installed with the other
packages by `Pkg.instantiate()` (step 4 of the [first-time setup](#first-time-setup)).
It brings the CUTEst and SIFDecode binaries with it (`CUTEst_jll` and `SIFDecode_jll`), so
there is no need to build CUTEst yourself or to set `CUTEST`, `SIFDECODE` or `ARCHDEFS`.

**Fortran compiler.** CUTEst.jl does need `gfortran`: each time a problem is loaded with
`CUTEstModel`, its SIF file is decoded into Fortran files, which `gfortran` compiles into a
shared library. Only `gfortran` is supported (not `ifx`, `ifort` or `flang`).

| Platform | What to do |
|---|---|
| Windows | nothing: CUTEst.jl downloads its own `gfortran.exe` (MinGW-w64) the first time it compiles a problem |
| Linux | install it with the package manager, for example `sudo apt install gfortran` (Debian, Ubuntu) or `sudo dnf install gcc-gfortran` (Fedora) |
| macOS | `brew install gcc`, which provides `gfortran` |

On Linux and macOS, `gfortran` must be on the `PATH` of the Julia process, otherwise
`using CUTEst` fails with `gfortran is not installed`. Check with `gfortran --version` in the
terminal you launch Julia from. CUTEst.jl warns if `gfortran` targets a different architecture
than Julia (for example an x86_64 `gfortran` with an arm64 Julia on Apple silicon).

**Problems.** The CUTEst problem collection (the SIF files) is not part of the package: it is
downloaded automatically, as a Julia artifact, the first time `using CUTEst` runs, so that first
run needs internet access. If the environment variable `MASTSIF` is set, CUTEst.jl reads the SIF
files from that directory instead; unset it, or call `CUTEst.set_mastsif()` after `using CUTEst`,
so that every problem selected by the scripts is found.

Decoding and compiling a problem happens before it is solved, so it is not counted in the solve
times.

To check the installation, load one problem from the root of this repository
(`julia --project=.`):

```julia
using CUTEst
nlp = CUTEstModel("ROSENBR")  # decodes and compiles the problem with gfortran
println(nlp.meta.nvar)        # 2
finalize(nlp)
```

### JSOSolvers

R2N is part of [JSOSolvers.jl](https://github.com/JuliaSmoothOptimizers/JSOSolvers.jl) from
version 0.14.9 on. `Project.toml` requires at least that version, so `Pkg.instantiate()`
installs it from the General registry like the other packages.

### HSL (optional)

An HSL licence is needed only for the two MA57 solvers. Every other solver (MINRES-QLP, CG,
L-BFGS and `trunk`) runs without it.

**With a licence.** MA57 needs a licensed `HSL_jll.jl`, available free of charge for academic
use from [STFC](https://licences.stfc.ac.uk/product/libhsl). Download and unpack it, add it to
the environment with `Pkg.develop(path = "/path/to/HSL_jll.jl")` (step 4 of the
[first-time setup](#first-time-setup)) and keep `use_hsl = true`.

**Without a licence.** Skip `Pkg.develop`: `Pkg.instantiate()` then installs the public stub of
`HSL_jll`, so `using HSL` still works but MA57 cannot run. Set `use_hsl = false` at the top of
both scripts, which then leave out:

| Script | Solvers not run | Figures not produced |
|---|---|---|
| `R2N_paper_benchmark.jl` | `R2N_ma57`, `R2N_ma57_fast` | `ma57`, `exact_vs_krylov` |
| `R2N_quick_benchmark.jl` | `R2N_ma57_fast` | `exact_vs_krylov` |

All the other solvers, tables and figures are the same as with the licence.

**How the scripts load HSL.** [HSL.jl](https://github.com/JuliaSmoothOptimizers/HSL.jl) is a
direct dependency of the experiments: it is listed in `Project.toml`, because JSOSolvers no
longer installs it. The MA57 subsolver of R2N, `MA57R2NSubsolver`, is defined in a package
extension of JSOSolvers that is activated by `using HSL`, so the scripts load HSL next to
JSOSolvers, with or without a licence:

```julia
using HSL  # activates MA57R2NSubsolver; loads with the public stub if there is no licence
using JSOSolvers
```

`MA57R2NSubsolver` is not exported, so the scripts call it as `JSOSolvers.MA57R2NSubsolver(nlp)`.
`HSL_jll` is precompiled, so it does not need `gfortran`.

### Code written for an earlier version of the JSOSolvers fork

The scripts in this repository use the current names. Code written for an earlier version of
the fork must load HSL as above and make these changes:

| Old usage | Now |
|---|---|
| `HSLR2NSubsolver(nlp; hsl_constructor = ma57_coord)` | `JSOSolvers.MA57R2NSubsolver(nlp)` (not exported) |
| `get_operator`, `get_operator_norm` | `JSOSolvers.get_model_hessian`, `JSOSolvers.get_model_hessian_norm` |
| `is_unsupported`, `finalize_subsolver!`, `reset_subsolver!`, `initialize!`, `update_subsolver!` | the same names with the `JSOSolvers.` prefix (no longer exported) |
| `ls_min_alpha`, `ls_max_alpha` passed to `R2N` | remove them: they had no effect and were removed |

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

The top of each script holds the settings. Those of the paper benchmark are set to the values
used in the paper; the quick benchmark differs only in `max_var`, `max_time` and `output_dir`.

| Setting | Meaning | Value |
|---|---|---|
| `min_var`, `max_var` | range of the number of variables | 1, `Inf` (quick: 1, 100) |
| `to_skip` | problems left out | 7 problems |
| `atol`, `rtol` | absolute and relative stopping tolerances | 1e-6, 1e-6 |
| `max_time` | time limit per solve, in seconds | 600 (quick: 60) |
| `use_hsl` | run the MA57 solvers (needs a licensed HSL_jll) | `true` (set `false` without an HSL licence) |
| `solved_statuses` | statuses counted as solved in the profiles | `first_order`, `acceptable` |
| `output_dir` | where the `.jld2` file, the tables and the figures are written (relative to where Julia is launched) | `R2N_results` (quick: `R2N_quick_results`) |
| `figure_format` | file format of the figures | `pdf` |

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
