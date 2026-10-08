function tests = test_Req_FuelEndurance_02
%TEST_REQ_FUELENDURANCE_02 Verifies REQ-403 Reserve Fuel Quantity.
%   Usable fuel must cover the intended operational period (REQ-402
%   Threshold, days) plus a reserve of the linked requirement's Threshold
%   (REQ-403, percent of that period).
tests = functiontests(localfunctions);
end

function test_RequirementPassCriteria(testCase)
[reservePct, req] = shipmbse.reqValue(mfilename, "Threshold", Units="%");
operationalDays = shipmbse.reqValue("REQ-402", "Threshold", Units="day");
requiredDays = operationalDays * (1 + reservePct/100);
actualDays = getFuelSystemEndurance();
testCase.verifyGreaterThanOrEqual(actualDays, requiredDays, sprintf( ...
    "%s not met: fuel endurance %.2f days does not cover %.2f days plus %.1f%% reserve (%.2f days).", ...
    req.Id, actualDays, operationalDays, reservePct, requiredDays));
end
