# **Developer & Handoff Notes**

Ship MBSE Architecture Framework

**Table of Contents**

* Project Handoff Summary  
* 1\. Toolchain & Repository Setup  
* 2\. System Overview & Architecture Hierarchy  
* 3\. Bus Domain Architecture (Model Workspace)  
* 4\. Key Architectural Design Rules Refinement  
* 5\. Stereotype & Profile Data Dictionary  
* 6\. Custom Helper Functions & Architecture Utilities  
* 7\. Adding Components, Ports, Connections & Metadata Assignment  
* 8\. Requirements Management, Verification Testing & Custom Registries  
* 9\. Recommendations for Future Work  
* Known Issues and Limitations  
* Developer Tips & Onboarding Guide

## **Project Handoff Summary**

### **Project Status**

The **SYSTEM** architecture has progressed from an initial structural model to a functional MBSE framework supporting architecture development, property management, requirement traceability, and automated verification. The project currently provides a reusable architectural foundation rather than a complete digital twin.

At the conclusion of this development effort:

* The top-level ship architecture and SWBS hierarchy have been established.  
* The bus interface architecture and Interface Dictionary have been developed.  
* Component stereotypes and property assignment workflows have been automated.  
* Requirement allocation and verification infrastructure has been implemented.  
* Initial verification tests have been developed for several ship subsystems.

The remaining effort is primarily focused on expanding subsystem models, populating engineering properties, increasing requirement coverage, and connecting behavioral Simulink/Simscape models to the architecture.

## **1\. Toolchain & Repository Setup**

The ship-mbse architecture framework runs in MATLAB R2026a with System Composer, Requirements Toolbox, and Simulink, managed as a MATLAB Project (`ship-mbse.prj`). The project sets the MATLAB path, so always work with the project open.

### **1.1 Workspace Directory Structure**

The project root directory is organized into standardized modular folders:

* /model/: System Composer model (`/model/system_composer/SYSTEM.slx` and its link set `SYSTEM~mdl.slmx`), profile definition files (/model/profiles/), requirement sets (/model/requirements/), and exported views.  
* /scripts/: Entry points `runAllTests.m` and `runAllReports.m`; the shared package (/scripts/+shipmbse/); read-only reports (/scripts/analysis/); model-changing utilities (/scripts/build/); legacy wrappers (/scripts/utilities/); requirement verification tests (/scripts/tests/) and code tests (/scripts/tests/unit/).  
* buildfile.m: build tasks (`buildtool`); see Section 6.4.  
* /data/: Input Excel configurations (/data/input\_tables/Properties.xlsx and FuelProp.xlsx), trade study parameters, and saved analysis results.  
* /outputs/: Generated output (not committed): `reports/`, `figures/`, `snapshots/` (for change impact), `test-results/` (JUnit, coverage).  
* /handoff/: Known issues, future work, and maintenance logs (e.g. `traceability_repair_2026-10.md`).  
* InterfaceDictionary.sldd: Interface data dictionary. **Not yet attached to SYSTEM.slx**: the model currently uses its own local interfaces (see Section 3).  
* /work/: Simulink cache and code generation folders (created locally, not committed).

### **1.2 Project Initialization Workflow**

1. Open MATLAB R2026a.  
2. Open the project: double-click `ship-mbse.prj`, or run `openProject("<path to repo>")`. This puts every model, requirement, data, and script folder on the path. No manual `addpath` is needed.  
3. Use the project shortcuts (Project tab): **Open SYSTEM (master model)**, **Configure ship variants**, **Rebuild properties from Excel**, **Run all tests**, **Run all reports**.  
4. From the command line: `buildtool` runs the code checks and tests; `buildtool verify` runs the requirement verification tests; `runAllReports` writes all reports to `outputs/reports/` (see Section 6).

When you add a file, add it to the project too (right-click > Add to Project). The project's integrity checks (Project tab > Run Checks) must pass before you commit.

## **2\. System Overview & Architecture Hierarchy**

The SYSTEM model defines a modular marine/industrial system architecture structured around standard naval ship work breakdown structure (SWBS / SBN) numerical taxonomy. The top-level hierarchy organizes functional domain groups, sub-groups, and component choices using System Composer blocks and Variant Containers.

### **2.1 Structural Group (100 Series)**

Encompasses structural hull mass distribution and geometric centers, including hull plating (10X), primary transverse ring framing (11X), longitudinal stiffeners, decks, and internal bulkheads (12X). Plate 10X acts as the main structural interface across systems 20X through 74X.

