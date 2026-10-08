function tests = test_Req_FuelEndurance_01
%TEST_REQ_FUELENDURANCE_01 Verifies REQ-402 Usable Fuel Inventory.
%   Fuel endurance of the active configuration must be at least the linked
%   requirement's Threshold (days).
tests = functiontests(localfunctions);
end

function test_RequirementPassCriteria(testCase)
[requiredDays, req] = shipmbse.reqValue(mfilename, "Threshold", Units="day");
actualDays = getFuelSystemEndurance();
testCase.verifyGreaterThanOrEqual(actualDays, requiredDays, sprintf( ...
    "%s not met: fuel endurance %.2f days is below the required %.2f days.", req.Id, actualDays, requiredDays));
end
