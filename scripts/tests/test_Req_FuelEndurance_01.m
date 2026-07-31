function tests = test_Req_FuelEndurance_01
tests = functiontests(localfunctions);
end

function test_RequirementPassCriteria(testCase)
% 1. Read PerfVal1 threshold for this specific requirement link
perfValThreshold = getLinkedPerfVal(mfilename, 'PerfVal1');
testCase.assertFalse(isnan(perfValThreshold), 'PerfVal1 attribute could not be read from requirement link.');

% 2. Get system endurance from model
actualSystemDays = getFuelSystemEndurance('SYSTEM');

% 3. Verify requirement condition
testCase.verifyGreaterThanOrEqual(actualSystemDays, perfValThreshold, ...
    sprintf('Requirement FAILED: System endurance (%.2f days) is below required threshold (%.2f days).', ...
    actualSystemDays, perfValThreshold));
end