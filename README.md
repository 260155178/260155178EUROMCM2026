# EuroMCM 2026 — Team 260155178

MATLAB implementation of the proposed solutions to **Problem α (Alpha)** of the [European Mathematical Contest in Modelling (EuroMCM) 2026](https://www.euromcm.org/).

The solutions use Ordinary Differential Equations (ODEs) to study competition for limited energy resources. The first models the interaction between humans and Neanderthals. The second extends the approach to humans and artificial systems capable of recursive self-improvement (RSI).

## Files

| Script | Proposed solution | Solver |
| --- | --- | --- |
| [HN260155178.m](HN260155178.m) | Human–Neanderthal competition | `ode45` |
| [RSI260155178.m](RSI260155178.m) | Human–RSI interaction and outcome classification | `ode15s` |

## Requirements

MATLAB R2018b or later. The scripts use standard MATLAB functions and require no additional toolboxes or external data files. All parameters and initial conditions are included in the scripts.

## How to run

Download or clone the repository and open its folder in MATLAB. Run the scripts separately:

```matlab
run('HN260155178.m')
```

```matlab
run('RSI260155178.m')
```

Each script clears the workspace and closes existing figures at startup. Save any figures you want to keep before running the other script. Results appear in figure windows and in the Command Window; files are not saved automatically.

## 1. Human–Neanderthal competition

`HN260155178.m` solves a two-population competition model over 6,000 years. It includes individual energy requirements, a shared resource budget, asymmetric resource competition and direct interaction losses.

The initial Neanderthal population is set to its carrying capacity. The initial human population is 1% of that population.

| Setting | Value |
| --- | --- |
| Available power | 1,000,000 W |
| Individual Neanderthal requirement | 150 W |
| Individual human requirement | 135 W |
| Human intrinsic growth rate | 0.010/year |
| Neanderthal intrinsic growth rate | 0.002/year |
| Neanderthal extinction threshold | Below 1% of the initial Neanderthal population |

The script displays one figure containing the two population trajectories and a phase-space diagram with a direction field. It prints the detected extinction time, or a message if the threshold is not crossed, together with the comparison interval of 1,400–5,400 years.

## 2. Human–RSI interaction

`RSI260155178.m` solves a seven-variable system over 150 years, from 2024 to 2174.

| Variable | Description |
| --- | --- |
| `I` | RSI electricity consumption, in TWh/year |
| `R` | RSI resistance to human attacks |
| `D` | RSI dependence on humans |
| `A` | Human attack intensity |
| `H` | Human population, in billions |
| `etaI` | RSI efficiency |
| `etaH` | Human efficiency |

The model combines a growing electricity supply, RSI capability feedback, human and RSI efficiency, periodic attacks, and resistance. The parameter `alpha` controls the RSI resource ceiling, while `deltaH` represents human dependence on RSI services in the available-resource calculation.

### Default scenario

| Setting | Value |
| --- | --- |
| Initial electricity supply | 27,700 TWh/year |
| Initial RSI electricity consumption | 415 TWh/year |
| Initial human population | 8.1 billion |
| Electricity supply ceiling | 100,000 TWh/year |
| `alpha` | 0.25 |
| `deltaH` | 0.30 |

### Figures and printed results

The script displays two figures:

1. A six-panel overview of human population, energy resources, resistance/dependence/attacks, efficiencies, damage to RSI, and the human–RSI trajectory with a direction field evaluated at `t_ref = 50`.
2. Human population comparisons for `alpha = [0.2, 0.5, 0.8]`, with `deltaH = 0` and `deltaH = 1`.

The Command Window shows the default scenario's extinction status, final RSI consumption, dependence, resistance, efficiency and outcome classification. It also shows:

- A fate map for `alpha = [0, 0.1, 0.25, 0.5, 0.75, 1]` and `deltaH = [0, 0.3, 1, 1.5]`.
- Critical alignment values estimated by bisection over the 150-year simulation, alongside the theoretical values calculated in the script.

### Outcome definitions

The script applies the following rules in order:

| Outcome | Rule |
| --- | --- |
| Extinction (`EXT`) | Human population drops below 10 million at any returned simulation time. |
| Marginal survival (`MARG`) | No extinction is detected, and the final population is below 50% of the initial population. |
| Coexistence (`COEX`) | No extinction is detected, and the final population is at least 50% of the initial population. |

## Changing scenarios

Edit the `p` parameters at the beginning of each script to change the model settings. In `RSI260155178.m`, the arrays `alphas` and `deltas` define the plotted comparisons; `alphas_map` and `deltas_map` define the printed fate map. The simulation interval is set by `tspan`.

## Team identifier

**Team control number:** 260155178.

Thank you for taking the time to explore our proposed solutions for EuroMCM 2026, Problem α.
