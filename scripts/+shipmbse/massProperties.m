function [mp, details] = massProperties(opts)
%MASSPROPERTIES Weight and centre of gravity of the active configuration.
%   mp = shipmbse.massProperties() sums the WeightsCenters stereotype over
%   every active component (see shipmbse.activeComponents) and returns a
%   struct with fields:
%     Weight, LCG, VCG, TCG                      without margin
%     WeightWithMargin, LCGWithMargin, ...        with each component's
%                                                 WeightMargin (%) applied
%     WeightWithCenters                           weight whose LCG/VCG/TCG are
%                                                 all known (basis of the CoG)
%     NumComponents, Units
%
%   [mp, details] = shipmbse.massProperties(...) also returns one row per
%   component: Path, Weight, MarginPct, WeightWithMargin, LCG, VCG, TCG,
%   HasCenters.
%
%   Missing data (NaN values) is never dropped silently:
%     * NaN weight  -> component excluded from all totals (HasCenters false).
%     * NaN centre  -> weight counted, but excluded from the CoG moments.
%     * NaN margin  -> treated as 0 %.
%   CoG fields are NaN when no weight with known centres exists.
%
%   Name-value options:
%     Stereotype  Profile.Stereotype holding Weight/LCG/VCG/TCG/WeightMargin
%                 (default: shipmbse.config().Stereotypes.WeightsCenters)
%     Model       Model to read (default: shipmbse.loadModel()).
%
%   See also shipmbse.activeComponents, shipmbse.getProp.

arguments
    opts.Stereotype (1,1) string = shipmbse.config().Stereotypes.WeightsCenters
    opts.Model (1,1) systemcomposer.arch.Model = shipmbse.loadModel()
end

st = opts.Stereotype;
[comps, paths] = shipmbse.activeComponents(opts.Model, Stereotype=st);
n = numel(comps);
W = nan(n, 1); M = nan(n, 1); L = nan(n, 1); V = nan(n, 1); T = nan(n, 1);
for k = 1:n
    c = comps(k);
    W(k) = shipmbse.getProp(c, st + ".Weight");
    L(k) = shipmbse.getProp(c, st + ".LCG");
    V(k) = shipmbse.getProp(c, st + ".VCG");
    T(k) = shipmbse.getProp(c, st + ".TCG");
    if c.hasProperty(st + ".WeightMargin")
        M(k) = shipmbse.getProp(c, st + ".WeightMargin");
    end
end
M(isnan(M)) = 0;
WM = W .* (1 + M/100);
hasCenters = ~isnan(W) & ~isnan(L) & ~isnan(V) & ~isnan(T);

counted = ~isnan(W);
mp.Weight = sum(W(counted));
mp.WeightWithMargin = sum(WM(counted));
mp.WeightWithCenters = sum(W(hasCenters));
[mp.LCG, mp.VCG, mp.TCG] = centres(W, L, V, T, hasCenters);
[mp.LCGWithMargin, mp.VCGWithMargin, mp.TCGWithMargin] = centres(WM, L, V, T, hasCenters);
mp.NumComponents = n;
mp.Units = struct("Weight", "t", "Centres", "m", "Margin", "%");

details = table(paths, W, M, WM, L, V, T, hasCenters, 'VariableNames', ...
    {'Path', 'Weight', 'MarginPct', 'WeightWithMargin', 'LCG', 'VCG', 'TCG', 'HasCenters'});

end

function [lcg, vcg, tcg] = centres(w, l, v, t, use)
total = sum(w(use));
if total > 0
    lcg = sum(w(use) .* l(use)) / total;
    vcg = sum(w(use) .* v(use)) / total;
    tcg = sum(w(use) .* t(use)) / total;
else
    lcg = NaN; vcg = NaN; tcg = NaN;
end
end
