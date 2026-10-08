function [comps, paths] = activeComponents(model, opts)
%ACTIVECOMPONENTS Every component in the active configuration of the architecture.
%   comps = shipmbse.activeComponents() returns the active components of the
%   model named in shipmbse.config, as a column array of
%   systemcomposer.arch.Component, in depth-first order.
%
%   [comps, paths] = shipmbse.activeComponents(model) also returns each
%   component's full path ("SYSTEM/SHIP/...").
%
%   Rules (the single definition used by every report, analysis and test):
%     * Components at every level are returned, not only leaves. Property
%       data lives at several levels (e.g. "52X FUEL" holds the fuel system
%       weight, its children hold component data).
%     * A variant component is represented by its ACTIVE CHOICE. The variant
%       container itself is never returned, and inactive choices and their
%       contents are skipped.
%     * Referenced architecture models are followed (decision D3).
%
%   Name-value options:
%     LeavesOnly  (false) Return only components without child components.
%     Stereotype  ("")    Return only components with this stereotype
%                         ("Profile.Stereotype").
%
%   See also shipmbse.sumProperty, shipmbse.massProperties,
%   shipmbse.findStereotypeOverlaps.

arguments
    model (1,1) systemcomposer.arch.Model = shipmbse.loadModel()
    opts.LeavesOnly (1,1) logical = false
    opts.Stereotype (1,1) string = ""
end

comps = systemcomposer.arch.Component.empty(0, 1);
paths = strings(0, 1);
[comps, paths] = visit(model.Architecture, string(model.Name), comps, paths, opts);

end

function [comps, paths] = visit(arch, archPath, comps, paths, opts)
children = arch.Components;
for k = 1:numel(children)
    c = children(k);
    if isa(c, 'systemcomposer.arch.VariantComponent')
        c = c.getActiveChoice();
        if isempty(c)
            continue
        end
        % Choices live one level below the container in the path
        cPath = archPath + "/" + string(children(k).Name) + "/" + string(c.Name);
    else
        cPath = archPath + "/" + string(c.Name);
    end

    sub = c.Architecture;   % also the root architecture of a referenced model
    hasChildren = ~isempty(sub) && ~isempty(sub.Components);
    keep = ~(opts.LeavesOnly && hasChildren);
    if keep && opts.Stereotype ~= ""
        keep = any(string(c.getStereotypes()) == opts.Stereotype);
    end
    if keep
        comps(end+1, 1) = c; %#ok<AGROW>
        paths(end+1, 1) = cPath; %#ok<AGROW>
    end
    if hasChildren
        [comps, paths] = visit(sub, cPath, comps, paths, opts);
    end
end
end
