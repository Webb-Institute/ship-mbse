function tests = test_elec
%TEST_ELEC Verifies REQ-103 Electrical Energy Distribution: capacity that is on covers demand that is on.
tests = functiontests(localfunctions);
end

function test_ElectricalSupplyVersusDemand(testCase)
st = shipmbse.config().Stereotypes;
verifyServiceBalance(testCase, st.ElectricalConsumer + ".PowerRequired", st.ElectricalGenerator + ".PowerGenerated", "Electrical power");
end
