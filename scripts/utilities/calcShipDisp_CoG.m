function [displacement, LCG, VCG, TCG] = calcShipDisp_CoG(stereotypeName, profileName)
%CALCSHIPDISP_COG Ship weight and centre of gravity without margin.
%   [displacement, LCG, VCG, TCG] = calcShipDisp_CoG(stereotype, profile)
%   sums Weight and weight moments of Profile.Stereotype over the active
%   configuration. Weight in t; LCG, VCG, TCG in m. CoG values are NaN if
%   no weight with known centres exists.
%
%   Wrapper around shipmbse.massProperties.
%
%   See also marginCalcShipDisp_CoG, shipmbse.massProperties.

arguments
    stereotypeName (1,1) string
    profileName (1,1) string
end

mp = shipmbse.massProperties(Stereotype=profileName + "." + stereotypeName);
displacement = mp.Weight;
LCG = mp.LCG;
VCG = mp.VCG;
TCG = mp.TCG;

end
