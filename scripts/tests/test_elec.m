function tests = test_elec
tests = functiontests(localfunctions);
end

function test_ElectricalSupplyVersusDemand(testCase)
% 1. Define values

[elecReq, ~] =sumPropIfOn('PowerRequired', 'ElectricalConsumer', 'ElectricalProfile');
[elecGen, ~] =sumPropIfOn('PowerGenerated', 'ElectricalGenerator', 'ElectricalProfile');


% 2. Use the test framework assertion
verifyGreaterThanOrEqual(testCase, elecGen, elecReq, ...
    'Insufficient Power Supply');

end