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

The ship-mbse architecture framework operates within MATLAB R2026a using System Composer, Simulink Projects, and MATLAB Data Dictionaries. All team members must adhere to the standard directory layout and path initialization workflow to ensure reproducible builds and model validation.

### **1.1 Workspace Directory Structure**

The project root directory is organized into standardized modular folders:

* /model/: Core System Composer models, profile definition files (/model/profiles/), requirement sets (/model/requirements/), and exported views.  
* /scripts/: MATLAB automation utilities (/scripts/utilities/), requirement verification test suites (/scripts/tests/), plug-ins, and helper functions. Main entry-point scripts include setupProjectPaths.m, runAllReports.m, and verifyRequirementAllocations.m.  
* /data/: Input Excel configurations (/data/input\_tables/Properties.xlsx and FuelProp.xlsx), trade study parameters, and saved analysis results.  
* /outputs/: Generated text reports (SystemsReport.txt, FuelValidationReport.txt, UnallocatedReq.txt), figures, and comparative table exports.  
* InterfaceDictionary.sldd: Shared data dictionary defining system interfaces and data types.

### 

### **1.2 Project Initialization Workflow**

1. Open MATLAB R2026a and set the current working folder to the repository root.  
2. Double-click ship-mbse.prj to launch the MATLAB Project environment.  
3. Execute setupProjectPaths.m in the Command Window to automatically load all required subdirectories and bind InterfaceDictionary.sldd to the active workspace.

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

## **4\. Key Architectural Design Rules Refinement**

* **Strict Bus Domain Typing:** All signal connections between subsystems must bind to their specific \_S connection bus type (e.g., Bus: LubeOil\_S, Bus: Control\_S), ensuring strong type-checking at system boundaries.  
* **Physical / Signal Separation:** Fluid flow, mechanical load, and thermal transfer are strictly handled via \_P physical bus ports, while monitoring, commands, and telemetry are handled via \_S standard Simulink composite bus ports.  
* **Variant Management:** Component 20X utilizes variant controls (VariantControl \= "20X DIESEL ENGINE" vs "20X ABSENT"). When absent, all physical and signal boundaries default to inactive stubs without breaking model hierarchy connections.

## 

## 

## 

## **5\. Stereotype & Profile Data Dictionary**

Metadata assignment is split into high-level system profiles (Properties.xlsx) and detailed component profiles (FuelProp.xlsx).

### **5.1 Global System Profiles (Properties.xlsx)**

| Profile Name | Stereotype Name | Properties & Units |
| :---: | :---: | :---: |
| WeightsCentersProfile | WeightsCenters | Weight (t), LCG (m), VCG (m), TCG (m), WeightMargin (%) |
| ElectricalProfile | ElectricalConsumer, ElectricalGenerator | PowerRequired (kW), PowerGenerated (kW), Status (On/Off) |
| FuelProfile | FuelConsumer, FuelProducer | FuelRequired (kL/s), FuelProduced (kL/s), FuelStored (kL), FuelType (string) |
| CoolingProfile | CoolConsumer, CoolProducer | CoolConsumed (kL/s), CoolProduced (kW), Status (On/Off) |
| LubeProfile | LubeConsumer, LubeProducer | LubeRequired (kL/s), LubeProduced (kL/s), Status (On/Off) |
| CompAirProfile | AirConsumer, AirProducer | AirConsumed (kL/s), AirProduced (kL/s), Status (On/Off) |
| WasteProfile | WasteGasProducer / Receiver WasteOilProducer / Receiver WasteWaterProducer / Receiver WasteSolidProducer / Receiver   | WGProduced (kL/s), WSProduced (kL/s), WWProduced (kL/s), WOProduced (kL/s), WGReceived (kL/s) |
| HeatProfile | HeatConsumer ,  HeatProducer | HeatConsumed (kW), HeatProduced (kW), Status (On/Off) |

### **5.2 Subsystem Detailed Profiles (FuelProp.xlsx)**

