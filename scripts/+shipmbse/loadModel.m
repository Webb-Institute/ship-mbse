function model = loadModel(modelName)
%LOADMODEL Load the ship architecture model without opening an editor window.
%   model = shipmbse.loadModel() loads the model named in shipmbse.config.
%   model = shipmbse.loadModel(modelName) loads the named model.
%
%   Returns a systemcomposer.arch.Model. If the model is already loaded, the
%   loaded copy is returned (including any unsaved changes).
%
%   See also shipmbse.config, systemcomposer.loadModel.

arguments
    modelName (1,1) string = shipmbse.config().ModelName
end

model = systemcomposer.loadModel(modelName);

end
