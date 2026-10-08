function comps = allComponents(model)
%ALLCOMPONENTS Every component in the model, for model-editing utilities.
%   comps = shipmbse.allComponents() returns every component of the model
%   named in shipmbse.config: all hierarchy levels, variant containers, and
%   every variant choice, active or not.
%
%   Use this only in utilities that edit the model (applying or stripping
%   stereotypes, assigning interfaces), where every element must be
%   reached. Never use it for totals or analysis: it includes inactive
%   choices and variant containers, which double-count. Analyses use
%   shipmbse.activeComponents.
%
%   See also shipmbse.activeComponents.

arguments
    model (1,1) systemcomposer.arch.Model = shipmbse.loadModel()
end

paths = find(model, systemcomposer.query.AnyComponent, 'Recurse', true, 'IncludeReferenceModels', true);
found = cell(numel(paths), 1);
for k = 1:numel(paths)
    found{k} = lookup(model, 'Path', paths{k});
end
comps = [found{:}]';   % heterogeneous array of components and variant components

end