| Stereotype | Key Stereotype Properties |
| :---: | :---: |
| Tank | PrimaryFluidCapacity, SecondaryFluidCapacity, TertiaryFluidCapacity (kL); PriFluid, SecFluid, TerFluid (string) |
| Pump | PowerRequired (kW), MaxFlowCapacity (kL/s), Pri/Sec/TerFlowRate (kL/s), Lube/CoolConsumption |
| Pipe | Diameter (m), Length (m), FlowRate (kL/s), FluidDensity (kg/kL), Fluid (string) |
| FluidConditioner | HeatConsumed (kW), WasteOilProduced (kL/s), Pri/Sec/TerFlowRate (kL/s) |

## **6\. Custom Helper Functions,  Utilities & Reports**

This utility suite automates naval architecture calculations (displacement and Center of Gravity) and aggregates stereotype properties and parameters across the SYSTEM model composer architecture.

### **6.1 Mass Properties & Hydrostatics**

#### **calcShipDisp\_CoG**

* **Syntax:** \[displacement, LCG, VCG, TCG\] \= calcShipDisp\_CoG(stereotypeName, profileName)  
* **Description:** Calculates total ship displacement (weight) and Center of Gravity coordinates (LCG, VCG, TCG) by traversing active components in the architecture.  
* **Inputs:** stereotypeName (string | char): Name of the stereotype defining mass properties; profileName (string | char): Profile containing the target stereotype.  
* **Outputs:** displacement (double): Total weight accumulated from matching active components; LCG, VCG, TCG (double): Longitudinal, Vertical, and Transverse Center of Gravity.  
* **Key Details:** Uses a recursive nested function (getActiveComponentsRecursive) to bypass inactive variant selections and evaluate active variant choices. Evaluates property paths formatted as Profile.Stereotype.Weight, LCG, VCG, and TCG.

#### **marginCalcShipDisp\_CoG**

* **Syntax:** \[displacementWithMargin, LCG, VCG, TCG\] \= marginCalcShipDisp\_CoG(stereotypeName, profileName)  
* **Description:** Calculates displacement and Center of Gravity coordinates while applying design weight margins to each individual component.  
* **Key Details:** Reads the WeightMargin property and factors it into component weight: Weight\_factored \= Weight \* (1 \+ Margin / 100\). Uses findElementsOfType(modelObj, 'Component') to search components across the model.

### **6.2 Property & Parameter Aggregation Utilities**

#### **sumParam**

* **Syntax:** \[ParamValueSum, numCompFound\] \= sumParam(targetParamName)  
* **Description:** Finds and sums a specific numerical parameter across all model components. Automatically parses character/string parameter values by splitting text on spaces to strip unit suffixes.

#### **sumProp**

* **Syntax:** \[PropValueSum, numCompFound\] \= sumProp(targetPropName, targetStereotypeName, targetProfileName)  
* **Description:** Sums a specific stereotype property across active architecture components using recursive hierarchy traversal. For VariantComponent blocks, it bypasses inactive containers and evaluates getActiveChoice().

#### **sumPropIfOn**

* **Syntax:** \[PropValueSumON, numCompFoundON\] \= sumPropIfOn(targetPropName, targetStereotypeName, targetProfileName)  
* **Description:** Sums a stereotype property value across active components, strictly filtering for components whose Status property evaluates to true/ON.

### **6.3 Automation Scripts**

* applyProperties(excelFileName): Reads component property definitions and stereotypes from a specified Excel spreadsheet and applies them across model components, variant containers, and variant choices.  
* applyPortProp(): Automatically attaches PortProfile, traverses all architecture levels, resolves port interfaces based on naming conventions, assigns stereotypes/properties, creates missing Interface Dictionary entries, and synchronizes connected port endpoints.

### 

### **6.4 Report Scripts**

#### **fuelAnalysis**

* **Syntax:** fuelAnalysis()  
* **Description:** Automates fuel property propagation, checks local physical connection compatibility, and performs hierarchical property rollups for vessel fuel systems. Aggregates child metrics (e.g., Power, Weight, Flow Rate, Center of Gravity) onto parent container properties using operations such as `SUM` and `COG`.Evaluates physical links at the `52X (FUEL)` architectural level to verify active status, matching fluid profiles, and standard target properties.  
* **Outputs:** FuelValidationReport.txt and FuelSystemSummary.txt.