### **2.2 Propulsion & Prime Mover Group (200 Series)**

Covers primary propulsion drivers and mechanical power transmission, including main propulsion diesel engines (20X), reduction gearboxes, shaft lines, propellers, and maneuvering thrusters (21X). Component 20X operates as a Variant Subsystem configured with an active engine choice or an inert (absent) choice.

### **2.3 Electrical Group (300 Series)**

Includes primary ship service power generation (diesel generators), emergency power sources, switchboards, bus ties, transformers, and power distribution loops servicing consumer loads.

### **2.4 Command, Control & Surveillance Group (400 Series)**

Covers navigation, sensor suites, internal/external communication links, integrated platform management systems (IPMS), and dynamic positioning controls. Boundary interface 42X provides command and monitoring signals to propulsion and auxiliary equipment.

### **2.5 Auxiliary & Fluid Services Group (500 Series)**

Represents ship support fluid and auxiliary networks organized into functional breakdown domains:

* **50X Cooling & Freshwater:** Chilled water plants, air handling units, and compartment climate control. Also included FW generation, storage, and distribution.  
* **51X Lubricating Oil Systems:** Storage tanks, transfer pumps, and engine lube oil conditioning networks  
* **52X Fuel Oil Systems:** Comprehensive fuel handling including intake/overflow (520), storage tanks (521), transfer pumps (522), purifiers/conditioners (523), fuel distribution (524), and fuel supply piping (525-527).  
* **53X Compressed Air Systems:** High-pressure starting air receivers, service air compressors, and control air lines.  
* **54X  Ballast and Saltwater Systems:** Ballast water pumps, piping and storage. SW supply to heat exchangers.  
* **55X Mission / Cargo Systems:** Any equipment and storage necessary to carry out the vessel’s mission.  
* **56X Deck Machinery:** Mooring and cargo handling equipment with their necessary hydraulics.  
* **57X Waste & Environmental Systems:** Oily water separators, sewage treatment, solid waste collection, and waste heat recovery / emissions scrubbing  
* **58X Fire Systems:** Pumps, manifolds, and other equipment used in fire suppression.  
* **59X Hotel Systems:** HVAC, Plumbing and Electrical equipment for accommodations and their services.

### **2.6 Outfit, Armament (600–700 Series)**

Covers accommodations, life safety infrastructure, and any vessel armaments.

### **Current Development Status**

The following summarizes the implementation status of each major ship system.

| SWBS Group | Current Status | Notes |
| :---: | :---: | :---: |
| **100 Hull Structure** | Architecture Complete | Primary structural hierarchy established. Weight properties partially populated. |
| **200 Propulsion** | Partially Complete | Variant subsystem implemented. Additional propulsion equipment remains to be modeled. |
| **300 Electrical** | Architecture Defined | Requires additional component properties and verification tests. |
| **400 Command & Control** | Architecture Defined | External interfaces established. Functional behavior not yet implemented. |
| **500 Auxiliary Systems** | Partially Complete | Fuel system has the highest level of implementation and automated testing. |
| **600 Outfit** | Placeholder | Minimal component detail currently modeled. |
| **700 Armaments** | Placeholder | Minimal component detail currently modeled. |

## 

## **3\. Bus Domain Architecture (Model Workspace)**

The architecture standardizes all physical and signal connections across system boundaries using paired Physical (\_P) and Signal (\_S) Connection Buses defined in modelWorkspace.mxarray:

| Domain | Physical Bus (\_P) | Signal/Control Bus (\_S) | Description |
| :---: | :---: | :---: | :---: |
| **Compressed Air** | CompAir\_P | CompAir\_S | Pneumatic power & starting/control air |
| **Control** | Control\_P | Control\_S | Engine governor, safety & command signals |
| **Freshwater Cooling** | CoolingFW\_P | CoolingFW\_S | HT/LT jacket water cooling loops |
| **Fuel Oil** | FuelOil\_P | FuelOil\_S | Fuel supply lines & pressure/flow status |
| **Lube Oil** | LubeOil\_P | LubeOil\_S | Engine lubrication feed & monitoring |
| **SaltWater** | SaltWater\_P | SaltWater\_S | Seawater cooling intake/discharge |
| **Thermal / Power** | Heat\_P, Power\_P | Heat\_S, Power\_S | Heat exchange & electrical generation |
| **Waste Management** | WasteOil\_P, WasteWater\_P, WasteSolid\_P, WasteGas\_P | WasteOil\_S, WasteWater\_S, WasteSolid\_S, WasteGas\_S | Drainage, bilge, waste processing, and exhaust manifolds |

