function rebuildProperties(opts)
%REBUILDPROPERTIES Strip all stereotypes and re-apply them from the Excel tables.
%   rebuildProperties() removes every component stereotype from the model
%   named in shipmbse.config (stripProperties), then applies the property
%   tables listed in shipmbse.config().Excel (applyProperties). Both tables
%   are validated before anything is stripped. This MODIFIES THE MODEL.
%
%   rebuildProperties(Save=true) also saves the model.
%
%   The tables cover different stereotypes and components, so the order in
%   which they are applied does not matter.
%
%   See also stripProperties, applyProperties.

arguments
    opts.Save (1,1) logical = false
end

cfg = shipmbse.config();
tables = string(struct2cell(cfg.Excel))';
for t = tables
    applyProperties(t, DryRun=true);   % fail before stripping if a table is invalid
end
stripProperties();
for t = tables
    applyProperties(t);
end
if opts.Save
    shipmbse.loadModel().save;
    disp("Model saved.");
end

end