#### **generateInterfaceReport()**

* **Syntax:** reportTable \= generateInterfaceReport()  
* **Description:** Traverses architecture boundary connectors and variant structures to map end-to-end leaf component connections and extract interface metrics.  
* **Boundary & Variant Tracing:** Deep-scans through architecture ports and active variant choices to identify true leaf source and target components.  
* **Metadata Extraction:** Cleans interface specifications (stripping `_S`/`_P` suffixes) and queries criticality/redundancy scores using dynamic stereotype lookups.  
* **Data Deduplication:** Eliminates duplicate paths, formats, and sorts connection records by interface number and component name.  
* **Outputs:** Interfaces.txt

#### **systemsReport()**

* **Syntax:** systemsReport()  
* **Description:** Generates multi-domain balance and usage reports across primary vessel engineering systems.  
* **Domain Analysis:** Computes consumer and producer totals for Electrical, Fuel, Lube Oil, Freshwater Cooling, Compressed Air, and Waste profiles.  
* **Variant Filtering:** Filters out inactive variants prior to totaling domain values.  
* **Multi-Stream Processing:** Uses a specialized layout to evaluate multi-stream waste systems (Gas, Oil, Water, Solid).  
* **Run Management:** Supports automatic report run indexing (e.g., `Run_001`) and clearing prior reports via a `'clear'` command argument.  
* **Outputs:**Auto-incremented text reports formatted as  Reports/SystemsReport\_Run\_XXX.txt

#### **GenerateWeightTableReport()**

* **Syntax:** weightTable \= GenerateWeightTableReport(cmd)  
* **Description:** Extracts weight distributions, design margins, and 3D spatial Center of Gravity (CoG) coordinates to summarize vessel displacement.  
* **Component Weight Extraction:** Retrieves base weights, percentage margins, total margins, and 3D CoG coordinates (LCG, TCG, VCG) for active components.  
* **Global Hydrostatics Summary:** Calculates total vessel displacement and global Center of Gravity coordinates, providing figures both with and without design margins.  
* **Report Indexing:** Automatically manages output file numbering and supports directory clearing.  
* **Outputs:**Auto-incremented text reports formatted as  Reports/WeightsAndMarginsReport\_Run\_XXX.txt

#### **verifyRequirementAllocations()**

* **Syntax:** verifyRequirementAllocations()  
* **Description:** Performs bi-directional allocation verification between a Simulink Requirements set and a System Composer model to identify unallocated requirements and components.  
* **Requirements Coverage Analysis:** Traverses requirement trees in ShipRequirements to confirm links to system components and sorts unallocated requirements numerically by ID.  
* **Component Coverage Analysis:** Recursively fetches model components across all hierarchy levels, verifying allocation links while resolving parent variant component inheritance.  
* **Dual Output Logging:** Prints structured coverage metrics and list summaries simultaneously to the MATLAB Command Window and an output text file.  
* **Outputs:**Auto-incremented text reports formatted as  UnallocatedReq.txt

#### **runAllReports()**

* **Syntax:** runAllReports()  
* **Description:**  Functions as the master orchestrator script that initializes the project environment and sequentially executes all analysis tools.  
* **Environment Initialization:** Configures workspace paths, adds the `/plugins` directory, and loads the target System Composer model.  
* **Sequential Batch Execution:** Automates execution of 5 primary analyses in order: systemsReport, verifyRequirementAllocations, fuelAnalysis, generateInterfaceReport, and GenerateWeightTableReport.  
* **Fault-Tolerant Processing:** Wraps each individual report call in a `try-catch` block to prevent individual script errors from halting the entire batch suite.  
* **Outputs:** Execution progress logs and artifacts produced by each sub-report script.

#### **changeImpactReport**

* **Syntax:** changeImpactReport(optArg)  
* **Description:** Serves as an interactive script for assessing, visualizing, and documenting the impact of proposed architectural changes across system components.  
* **Interactive Live Analysis:** Combines executable MATLAB code, embedded visual outputs, and dynamic rich-text formatting into a single Live Script interface.  
* **Dependency & Change Impact Tracing:** Evaluates modifications to model elements to determine downstream effects on connected components, interfaces, and system parameters.  
* **Outputs:** Comparative report and graphs, optionally clears the report memory upon completion.

