function verifyServiceBalance(testCase, demandProperty, capacityProperty, label)
%VERIFYSERVICEBALANCE Shared check: capacity that is on covers demand that is on.
%   verifyServiceBalance(testCase, demandProperty, capacityProperty, label)
%   sums demandProperty and capacityProperty ("Profile.Stereotype.Property")
%   over active components whose Status is on, and verifies capacity >=
%   demand. The test FAILS (rather than passing vacuously) if no demand
%   component is on, or if the two properties have different units.
%
%   See also shipmbse.sumProperty, shipmbse.serviceBalance.

arguments
    testCase (1,1) matlab.unittest.TestCase
    demandProperty (1,1) string
    capacityProperty (1,1) string
    label (1,1) string
end

model = shipmbse.loadModel();
[demand, dDet] = shipmbse.sumProperty(demandProperty, OnlyIfOn=true, Model=model);
[capacity, cDet] = shipmbse.sumProperty(capacityProperty, OnlyIfOn=true, Model=model);
dUnit = shipmbse.propertyInfo(demandProperty, model).Units;
cUnit = shipmbse.propertyInfo(capacityProperty, model).Units;

testCase.assertGreaterThan(sum(dDet.Included), 0, sprintf( ...
    "%s: no active component with %s is on, so there is nothing to verify.", label, demandProperty));
testCase.assertEqual(cUnit, dUnit, sprintf( ...
    "%s: demand unit ""%s"" and capacity unit ""%s"" differ.", label, dUnit, cUnit));
testCase.verifyGreaterThanOrEqual(capacity, demand, sprintf( ...
    "%s shortfall: capacity %g %s from %d component(s) is less than demand %g %s from %d component(s).", ...
    label, capacity, cUnit, sum(cDet.Included), demand, dUnit, sum(dDet.Included)));

end
