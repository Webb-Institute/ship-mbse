# Known Issues

Open defects and gaps as of October 2026, from the baseline review of `main` @ `4d4d2c5`.
Remove an item here when its fix is merged.

## Model and interfaces

- **Interfaces are empty.** All 25 interfaces in `SYSTEM.slx` (13 physical, 12 data) have zero elements.
- **`InterfaceDictionary.sldd` is not attached** to `SYSTEM.slx`, and its interface names differ from
  the model's (`CompressedAir` vs `CompAir_P`).
- **No external interfaces.** ENVIRONMENT and STAKEHOLDERS have no ports, so the ship has no
  modeled external interfaces.
- Variant choices use default port names (`Bus Element In1…n`). One physical port on
  `20X (MAIN ENGINE)` is unconnected.
- Name typos are hard-coded in scripts, so they can't be fixed by renaming alone:
  `500 (AUXILLIARY SYSTEMS)`, `60X (ACCOMODATION)`, and `MANUVERING` in variant control labels.
- Model IDs reuse ESWBS numbers with different meanings (e.g. model 52X = Fuel, ESWBS 520 =
  Sea Water). A mapping document is planned.

## Profiles and data

- **Property values are placeholders** and not engineering data (e.g. Shore Power = 976 t).
- Several units don't suit the domain: kL/s for fuel, compressed air, waste gas and solid
  waste; kW for "cooling consumed".
- Duplicate definitions: `Weights` (FuelComponentProfile) vs `WeightsCenters`; `Redundancy` in
  both CritRelRedProfile and PortProfile. `PowerRequired` on Pump and Controller isn't counted
  in electrical totals unless the component also has `ElectricalConsumer`.
- `Pipe`, `HeatConsumer/Producer`, `WasteOilProducer` and `WasteReceiver` apply to all element
  types (`<None>`).
- Operating state is a single boolean `Status`; there are no operating conditions.
- `applyProperties` applies a variant container's values to **all** its choices, ABSENT ones
  included, and the result depends on the order the spreadsheets are applied.

## Requirements and traceability

- The requirement set has **no custom attributes** (`PerfVal1` etc.), so requirement-driven
  tests can't read thresholds.
- Most requirements are qualitative. REQ-505, 508 and 511–513 contain placeholders
  (`[vi]`, `[d]`, `[X]`, `[D]`). All NEED items are typed Functional.
- Dangling links were repaired in October 2026; 8 allocations need an engineering review.
  See [`traceability_repair_2026-10.md`](traceability_repair_2026-10.md).
- `test_Req_FuelEndurance_02` has no requirement link.

## Scripts and tests

| Location | Issue |
|---|---|
| `scripts/tests/getFuelSystemEndurance.m:245,262` | Endurance = kL ÷ kL/s = **seconds**, reported as days (86,400× optimistic) |
| `scripts/plugins/fuelAnalysis.m:798` | `finally` is not a MATLAB keyword; the summary file is never closed on success |
| `scripts/plugins/fuelAnalysis.m` | Saves the model; writes parent roll-ups that later reports can double-count |
| `GenerateWeightTableReport.m`, `systemsReport.m:77-85`, `marginCalcShipDisp_CoG.m` | Inconsistent variant filtering: table rows and totals can come from different component sets |
| `calcShipDisp_CoG.m:46`, `marginCalcShipDisp_CoG.m:42` | A component's weight is dropped when any CoG coordinate is missing |
| `marginCalcShipDisp_CoG.m:55-57`, `electricalTesting.m` | Divide by zero when nothing is found or generation is 0 |
| `getFuelSystemEndurance.m:115` | `sum(unique(...))` drops tanks with equal capacities |
| `getFuelSystemEndurance.m:285-292` | `evalin('base')` lets workspace variables override model data |
| `getLinkedPerfVal.m` | Turns all warnings off; searches the current folder; `"REQ-406"` parses as −406 |
| `verifyRequirementAllocations.m:174,181` | Matches any artifact containing "SYSTEM"; ignores link type |
| `generateInterfaceReport.m:638-743` | "Criticality" taken from any ancestor, sibling or connector; sort at `:403` does nothing |
| `applyPortProp.m:153-199, 341-361` | Interface inferred from name (any name ending in "C" becomes Control); mismatches silently overwritten |
| `test_elec/fuel/lube/cooling/cAir` | Pass vacuously when no matching components are found |
| `test_ExistComp_01.m:16-23` | Dereferences before asserting; `verifyNotEmpty("")` passes |
| `runAllReports.m` | Catches every error and always prints "ALL REPORTS COMPLETE" |
| Many scripts | Model name `'SYSTEM'` and component paths are hard-coded; about 10 separate component traversals |

## Repository

- `SYSTEMCOMPLEX.slx` was removed from `main` in October 2026. It is preserved at the git tag
  `archive/systemcomplex-2026-07`.
- `SYSTEM.slx` is a single 9.5 MB binary file, so concurrent edits conflict. Splitting it into
  per-group referenced models under a master `SYSTEM` is planned.
- No CI. Tests and checks run only locally.
