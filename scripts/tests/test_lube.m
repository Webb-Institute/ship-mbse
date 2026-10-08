function tests = test_lube
%TEST_LUBE Verifies REQ-110 Lubrication Service: capacity that is on covers demand that is on.
tests = functiontests(localfunctions);
end

function test_LubeSupplyVersusDemand(testCase)
st = shipmbse.config().Stereotypes;
verifyServiceBalance(testCase, st.LubeConsumer + ".LubeRequired", st.LubeProducer + ".LubeProduced", "Lube oil supply");
end