> **Current status (October 2026):**
> * The 25 interfaces above (13 physical, 12 data) exist as model-local interfaces in `SYSTEM.slx`, but **none has any elements yet**. They identify a domain but carry no flow, pressure, voltage, or signal content.
> * `InterfaceDictionary.sldd` is **not attached** to the model and uses different names (e.g. `CompressedAir` rather than `CompAir_P`).
> * Port *names* do not carry `_P`/`_S` suffixes. `applyPortProp` infers the interface from the connection tag at the end of the port name (see the glossary).
>
> Moving the interfaces into the shared dictionary with real elements is planned future work.

## **4\. Key Architectural Design Rules Refinement**

The rules below are the intended design rules. They are not yet enforced automatically; see the status note in Section 3.


* **Strict Bus Domain Typing:** All signal connections between subsystems must bind to their specific \_S connection bus type (e.g., Bus: LubeOil\_S, Bus: Control\_S), ensuring strong type-checking at system boundaries.  
* **Physical / Signal Separation:** Fluid flow, mechanical load, and thermal transfer are strictly handled via \_P physical bus ports, while monitoring, commands, and telemetry are handled via \_S standard Simulink composite bus ports.  
* **Variant Management:** Component 20X utilizes variant controls (VariantControl \= "20X DIESEL ENGINE" vs "20X ABSENT"). When absent, all physical and signal boundaries default to inactive stubs without breaking model hierarchy connections.

## 

## 

## 

## **5\. Stereotype & Profile Data Dictionary**

Property values are entered in two Excel tables (`data/input_tables/`): `Properties.xlsx` for ship-level data, and `FuelProp.xlsx` for the fuel system's components. `rebuildProperties` applies them to the model (Section 7.1). Units are defined in the profiles; the tables' unit row must match.

Numeric properties default to `NaN`. A value that was never entered reads as `NaN`, is reported as *missing*, and is never summed as zero.

### **5.1 Ship-level profiles**

| Profile | Stereotypes | Properties (units) |
| :--- | :--- | :--- |
| WeightsCentersProfile | WeightsCenters | Weight (t), LCG / VCG / TCG (m), WeightMargin (%) |
| ElectricalProfile | ElectricalConsumer, ElectricalGenerator | PowerRequired, PowerGenerated (kW); PowerFactor; Status |
| FuelProfile | FuelConsumer, FuelProducer | FuelRequired (t/h), FuelType (text); FuelProduced (t/h), FuelStored (t); Status |
| LubeProfile | LubeConsumer, LubeProducer | LubeRequired, LubeProduced (t/h); LubeStored (m³); Status |
| CoolingProfile | CoolConsumer, CoolProducer | CoolConsumed, CoolProduced (kW heat load); Status |
| CompAirProfile | AirConsumer, AirProducer | AirConsumed, AirProduced (Nm³/h); Status |
| HeatProfile | HeatConsumer, HeatProducer | HeatConsumed, HeatProduced (kW); Status |
| WasteProfile | WasteGas/Oil/Water/SolidProducer, WasteReceiver | Waste gas (kg/h); waste oil and waste water (m³/day); solid waste (kg/day); Status |
| ShipElementProfile | DataRecord | Maturity (Placeholder, Parametric, Calculated, Vendor, Measured), DataSource (text) |
| CritRelRedProfile, PortProfile | Criticality, Redundancy, Reliability | Scores (unitless) |

Volume and mass are linked by nominal fluid densities in `shipmbse.config().FluidDensity` (t/m³ at 15 °C): HFO 0.98, MDO 0.89, F-76 0.85, JP-5 0.81, lube oil 0.90. These are assumptions; replace them with project values when known.

### **5.2 Fuel system component profile (FuelComponentProfile)**

| Stereotype | Properties (units) |
| :--- | :--- |
| Tank | Primary/Secondary/Tertiary FluidCapacity and FluidLevel (m³); PriFluid/SecFluid/TerFluid (text) |
| Pump, FluidConditioner | MaxFlowCapacity, Pri/Sec/TerFlowRate (m³/h); fluids (text); Status |
| Pipe | Diameter, Length (m); FlowRate (m³/h); FluidDensity (kg/m³); Fluid (text); Status |
| Controller | Status |

