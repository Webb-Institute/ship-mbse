function [records, summary] = dataMaturity(model)
%DATAMATURITY Maturity and source of the data on each active component.
%   records = shipmbse.dataMaturity() returns one row per active component
%   that carries property data (any stereotype other than DataRecord):
%     Path, Maturity, DataSource
%   Maturity is "<none>" when the component has data but no DataRecord.
%
%   [records, summary] also returns a one-line text summary, e.g.
%   "Data maturity: 44 Placeholder", for report headers.
%
%   See also shipmbse.config (MaturityLevels), applyProperties.

arguments
    model (1,1) systemcomposer.arch.Model = shipmbse.loadModel()
end

cfg = shipmbse.config();
rec = cfg.Stereotypes.DataRecord;
[comps, paths] = shipmbse.activeComponents(model);
keep = false(numel(comps), 1);
maturity = strings(numel(comps), 1);
source = strings(numel(comps), 1);
for k = 1:numel(comps)
    st = string(comps(k).getStereotypes());
    keep(k) = ~isempty(setdiff(st, rec));
    if ~keep(k)
        continue
    end
    if ismember(rec, st)
        maturity(k) = shipmbse.getProp(comps(k), rec + ".Maturity");
        source(k) = shipmbse.getProp(comps(k), rec + ".DataSource");
    else
        maturity(k) = "<none>";
    end
end
records = table(paths(keep), maturity(keep), source(keep), 'VariableNames', {'Path', 'Maturity', 'DataSource'});

levels = [cfg.MaturityLevels, "<none>"];
parts = strings(0);
for lv = levels
    n = sum(records.Maturity == lv);
    if n > 0
        parts(end+1) = n + " " + lv; %#ok<AGROW>
    end
end
summary = "Data maturity: " + strjoin(parts, ", ");
if all(records.Maturity == "Placeholder")
    summary = summary + "  ** ALL VALUES ARE PLACEHOLDERS: not for design decisions **";
end

end
