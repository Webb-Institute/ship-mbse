function stripProperties()

    import systemcomposer.query.*
    modelName = 'SYSTEM';
    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end

    % Creating Model Object and Creating an Array of All Components
    modelObj= systemcomposer.loadModel(modelName);
    compAll = findElementsOfType(modelObj, 'Component');

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