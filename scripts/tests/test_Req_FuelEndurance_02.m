function tests = test_Req_FuelEndurance_02
tests = functiontests(localfunctions);
end

function test_RequirementPassCriteria(testCase)
perfValThreshold = getLinkedPerfVal(mfilename, 'PerfVal1');
testCase.assertFalse(isnan(perfValThreshold), 'PerfVal1 attribute could not be read from requirement link.');

actualSystemDays = getFuelSystemEndurance('SYSTEM');

testCase.verifyGreaterThanOrEqual(actualSystemDays, perfValThreshold, ...
    sprintf('Requirement FAILED: System endurance (%.2f days) is below required threshold (%.2f days).', ...
    actualSystemDays, perfValThreshold));
end