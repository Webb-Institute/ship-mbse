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

## Design results that fail or disagree (current placeholder data)

These are findings about the **design data**, surfaced by the corrected tools. They are not
software defects.

- **Fuel endurance fails REQ-402/403:** 5.79 days (heavy fuel oil limits) vs. 100 days required.
  The old script reported "250,000 days" because it returned seconds and double-counted demand.
- **Waste water shortfall:** production 26 kL/s vs. receiving capacity 25 kL/s.
- **Placeholder magnitudes:** the unit migration converted existing placeholder values
  numerically, so several are not physical (e.g. lube oil demand in thousands of t/h, solid
  waste in hundreds of millions of kg/day). All rows are `Maturity = Placeholder`.
- Components implementing no requirement: `520 (FUEL INTAKE/RETURN)`, `529 (FO POWER
  DISTRIBUTION)` (plus the 500/600 group levels and ENVIRONMENT/STAKEHOLDERS).

## Requirements and traceability

- Most requirements are qualitative. Only REQ-402 (100 day) and REQ-403 (1 %) have a
  `Threshold` attribute so far. REQ-505, 508 and 511–513 contain placeholders (`[vi]`, `[d]`,
  `[X]`, `[D]`). All NEED items are typed Functional.
- 8 of 102 requirements are verified by a test.
- Dangling links were repaired and reviewed re-links applied in October 2026; see
  [`traceability_repair_2026-10.md`](traceability_repair_2026-10.md).
- The Requirements Editor's verification-status column (running linked tests from the
  requirement set) has not been confirmed to work; running it once dropped the MATLAB session.

## Scripts and tests

The defects found in the October 2026 review (seconds-as-days endurance, `finally`, variant
double-counting, model-modifying reports, vacuous tests, hard-coded names, etc.) were fixed in
Phase 1. Remaining:

| Location | Issue |
|---|---|
| `scripts/build/applyPortProp.m` | Interface inferred from the port-name tag (any name ending in "C" becomes Control); mismatched interfaces on connected ports are overwritten without a report. To be replaced by explicit interface assignment |
| Linked test files | Requirement links are stored as character ranges; after editing a linked test outside the MATLAB Editor, run `updateTestLinkRanges` |

## Data files and profiles

- `data/input_tables/CaseSpecificProperties/CaseSpecificProperties.xlsx` is **legacy and unused**.
  It was not migrated to the new units, and it names variant containers, which `applyProperties`
  rejects. Migrate or delete it before using it.
- `FuelComponentProfile` still defines deprecated duplicate properties (`PowerRequired`,
  `LubeConsumption`, `CoolConsumption`, `HeatConsumed`, `WasteOilProduced`, and the `Weights`
  stereotype). They are unused and will be removed in the profile consolidation.
- Duplicate `Redundancy` stereotypes (CritRelRedProfile and PortProfile) remain.

## Repository

- `SYSTEMCOMPLEX.slx` was removed from `main` in October 2026. It is preserved at the git tag
  `archive/systemcomplex-2026-07` and on the `version1` snapshot branch.
- `SYSTEM.slx` is a single 9.5 MB binary file, so concurrent edits conflict. Splitting it into
  per-group referenced models under a master `SYSTEM` is planned.
- No CI yet. `buildtool` runs checks and tests locally (CI needs a licensed runner).
