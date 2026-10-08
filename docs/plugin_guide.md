# Plugin Guide

Describes the report and analysis scripts in `scripts/plugins/`, the utilities they depend
on in `scripts/utilities/`, and the conventions for adding a new one.

All scripts assume the MATLAB Project is open (it puts every folder on the path). Reports
are written to `outputs/reports/` via `getOutputDir`.

## Entry points

| Script | Purpose |
|---|---|
| `scripts/runAllReports.m` | Loads `SYSTEM` and runs `systemsReport`, `verifyRequirementAllocations`, `fuelAnalysis`, `generateInterfaceReport`, and `GenerateWeightTableReport` in sequence |
| `scripts/runAllTests.m` | Runs every test in `scripts/tests/` and prints a summary table |

## Reports and analyses (`scripts/plugins/`)

| Script | What it does | Output (`outputs/reports/`) | Modifies model? |
|---|---|---|---|
| `systemsReport(cmd)` | Producer and consumer totals for the electrical, fuel, lube, cooling, compressed air and waste domains (active variants only) | `SystemsReport_Run_NNN.txt` | No |
| `GenerateWeightTableReport(cmd)` | Weight, margin and CoG table with displacement totals with and without margin | `WeightsAndMarginsReport_Run_NNN.txt` | No |
| `fuelAnalysis()` | Propagates pipe fluid types, validates 52X connections, and rolls child values up to parents | `FuelValidationReport.txt`, `FuelSystemSummary.txt` | **Yes**: saves pipe fluids; writes parent roll-ups (unsaved) |
| `generateInterfaceReport()` | Traces connectors to leaf source and target components, with interface type and criticality | `InterfaceReport.txt` | No |
| `verifyRequirementAllocations()` | Two-way allocation check: requirements without components, and components without requirements | `UnallocatedReq.txt` | No |
| `changeImpactReport(optArg)` | Compares numbered report runs and plots changes (plain-text live function) | `Change_Impact_Summary.txt`, `Change_Impact_Plots.pdf` | No |
| `electricalTesting(margin)` | Prints the electrical generation margin and utilization against a desired margin (plain-text live function) | Command Window | No |

Passing `"clear"` or `"reset"` to `systemsReport` / `GenerateWeightTableReport` **deletes**
their previous numbered reports.

> **Caution:** `fuelAnalysis` changes the model. Because its parent roll-ups stay in memory, a
> later report in the same session can double-count parent and child values. Run it last, or
> close `SYSTEM` without saving afterwards. See `handoff/known_issues.md`.

## Utilities (`scripts/utilities/`)

| Function | Purpose | Modifies model? |
|---|---|---|
| `applyProperties(xlsxFile)` | Applies stereotypes and property values from an Excel table (4-row header: profile, stereotype, property, units) | Yes |
| `stripProperties()` | Removes stereotype property values from all components | Yes |
| `rebuildProperties()` | `stripProperties`, then `applyProperties` on `FuelProp.xlsx` and then `Properties.xlsx` | Yes |
| `applyPortProp()` | Applies the port profile and assigns interfaces from port-name tags | Yes |
| `configureShip()` | Selects variant choices (propulsion, PTO, fuel piping) from the settings at the top of the file, then saves | Yes |
| `sumProp(prop, stereotype, profile)` | Sums a stereotype property over active components | No |
| `sumPropIfOn(prop, stereotype, profile)` | Like `sumProp`, but only components whose `Status` is on | No |
| `calcShipDisp_CoG(stereotype, profile)` | Displacement and LCG/VCG/TCG over active components | No |
| `marginCalcShipDisp_CoG(stereotype, profile)` | Same, with per-component weight margin applied | No |
| `getOutputDir(sub)` | Absolute path to `outputs/<sub>`, created if needed | No |

## Adding a new report or analysis

1. Put the function in `scripts/plugins/` and add it to the project.
2. Write output only under `getOutputDir(...)`. Never use a relative folder.
3. Do **not** save or modify the model in an analysis. Keep model-changing scripts in
   `scripts/utilities/` and name them as actions (`apply…`, `configure…`, `rebuild…`).
4. Enumerate components the same way as the existing utilities (active variant choices
   only). A single shared traversal function is planned. Reuse it once it lands.
5. Start the file with an H1 help line (`%NAME One-line description`) and syntax help.
6. If the analysis should run in the batch, add it to `runAllReports.m`.