**The fuel system's totals are the sum of its components** (decision, October 2026). The fuel system component `52X FUEL` carries no weight, power or other summary values of its own. Its parts (520–529) carry the ship-level stereotypes (WeightsCenters, ElectricalConsumer, CoolConsumer, LubeConsumer, HeatConsumer, WasteOilProducer, and FuelProducer on the supply pipes), so ship totals include them. `fuelAnalysis` reports the fuel system totals and flags any summary value put back on `52X FUEL`.

`FuelComponentProfile` still defines `PowerRequired`, `LubeConsumption`, `CoolConsumption`, `HeatConsumed`, `WasteOilProduced` and the `Weights` stereotype. They are **deprecated and unused**: use the ship-level stereotypes instead. They will be removed in the profile consolidation.

## **6\. Scripts: Shared Package, Analyses, Build Utilities**

All scripts follow three rules:

1. **One traversal.** Every report, analysis and test enumerates components through `shipmbse.activeComponents`. It returns every component in the *active configuration*, at every level, with each variant represented by its **active choice**. Variant containers are never returned, and inactive choices are skipped. This is the only definition of "the configuration" that totals may use.
2. **Analyses never modify the model.** Anything in `scripts/analysis/` only reads. Anything that changes the model or link sets lives in `scripts/build/` and says so in its help.
3. **No hard-coded names.** The model name, component paths, stereotype names and Excel file names live in `shipmbse.config`.

Run `help <function>` for full syntax.

### **6.1 Shared package (`scripts/+shipmbse/`)**

| Function | Purpose |
| :--- | :--- |
| `config` | Central names: model, requirement set, component paths (Simulink block paths; a `/` inside a name is written `//`), stereotypes, Excel files, fuel consumer → pipe map |
| `loadModel` | Load the architecture model without opening an editor |
| `activeComponents` | The traversal (see rule 1). Options: `LeavesOnly`, `Stereotype`, `AllVariantChoices` (for traceability only, never for totals) |
| `allComponents` | Every component including containers and inactive choices. **Build utilities only** |
| `getProp`, `propertyInfo` | Typed property values, units from the profile, and a flag when a value still equals the profile default |
| `sumProperty` | Sum a property over the configuration, optionally only components whose `Status` is on; returns per-component details |
| `serviceBalance` | Demand vs. capacity (margin) per domain: electrical, fuel, lube, cooling, air, heat, waste streams |
| `massProperties` | Weight and LCG/VCG/TCG with and without margin; missing centres are excluded from the CoG and reported, never silently dropped |
| `fuelEndurance`, `durationToDays` | Endurance per fuel type in days, with unit conversion (kL ÷ kL/s → s → days) |
| `interfaceConnections` | Leaf-to-leaf connections traced through composite and variant boundaries |
| `traceability` | Requirement ↔ architecture (Implement links) and requirement ← test (Verify links) coverage |
| `findStereotypeOverlaps` | Components that share a stereotype with a descendant (double-count risk) |
| `linkedRequirements`, `reqValue` | Requirement(s) a test verifies; strict reading of `Threshold`, `Units`, `RequiredComponent` attributes |
| `snapshot` | Capture configuration, balances, mass and endurance for change-impact comparison |
| `reportFile`, `sortByModelId`, `pathLeaf` | Report file numbering, ordering by model ID, splitting block paths |

The legacy functions `sumProp`, `sumPropIfOn`, `calcShipDisp_CoG`, `marginCalcShipDisp_CoG` and `getFuelSystemEndurance` (`scripts/utilities/`) keep their original signatures and are thin wrappers over the package.

### **6.2 Analyses (`scripts/analysis/`, read-only)**

| Script | Output (`outputs/reports/`) |
| :--- | :--- |
| `systemsReport` | `SystemsReport_Run_NNN.txt`: demand, capacity and margin per domain; shortfalls flagged |
| `generateWeightTableReport` | `WeightsAndMarginsReport_Run_NNN.txt`: component weights and ship totals with and without margin |
| `verifyRequirementAllocations` | `TraceabilityReport.txt` |
| `fuelAnalysis` | `FuelAnalysisReport.txt`: connection checks inside the fuel system, and the children's roll-up compared with the fuel system's own values |
| `generateInterfaceReport` | `InterfaceReport.txt`: leaf-to-leaf connections by interface; interface mismatches |
| `changeImpactReport` | `Change_Impact_<a>_vs_<b>.txt` and a figure, comparing two snapshots |
| `electricalTesting` | Command-window margin and utilization check |

