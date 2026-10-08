function tests = test_fuel
%TEST_FUEL Verifies REQ-111 Fuel Oil Supply: capacity that is on covers demand that is on.
tests = functiontests(localfunctions);
end

function test_FuelSupplyVersusDemand(testCase)
st = shipmbse.config().Stereotypes;
verifyServiceBalance(testCase, st.FuelConsumer + ".FuelRequired", st.FuelProducer + ".FuelProduced", "Fuel oil supply");
end
