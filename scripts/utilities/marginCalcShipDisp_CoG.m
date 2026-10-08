function [displacementWithMargin, LCG, VCG, TCG] = marginCalcShipDisp_CoG(stereotypeName, profileName)
%MARGINCALCSHIPDISP_COG Ship weight and centre of gravity with weight margins.
%   [displacementWithMargin, LCG, VCG, TCG] = marginCalcShipDisp_CoG(stereotype, profile)
%   applies each component's WeightMargin (%) to its weight, then sums
%   weight and moments over the active configuration. Weight in t; centres
%   in m.
%
%   Wrapper around shipmbse.massProperties.
%
%   See also calcShipDisp_CoG, shipmbse.massProperties.

arguments
    stereotypeName (1,1) string
    profileName (1,1) string
end

mp = shipmbse.massProperties(Stereotype=profileName + "." + stereotypeName);
displacementWithMargin = mp.WeightWithMargin;
LCG = mp.LCGWithMargin;
VCG = mp.VCGWithMargin;
TCG = mp.TCGWithMargin;

end
