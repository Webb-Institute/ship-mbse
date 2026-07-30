% Calculating Ship CoG and Displacement with Margin
function [displacementWithMargin, LCG, VCG, TCG] = marginCalcShipDisp_CoG(stereotypeName, profileName)
import systemcomposer.query.*

modelName = 'SYSTEM';
if ~bdIsLoaded(modelName)
    open_system(modelName);
end


% Creating Model Object and Creating an Array of All Components
modelObj= systemcomposer.loadModel(modelName);
compAll = findElementsOfType(modelObj, 'Component');

displacementWithMargin = 0;
LCG = 0;
VCG = 0;
TCG = 0;

% Construct property paths
stereotypePath = [profileName, '.', stereotypeName];
weightPath     = [profileName, '.', stereotypeName, '.Weight'];
LCGPath        = [profileName, '.', stereotypeName, '.LCG'];
VCGPath        = [profileName, '.', stereotypeName, '.VCG'];
TCGPath        = [profileName, '.', stereotypeName, '.TCG'];
MarginPath        = [profileName, '.', stereotypeName, '.WeightMargin'];

for i =1:length(compAll)
    comp =compAll(i);
    stereotypes = string(comp.getStereotypes());

    % Calculate the center of gravity for each component if applicable
    if any(strcmp(stereotypes, string(stereotypePath)))

        weight = str2double(getProperty(comp, weightPath));
        long = str2double(getProperty(comp, LCGPath));
        vert = str2double(getProperty(comp, VCGPath));
        tran = str2double(getProperty(comp, TCGPath));
        margin =str2double(getProperty(comp, MarginPath));

        % Skip components with missing/invalid numbers
        if isnan(weight) || isnan(long) || isnan(vert) || isnan(tran) || isnan(margin)
            continue;
        end

        % Update the overall center of gravity
        LCG = LCG + weight * long * (1 + margin/100);
        VCG = VCG + weight * vert * (1 + margin/100);
        TCG = TCG + weight * tran * (1 + margin/100);
        displacementWithMargin = displacementWithMargin + weight * (1 + margin/100); 
    end
end

% Find the center of gravity by total displacement
LCG = LCG / displacementWithMargin;
VCG = VCG / displacementWithMargin;
TCG = TCG / displacementWithMargin;
end