function tests = test_fuel
    tests = functiontests(localfunctions);
end

function test_FuelSupplyVersusDemand(testCase)
    % 1. Define values
    
    [fuelReq, ~] =sumPropIfOn('FuelRequired', 'FuelConsumer', 'FuelProfile');
    [fuelGen, ~] =sumPropIfOn('FuelProduced', 'FuelProducer', 'FuelProfile');
   

    % 2. Use the test framework assertion
    verifyGreaterThanOrEqual(testCase, fuelGen, fuelReq, ...
        'Insufficient Fuel Oil Supply');
   
end