`runAllReports` runs all of them, saves a snapshot to `outputs/snapshots/`, and errors if any report failed. To see what a design change did: run `runAllReports`, change the model, run it again, then `changeImpactReport`.

### **6.3 Build utilities (`scripts/build/`, modify the model)**

| Script | What it changes |
| :--- | :--- |
| `configureShip(Name=Value)` | Active variant choices for propulsion and fuel; saves |
| `applyProperties(file)`, `stripProperties`, `rebuildProperties` | Stereotypes and property values from the Excel tables |
| `applyPortProp` | Port profile and interfaces inferred from port names; saves |
| `propagatePipeFluids` | Copies each fuel consumer's `FuelType` onto its supply pipe's `Fluid`; saves |
| `updateTestLinkRanges` | Re-anchors each test's requirement link to its test function after the file was edited outside the MATLAB Editor |

### **6.4 Build tasks (`buildfile.m`)**

| Command | Runs |
| :--- | :--- |
| `buildtool` | `check` + `test` (default) |
| `buildtool check` | Code Analyzer over `scripts/`; any warning fails |
| `buildtool test` | Code tests (`scripts/tests/unit`): package unit tests against the MiniShip fixture and the SYSTEM regression baseline; JUnit and coverage in `outputs/test-results/` |
| `buildtool verify` | Requirement verification tests (`scripts/tests`) |
| `buildtool trace` | Traceability audit; fails on unresolved links or unimplemented requirements |
| `buildtool reports` | `runAllReports` |

A `test` failure means the tools are wrong. A `verify` failure means the *design* does not meet a requirement with its current data. That's why the two are separate gates.

## **7\. Adding Components, Ports, Connections & Metadata Assignment**

Building and expanding the SYSTEM model involves defining component blocks, establishing ports and connectors across standard components and variant architecture choices, and assigning metadata.

### **7.1 Component Excel Sheet Structure & Mapping Rules**

`applyProperties` reads each table using a 4-row header:

| Row | Content | Examples |
| :--- | :--- | :--- |
| **1** | Profile | WeightsCentersProfile, ShipElementProfile |
| **2** | Stereotype | WeightsCenters, DataRecord |
| **3** | Property | Weight, LCG, Maturity, DataSource |
| **4** | Units: **must equal the profile's units** for numeric properties (parentheses optional); `On/Off` for booleans; `string` or a list of allowed values for text | (t), t/h, Nm^3/h, On/Off |
| **5+** | Column A: component or **variant choice** name; then values. `N/A` or blank = no value | `20X DIESEL ENGINE`, 682, TRUE |

Every table starts with the two `ShipElementProfile.DataRecord` columns, **Maturity** and **DataSource**. Fill them for every row that has data.

Rules enforced by `applyProperties` (all problems are reported together, before anything changes):
* Unknown profiles, stereotypes, properties or components; unit mismatches; non-numeric values in numeric columns; and invalid Maturity values are errors.
* Rows must name a component or a variant **choice**, never a variant container.
* A stereotype is applied when the row has a value for it, and removed when all its columns are N/A. N/A inside an applied stereotype means "not known" (NaN).
* Applying a table twice, or the two tables in either order, gives the same model. Use `applyProperties(file, DryRun=true)` to validate only.

### 

### **7.2 Automated Port Interface Assignment**

The automated script applyPortProp() parses port names using a standardized multi-part identifier structure:

\[Start Component\]-\[Terminal Component\]\[System Designation\]\[Suffix\]

**Domain Suffix Rules (\_P vs \_S):** Appending \_P marks the port as a Physical Port (e.g., CoolingFW\_P). Appending \_S forces the port to be treated as a Data/Signal Port (e.g., Control\_S).

> **Note:** No port in the current model uses the `_P`/`_S` suffix. In practice `applyPortProp` maps the connection tag (e.g. `FO`, `LO`, `C`) to an interface. Any name ending in `C` is treated as Control, so check its results.

**Standard Development Workflow**

