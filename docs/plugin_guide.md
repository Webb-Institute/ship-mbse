# Plugin Guide

Explains the analysis plugin architecture used by `scripts/runAllReports.m` and
how to add a new plugin under `scripts/plugins/`.

## Existing plugins
- `applyProperties.mlx` — Takes the user-defined properties in the  Properties.xlsx File and imports the properties applying them to the model components
- `sumParam.mlx` — Sums values of the requested parameter on each component that has the parameter. Returns the sum and the amount of components with the parameter
- `sumProp.mlx` — Sums values of the requested property on each component that has ths property. Returns the sum and the amount of components with the property.
- `sumPropIfOn.mlx` — Sums the values of the requested property on each component that has the property only if the component is toggled ON (which is another property). Returns the sum anf the amount of components with the property that are turned on 
- `applyPortProp.mlx` — Applies user defined properties to all of the ports in the model. It also determines the interface they belong to based on the naming convention applied to all of the ports. 
- `calcShipDisp_CoG.mlx` — Calculates the ship's displacement based on the weight property, and calculates the center of gravity of the ship from aft perpendicular, baseline, and centerline
- `electricalTesting.mlx` — Calculates the power required and the power generates and compares the value to a user defined margin. Also checks to see if the power generation is oversized 
- `generateInterfaceReport.mlx` — Generates an excel file that includes the Start Component and End Component for the interface, as well as the interface type and criticality/redundancy score  

- `findUnallocatedRequirements.mlx` — ADD DEFINITION ONCE FINISHED
- `requirementsCoveragePlugin.m` — TODO description
- `interfaceInventoryPlugin.m` — TODO description
- `dependencyMatrixPlugin.m` — TODO description
- `criticalityPlugin.m` — TODO description
- `powerEnergyPlugin.m` — TODO description
- `weightMarginPlugin.m` — TODO description
- `reliabilityFMEAPlugin.m` — TODO description
- `tradeStudyPlugin.m` — TODO description
- `changeImpactPlugin.m` — TODO description

## Plugin interface

TODO: document the expected function signature, inputs, and outputs shared by
all plugins so they can be invoked uniformly by `runAllReports.m`.

## Adding a new plugin

TODO: step-by-step instructions.
