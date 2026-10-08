# Scripts Guide

The reference list of every script, with outputs and build tasks, is in
[`developer_guide.md`, Section 6](developer_guide.md#6-scripts-shared-package-analyses-build-utilities).
This page covers how to add to them.

## Where things go

| Folder | Contents | May modify the model? |
|---|---|---|
| `scripts/+shipmbse/` | Shared package: traversal, property reading, calculations | No |
| `scripts/analysis/` | Reports and analyses | **No** |
| `scripts/build/` | Utilities that change the model or link sets | Yes, and their help says so |
| `scripts/utilities/` | Legacy wrappers (`sumProp`, `calcShipDisp_CoG`, ...) and `getOutputDir` | No |
| `scripts/tests/` | Requirement verification tests (linked to requirements) | No |
| `scripts/tests/unit/` | Code tests for the scripts themselves | No |

## Adding an analysis or report

1. Put the calculation in `+shipmbse` as a function that takes the model (`model = shipmbse.loadModel()` by default) and **returns tables/structs**. Put the file writing in a thin wrapper in `scripts/analysis/`.
2. Enumerate components only with `shipmbse.activeComponents`. Never call `find`/`findElementsOfType` directly. Never sum over `shipmbse.allComponents` (it includes inactive choices and variant containers).
3. Read values with `shipmbse.getProp` / `shipmbse.sumProperty`. They return typed values and units; never parse property strings yourself.
4. Take names (model, paths, stereotypes) from `shipmbse.config`; add new ones there.
5. Write files only under `getOutputDir(...)`; use `shipmbse.reportFile(prefix)` for numbered runs.
6. Never save, `setProperty` or `applyStereotype` in an analysis. If a step must change the model, make it a separate script in `scripts/build/`.
7. Start the file with an H1 help line (`%NAME One-line description`) and syntax help; validate inputs with an `arguments` block.
8. Add a unit test in `scripts/tests/unit/test_shipmbse.m`, with hand-calculated expected values against the MiniShip fixture (`buildMiniShip`; extend it if needed).
9. If it should run in the batch, add it to `runAllReports.m` (and, if it produces numbers worth comparing, to `shipmbse.snapshot`).
10. Run `buildtool` before committing: Code Analyzer warnings fail the build.

## Adding a model-editing utility

Same rules, except it lives in `scripts/build/`, may use `shipmbse.allComponents`, and its help states that it modifies the model and whether it saves. Check that running it twice leaves the same result (the property rebuild is checked this way).
