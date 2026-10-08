function stripProperties()
%STRIPPROPERTIES Remove every stereotype from every component of the model.
%   stripProperties() removes all applied stereotypes (and so all property
%   values) from every component of the model named in shipmbse.config,
%   including variant containers and inactive choices. Port stereotypes are
%   not touched. This MODIFIES THE MODEL; it does not save.
%
%   See also rebuildProperties, applyProperties.

    compAll = shipmbse.allComponents();

    % Strips all Stereotypes from each component to reset
    for a = 1:length(compAll)
        compToStrip = compAll(a);
        appliedStereotypes = compToStrip.getStereotypes();
        if ~isempty(appliedStereotypes)
            for s = 1:length(appliedStereotypes)
                stripStereotype = char(appliedStereotypes(s));
                compToStrip.removeStereotype(stripStereotype);
            end
        end
    end
end