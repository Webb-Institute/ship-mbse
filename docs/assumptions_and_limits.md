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
- **Operating state:** each stereotype has a boolean `Status` (on/off). Totals sum only active
  variant choices and, where `Status` is used, only components that are on.
- **Margins:** weight margin is a per-component percentage applied to that component's weight.
- **Coordinates:** LCG, VCG and TCG are in metres in a single global ship frame. The origin and
  axis conventions (aft perpendicular, baseline, centerline) are not yet formally documented.

## Limitations

- **Placeholder data:** property values in `data/input_tables/*.xlsx` are illustrative, not
  engineering estimates. Totals, margins and test outcomes are **not meaningful for design
  decisions** yet.
- **Units:** several flow quantities use kL/s, which doesn't suit fuel, air or waste streams.
  Units are stored as text in the Excel header and are not converted.
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
