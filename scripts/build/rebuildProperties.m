function rebuildProperties()
%REBUILDPROPERTIES Strip all stereotype properties and re-apply them from Excel.
%   rebuildProperties() removes stereotype property values from the SYSTEM
%   model with stripProperties, then re-applies FuelProp.xlsx followed by
%   Properties.xlsx with applyProperties. This modifies the model.
%
%   Application order matters: values from Properties.xlsx overwrite any
%   overlapping values from FuelProp.xlsx.
%
%   See also stripProperties, applyProperties.

stripProperties();
applyProperties('FuelProp.xlsx');
applyProperties('Properties.xlsx');

end