1. Create the System Composer component.  
2. Add its stereotypes and property values to the Excel property tables.  
3. Run `rebuildProperties(Save=true)`. It validates both tables first, then strips and reapplies.  
4. Allocate requirements to it (Implement links) in the Requirements Editor.  
5. Add or update verification tests (Section 8.4).  
6. Run `buildtool` (checks and code tests), `buildtool verify trace`, and `runAllReports`.  
7. If the change intentionally alters analysis results, update the expected values in `scripts/tests/unit/test_regressionBaseline.m` in the same commit and say why.

## **8\. Requirements, Traceability & Verification Tests**

Requirements live in `model/requirements/ShipRequirements.slreqx`. Three kinds of links connect them to the rest of the repository:

| Link type | From | Stored in | Meaning |
| :--- | :--- | :--- | :--- |
| Implement | Architecture component | `model/system_composer/SYSTEM~mdl.slmx` | The component allocates/implements the requirement |
| Verify | Test function | `scripts/tests/<test>~m.slmx` | The test verifies the requirement |

### **8.1 Traceability audit**

`verifyRequirementAllocations` (or `buildtool trace`) reports:
- every requirement that needs allocation (not Container/Informational) with no implementing component;
- which requirements are verified by a test;
- every component, across **all variant choices**, that implements no requirement;
- unresolved links.

A variant choice counts as allocated if it or its variant container has an Implement link.

### **8.2 Requirement attributes**

The requirement set defines these custom attributes:

| Attribute | Type | Use |
| :--- | :--- | :--- |
| `Threshold` | text, must be a number | Value the design must meet (e.g. REQ-402: `100`) |
| `Objective` | text, must be a number | Desired value |
| `Units` | text | Units of Threshold/Objective (e.g. `day`, `%`) |
| `VerificationMethod` | list | Analysis, Demonstration, Inspection, Test |
| `RequiredComponent` | text | Component that must exist and be active (existence checks) |

Requirements Toolbox has no numeric attribute type. `shipmbse.reqValue` therefore parses `Threshold`/`Objective` **strictly**: `"100"` is 100, while `"100 days"`, `""` and `"REQ-406"` are errors. With `Units=...` it also checks the requirement's units.

### **8.3 Verification tests (`scripts/tests/`)**

| Test | Verifies | Check |
| :--- | :--- | :--- |
| `test_elec`, `test_fuel`, `test_lube`, `test_cooling`, `test_cAir` | REQ-103, 111, 110, 109, 113 | Capacity that is on ≥ demand that is on (`verifyServiceBalance`). Fails if no demand component is on or if units differ |
| `test_ExistComp_01` | REQ-104 | The `RequiredComponent` exists and is in the active configuration |
| `test_Req_FuelEndurance_01` | REQ-402 | Fuel endurance ≥ `Threshold` days |
| `test_Req_FuelEndurance_02` | REQ-403 | Endurance ≥ REQ-402 days × (1 + `Threshold` %) |

Current verdicts (October 2026, placeholder data): REQ-402 and REQ-403 **fail** (endurance 5.79 days vs. 100 required). All others pass.

### **8.4 Writing and linking a new verification test**

1. Create `scripts/tests/test_<name>.m` with **one** test function:

```matlab
function tests = test_ElecMargin
%TEST_ELECMARGIN Verifies REQ-xxx: generation margin >= Threshold %.
tests = functiontests(localfunctions);
end

function test_GenerationMargin(testCase)
[minMargin, req] = shipmbse.reqValue(mfilename, "Threshold", Units="%");
r = electricalTesting(minMargin);
testCase.verifyGreaterThanOrEqual(r.MarginPct, minMargin, ...
    sprintf("%s not met: margin %.1f%% < %.1f%%.", req.Id, r.MarginPct, minMargin));
end
```

2. Put the threshold on the requirement (`Threshold`, `Units`, `VerificationMethod`), not in the test.
3. Link the test to the requirement: in the MATLAB Editor, select the test function, then in the Requirements Editor right-click the requirement and choose **Link to Selection in MATLAB Editor**. Set the link type to **Verify**. Keep one requirement per test file.
4. If you later edit a linked test outside the MATLAB Editor, run `updateTestLinkRanges` so the link stays on the test function.
5. Run `buildtool verify trace`.

Code tests for the scripts themselves go in `scripts/tests/unit/`. New `shipmbse` functions need tests against the MiniShip fixture (`buildMiniShip`), whose expected values are worked out by hand.

## **9\. Recommendations for Future Work**

To transition the SYSTEM model from a baseline architectural layout into a fully integrated digital twin, subsequent development cycles should focus on the following structural, verification, and governance upgrades across the MBSE framework:

