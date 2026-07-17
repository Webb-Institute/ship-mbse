# Plugin Guide

Explains the analysis plugin architecture used by `scripts/runAllReports.m` and
how to add a new plugin under `scripts/plugins/`.

## Existing plugins
- `applyProperties.mlx` — Takes the user-defined properties in the  Properties.xlsx File and imports the properties applying them to the model components
- `sumParam.mlx` — Sums values of the requested parameter on each component that has the parameter. Returns the sum and the amount of components with the parameter
- `sumProp.mlx` — Sums values of the requested property on each component that has ths property. Returns the sum and the amount of components with the property.
- `sumPropIfOn.mlx` — Sums the values of the requested property on each component that has the property only if the component is toggled ON (which is another property). Returns the sum anf the amount of components with the property that are turned on 


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
