# Assumptions and Limitations

Modeling assumptions, simplifications, and known limitations of the ship-mbse model and
scripts. For specific defects, see [`handoff/known_issues.md`](../handoff/known_issues.md).

## Assumptions

- **Concept:** a Military Sealift Command multi-purpose vessel with common fore and aft sections
  and a swappable mission midbody. The current model does not yet separate platform from
  midbody; mission equipment sits in `55X (CARGO/MISSION)` and `70X–74X`.
- **Breakdown:** the physical hierarchy follows an **SWBS-style numbering** (groups 100–700,
  tens-level subgroups ending in `X`). It is **not ESWBS**: numbers below the group level have
  different meanings than in Navy ESWBS. The model keeps its own IDs; a mapping to ESWBS is
  maintained separately.
- **Level of detail:** most subsystems are modeled at the tens level (e.g. `50X`). Only Fuel
  (`52X` → `520–529`) is decomposed to the units level.
- **Local systems:** hydraulic systems are assumed to be local to the subsystems that use them,
  not an independent system.
- **Connections:** physical connections between the hull (`10X PLATE`) and each group represent
  structural support (foundations). Signal connections represent mass, energy or information flow
  and are named `<source>-<destination><tag>` (see the glossary).
- **What counts as "the configuration":** every component at every level whose variant choices
  are active. Each variant is represented by its active choice; variant containers and inactive
  choices are never counted. Data may sit at more than one level (e.g. `52X FUEL` holds the fuel
  system's weight while its children hold component data). Totals are only correct if a component
  and its descendants never carry the same stereotype; `shipmbse.findStereotypeOverlaps` checks this
  and the regression test enforces it.
- **Operating state:** each stereotype has a boolean `Status` (on/off). Balances count only
  components that are on.
- **Margins:** weight margin is a per-component percentage applied to that component's weight.
- **Coordinates:** LCG, VCG and TCG are in metres in a single global ship frame. The origin and
  axis conventions (aft perpendicular, baseline, centerline) are not yet formally documented.

## Limitations

- **Placeholder data:** every property value is `Maturity = Placeholder`, not an engineering
  estimate. Totals, margins and test outcomes are **not meaningful for design decisions** yet.
  Replace values row by row and raise the row's Maturity as you do.
- **Units** (October 2026): fuel and lube rates t/h, fuel stored t, tank volumes m³, pipe and
  pump flows m³/h, compressed air Nm³/h, waste gas kg/h, waste water and waste oil m³/day,
  solid waste kg/day, power and heat kW. Units are defined in the profiles and reported with
  every value. Balances refuse to compare quantities with different units.
- **Densities:** tank volumes are converted to fuel mass with nominal densities (HFO 0.98, MDO
  0.89, F-76 0.85, JP-5 0.81, lube 0.90 t/m³) in `shipmbse.config`.
- **Migrated values:** the October 2026 unit migration converted the existing placeholder values
  numerically, so some magnitudes are not physical (e.g. lube oil in thousands of t/h). Every
  such row is marked `Maturity = Placeholder`; reports say when all data is placeholder.
- **Interfaces** have no elements, so no flow, pressure, temperature, voltage or data content is
  modeled or checked at connections.
- **No operating conditions** (in-port, transit, mission, emergency). Electrical and fluid
  balances are single-point.
- **No hydrostatics or stability.** Displacement and CoG are summed from component properties;
  there is no hull form, tank model, free-surface effect or loading condition.
- **No behavior.** The architecture is structural only; there are no state machines,
  sequences, or Simulink/Simscape behavior models.
- **Requirements** are mostly qualitative, and the set has no custom attributes for thresholds,
  so few requirements can be verified automatically.
- **Single model file:** the whole architecture is in one binary `SYSTEM.slx`, which limits
  concurrent editing.