### **9.1 Enhancing Requirement Governance via Custom Attribute Registries**

Custom attribute registries in Simulink Requirements (.slreqx) should be systematically expanded to capture enriched governance and management metadata directly within requirement sets. Recommended attribute extensions include:

* **Requirement Owner (RequirementOwner):** String field storing the engineering discipline lead or IPT (Integrated Product Team) point of contact responsible for maintaining and verifying compliance.  
* **Safety & Operational Criticality (SafetyCriticality):** Enumeration registry (e.g., High, Medium, Low, Safety-Critical) to support class society audits (ABS/DNV) and System Safety Hazard Analyses (SSHA).  
* **Verification Level (VerificationLevel):** Enumeration identifying the system breakdown layer where compliance is formally proven (e.g., Component, Subsystem, Integrated System, Sea Acceptance Trials).  
* **Verification Method (VerificationMethod):** Categorization specifying whether fulfillment is verified by Analysis, Demonstration, Test, or Inspection.  
* **Target Milestone (TargetMilestone):** Project design gate tracking requirement maturity (e.g., SRR, PDR, CDR).

### **9.2 Expanding Automated Verification Tests Across Ship Subsystems**

As the System Composer architecture model expands beyond initial auxiliary layouts, the MATLAB unit test framework in /scripts/tests/ must be scaled proportionally. Following the pattern established by test\_fuel.m, test\_ExistComp.m, and test\_Req\_FuelEndurance\_01.m, dedicated test suites should be authored for additional major ship systems.

### **9.3 Automated Continuous Integration & Coverage Auditing**

Integrate verifyRequirementAllocations.m into automated continuous integration (CI/CD) or pre-commit hooks within MATLAB Projects.  Automatically executing bi-directional allocation audits ensures that unallocated requirements or orphan components are caught before merging architecture modifications into the main repository branch.

### **9.4 Native Interface Utilization & Port Dictionary Integration**

Reconfigure component creation utilities so that System Composer ports are natively instantiated with explicit Physical or Signal types at creation time. This will transition the model away from relying on trailing port name suffixes (e.g., \_P and \_S) and enforce strict physical domain consistency via InterfaceDictionary.sldd.

### **9.5 Spatial Arrangements, Compartment Breakdown & 3D Hydrostatics**

Incorporate spatial attributes—including compartment identifiers, deck levels, frame numbers, and 3D bounding boxes (X, Y, Z coordinates)—into component stereotypes. This enables automated spatial arrangement checks, localized weight distribution analysis, and direct coupling with hydrostatic stability solvers.

### **9.6 Dynamic Behavior & Multi-Domain Physical Simulation**

Extend architecture components by linking System Composer blocks to underlying Simulink behavioral models and Simscape physical network models. This bridges high-level architectural trade studies with dynamic, time-domain physical system simulations for transient analysis and power hardware-in-the-loop (PHIL) testing.

## **Developer Tips & Onboarding Guide**

### **Developer Tips**

* Always launch the project through ship-mbse.prj rather than opening models directly.  
* Ensure necessary project path files are implemented.  
* Keep InterfaceDictionary.sldd synchronized with any interface changes.  
* Reuse existing stereotypes whenever possible instead of creating duplicates.  
* Maintain SWBS numbering when introducing new components.  
* Commit incremental architectural changes frequently.  
* Run verification scripts after any significant architecture modification.  
* Validate interfaces before creating behavioral models.  
* Committing unnecessary changes to the system model can easily cause merge conflicts with peers. It is best to only commit model changes if there are critical architectural changes.

### **Recommended Onboarding Sequence**

1. Read Sections 2–5 to understand the overall architecture.  
2. Open SYSTEM.slx and explore the SWBS hierarchy.  
3. Review the interfaces (Section 3). *(Note: interfaces have no elements yet and the Interface Dictionary is not attached; see the status note.)*  
4. Examine the stereotype profiles in the Excel property sheets.  
5. Review helper functions in the scripts directory.  
6. Execute the automated verification scripts.  
7. Review existing requirement allocations.  
8. Begin development in the subsystem of interest.

### **Immediate Development Priorities**

* Complete metadata assignment across all existing components.  
* Expand requirement allocations throughout the architecture.  
* Add to existing subsystem components with fully developed subsystem architectures.  
* Integrate behavioral Simulink models with existing System Composer components.  
* Improve interface typing by migrating away from suffix-based identification where practical.