## **7\. Adding Components, Ports, Connections & Metadata Assignment**

Building and expanding the SYSTEM model involves defining component blocks, establishing ports and connectors across standard components and variant architecture choices, and assigning metadata.

### **7.1 Component Excel Sheet Structure & Mapping Rules**

The metadata assignment script reads component properties using a standardized 4-row header layout:

| Row Range | Content Description | Template Examples |
| :---: | :---: | :---: |
| **Row 1** | Profile Names | WeightsCentersProfile, ElectricalProfile, FuelProfile |
| **Row 2** | Stereotype Names | WeightsCenters, ElectricalConsumer, FuelConsumer |
| **Row 3** | Property Names | Weight, LCG, VCG, TCG, WeightMargin, PowerRequired, Status |
| **Row 4** | Units / Description Header | (t), (m), %, (kW), On/Off, kL/s |
| **Row 5+** | Component Names & Values | Component or variant Name in Column A; property values across active columns, N/A if property is not applied |

### 

### **7.2 Automated Port Interface Assignment**

The automated script applyPortProp() parses port names using a standardized multi-part identifier structure:

\[Start Component\]-\[Terminal Component\]\[System Designation\]\[Suffix\]

**Domain Suffix Rules (\_P vs \_S):** Appending \_P marks the port as a Physical Port (e.g., CoolingFW\_P). Appending \_S forces the port to be treated as a Data/Signal Port (e.g., Control\_S).

**Standard Development Workflow**

1. Create the System Composer component.  
2. Add appropriate component stereotypes and properties to the Excel properties sheet.  
3. Populate component properties using the Excel property sheets.  
4. Execute applyProperties().  
5. Allocate requirements using Simulink Requirements.  
6. Develop or update MATLAB verification tests.  
7. Execute verifyRequirementAllocations().  
8. Execute all regression tests before committing changes.

## **8\. Requirements Management, Verification Testing & Custom Registries**

The ship-mbse framework utilizes Simulink Requirements (.slreqx) integrated with System Composer architecture models to enforce bi-directional traceability, custom metadata tracking, and automated model testing.

### **8.1 Bi-Directional Requirement Allocation Verification**

To ensure structural completeness across the architecture, the framework includes an automated bi-directional allocation verification utility: verifyRequirementAllocations.m.

#### **Function Overview & Execution**

Executing verifyRequirementAllocations() performs a two-way coverage check between the requirement set (ShipRequirements.slreqx) and the System Composer architecture model (SYSTEM.slx):

* **Part 1 (Requirements → Components Allocation Check):** Recursively traverses all requirements in ShipRequirements.slreqx, evaluating incoming and outgoing links. Identifies any requirement that is not allocated to at least one architecture component.  
* **Part 2 (Components → Requirements Allocation Check):** Traverses the complete model hierarchy using getAllComponents(). Reads component qualified paths, evaluates links, and flags any architectural component that is not allocated to at least one requirement.  
* **Report Generation:** Displays an executive summary in the Command Window and writes a detailed audit report to /outputs/UnallocatedReq.txt.

% Run bi-directional allocation verification check

verifyRequirementAllocations();

### **8.2 Requirement Verification Test Suite (/scripts/tests/)**

Verification tests are automated MATLAB unit test scripts located in the /scripts/tests/ directory. These scripts evaluate model properties, parameters, and dynamic capabilities against system requirements, asserting pass/fail conditions.

### **Analysis of Standard Framework Tests**

| Test Script | Target Subsystem | Verification Logic & Operational Assessment |
| :---: | :---: | :---: |
| test\_fuel.m | **52X Fuel Oil** | Aggregates total active fuel demand (FuelRequired) and active fuel generation capacity (FuelProduced) across all energized components |
| test\_ExistComp.m | **Any Component** | Checks if a component needed to fulfill a requirement exists or is the selected variant choice |
| test\_Req\_FuelEndurance\_01.m | **521 Fuel Storage / Endurance** | Uses getLinkedPerfVal to dynamically extract the required operational endurance threshold (PerfVal1) from its linked requirement. Computes actual vessel endurance via and verifies that actual endurance meets or exceeds the threshold. |

