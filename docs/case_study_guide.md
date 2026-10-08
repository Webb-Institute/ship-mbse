# Case Study Guide

**Status: planned.** No reference case study exists yet.

The planned reference case study is the common platform with the **command/C2 mission
module**. It will be run end to end, from model configuration to the generated design data
book, with results captured in `outputs/case_study/` and a tagged release for
reproducibility. It depends on the mission-module and analysis work in
[`handoff/future_work.md`](../handoff/future_work.md) (Phases 4–6).

Until then, the closest end-to-end workflow is:

1. Open the project (`openProject`).
2. Set variant choices in `scripts/utilities/configureShip.m` and run it.
3. Run `rebuildProperties` to apply the Excel property tables.
4. Run `runAllTests` and `runAllReports`, then review `outputs/reports/`.

Note that property data is placeholder (see [`assumptions_and_limits.md`](assumptions_and_limits.md)).
