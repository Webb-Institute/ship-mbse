function tests = test_Req_FuelEndurance_02
% TEST_REQ_FUELENDURANCE_02 Verifies REQ-403 Reserve Fuel Quantity.
%   Usable fuel must cover the intended operational period (REQ-402,
%   verified by test_Req_FuelEndurance_01) plus a reserve equal to PerfVal1
%   percent of that period (REQ-403, linked to this test).
tests = functiontests(localfunctions);
end

function test_RequirementPassCriteria(testCase)
% 1. Read thresholds: reserve percentage from this test's linked requirement
%    (REQ-403); operational period from the REQ-402 link of _01.
reservePct = getLinkedPerfVal(mfilename, 'PerfVal1');
testCase.assertFalse(isnan(reservePct), 'PerfVal1 (reserve %) could not be read from the REQ-403 link.');
operationalDays = getLinkedPerfVal('test_Req_FuelEndurance_01', 'PerfVal1');
testCase.assertFalse(isnan(operationalDays), 'PerfVal1 (operational days) could not be read from the REQ-402 link.');

% 2. Get system endurance from model
actualSystemDays = getFuelSystemEndurance();
requiredDays = operationalDays * (1 + reservePct/100);

% 3. Verify requirement condition
testCase.verifyGreaterThanOrEqual(actualSystemDays, requiredDays, ...
    sprintf(['Requirement FAILED: System endurance (%.2f days) does not cover the operational ' ...
    'period (%.2f days) plus %.1f%% reserve (%.2f days required).'], ...
    actualSystemDays, operationalDays, reservePct, requiredDays));
end