### **8.3 Custom Attribute Registries & Dynamic Variable Passing**

Custom attribute registries in Simulink Requirements allow engineers to define custom metadata fields on requirement objects (or requirement link objects). In the ship-mbse framework, custom attributes such as PerfVal1, PerfVal2, or ThresholdValue are used to store quantitative design criteria directly inside the requirement set.

#### **Setting Variables for Verification Tests via Attributes**

Instead of hardcoding threshold values (e.g., specifying 14 days endurance) inside MATLAB test scripts, threshold variables are defined as custom attributes within the requirement registry. Test scripts query these attributes dynamically at runtime. This decouples verification logic from specific numerical requirements.

#### **Custom Attribute Extraction Script: getLinkedPerfVal.m**

The helper function getLinkedPerfVal.m extracts attribute values from requirements or links connected to a specific test script:

* **Inputs:** testFileName (name of calling test script) and attrName (target attribute, e.g., 'PerfVal1').  
* **Requirement Auto-Loading:** Automatically scans the working folder and loads all available requirement sets (.slreqx) and link sets (.slmx) into memory.  
* **Link Traversal:** Queries slreq.inLinks and slreq.outLinks to locate links connected to the calling test script.  
* **Attribute Resolution:** Inspects the custom attributes on the link object. If unassigned, it falls back to inspecting the connected source or destination requirement object.  
* **Type Parsing:** Safe-parses numeric, logical, or string values (using regular expressions to strip non-numeric characters) and returns double-precision perfVal.

% Extract threshold value inside a test script

perfValThreshold \= getLinkedPerfVal(mfilename, 'PerfVal1');

### 

### 

### **8.4 Authoring Tests & Requirement Linking Workflow**

#### **1\. Authoring New Test Scripts**

New verification tests must follow the MATLAB Function-Based Unit Test structure:

function tests \= test\_Req\_NewFeature

    tests \= functiontests(localfunctions);

end

function test\_FeaturePerformanceCriteria(testCase)

    % 1\. Dynamically read required threshold from linked requirement

    requiredThreshold \= getLinkedPerfVal(mfilename, 'PerfVal1');

    testCase.assertFalse(isnan(requiredThreshold), 'PerfVal1 attribute missing from requirement link.');

    

    % 2\. Query model state

    actualValue \= sumPropIfOn('PowerRequired', 'ElectricalConsumer', 'ElectricalProfile');

    

    % 3\. Verify requirement condition

    testCase.verifyLessThanOrEqual(actualValue, requiredThreshold, ...

   sprintf('Requirement FAILED: Power draw (%.2f kW) exceeds limit (%.2f kW).', actualValue, requiredThreshold));

end

#### **2\. Linking Test Scripts to Requirements**

To establish traceability between a test script and a requirement in Simulink Requirements:

1. Open the test script file (e.g., test\_Req\_FuelEndurance\_01.m) in the MATLAB Editor.  
2. Highlight the entire script text inside the Editor window (or select the main test function).  
3. Open the Requirements Editor (or Requirements Perspective overlay in System Composer).  
4. Select the target requirement in the tree view.  
5. Right-click the requirement or click **Add Link** → select **Link to Selection in Editor**.

**Granular Testing Best Practice (1-to-1 Test-to-Requirement Mapping)**

If the same underlying test logic (e.g., evaluating fuel endurance or electrical load) applies to multiple requirements with differing custom attribute thresholds, create separate test scripts for each requirement (e.g., test\_Req\_FuelEndurance\_01.m, test\_Req\_FuelEndurance\_02.m). Linking each test script exclusively to a single requirement ensures that test results immediately isolate which specific requirement and custom attribute threshold caused a test failure, eliminating ambiguity during model audits.

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
3. Review the Interface Dictionary. *(Note: This section has not been fully developed or implemented)*  
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