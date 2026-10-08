function model = buildMiniShip(name)
%BUILDMINISHIP Build the in-memory MiniShip test fixture (not saved).
%   model = buildMiniShip() creates a small System Composer model with the
%   project profiles and hand-checkable data. Close it with
%   bdclose("MiniShip") when done. Expected values (see test_shipmbse):
%
%   Component           Weight  LCG  VCG  TCG  Margin  Other
%   HULL/PLATE            100    10    5    0    10%
%   HULL/FRAME             50    20    6    2     0%
%   PROP/DIESEL (active)   30    40    3   -1    20%   5 kW load (on); 0.001 kL/s F76 (on)
%   PROP/ELECTRIC          999   99   99   99     0%   500 kW load (on) -- INACTIVE choice
%   GEN                    20    30    4    0     0%   20 kW generator (on); 0.0005 kL/s F76 (on)
%   LOADS                                             8 kW load (on)
%   LOADS2                                            100 kW load (OFF)
%   FUEL                                              100 kL stored
%
%   Connections: GEN.P -> LOADS.P, and GEN.Q -> PROP.Q (resolved to DIESEL.Q).

arguments
    name (1,1) string = "MiniShip"
end

if bdIsLoaded(name)
    bdclose(name);
end
model = systemcomposer.createModel(name);
for p = ["WeightsCentersProfile", "ElectricalProfile", "FuelProfile", "PortProfile"]
    model.applyProfile(p);
end
arch = model.Architecture;

wc = "WeightsCentersProfile.WeightsCenters";
ec = "ElectricalProfile.ElectricalConsumer";
eg = "ElectricalProfile.ElectricalGenerator";
fc = "FuelProfile.FuelConsumer";
fp = "FuelProfile.FuelProducer";

hull = arch.addComponent("HULL");
plate = hull.Architecture.addComponent("PLATE");
frame = hull.Architecture.addComponent("FRAME");
setWeight(plate, wc, 100, 10, 5, 0, 10);
setWeight(frame, wc, 50, 20, 6, 2, 0);

prop = arch.addVariantComponent("PROP");
choices = prop.addChoice({'DIESEL', 'ELECTRIC'});
diesel = choices(1);
electric = choices(2);
setWeight(diesel, wc, 30, 40, 3, -1, 20);
setStereo(diesel, ec, "PowerRequired", "5", "Status", "true");
setStereo(diesel, fc, "FuelRequired", "0.001", "Status", "true", "FuelType", "'F76'");
setWeight(electric, wc, 999, 99, 99, 99, 0);
setStereo(electric, ec, "PowerRequired", "500", "Status", "true");
prop.setActiveChoice(diesel);

gen = arch.addComponent("GEN");
setWeight(gen, wc, 20, 30, 4, 0, 0);
setStereo(gen, eg, "PowerGenerated", "20", "Status", "true");
setStereo(gen, fc, "FuelRequired", "0.0005", "Status", "true", "FuelType", "'F76'");

loads = arch.addComponent("LOADS");
setStereo(loads, ec, "PowerRequired", "8", "Status", "true");
loads2 = arch.addComponent("LOADS2");
setStereo(loads2, ec, "PowerRequired", "100", "Status", "false");

fuel = arch.addComponent("FUEL");
setStereo(fuel, fp, "FuelStored", "100", "Status", "true");

% Connections: a direct one and one through the variant container
gen.Architecture.addPort("P", "out");
loads.Architecture.addPort("P", "in");
genP = gen.getPort("P");
connect(genP, loads.getPort("P"));        % port-to-port connect (arch.connect does not add it)
gen.Architecture.addPort("Q", "out");
diesel.Architecture.addPort("Q", "in");     % choice port ...
prop.updatePortsFromChoices("Mode", "addPorts");   % ... exposed on the variant container
connect(gen.getPort("Q"), prop.getPort("Q"));
% Port stereotypes are applied on the architecture port
genArchP = gen.Architecture.getPort("P");
genArchP.applyStereotype("PortProfile.Redundancy");
genArchP.setProperty("PortProfile.Redundancy.RedundancyScore", "2");

end

function setWeight(c, wc, w, l, v, t, margin)
setStereo(c, wc, "Weight", string(w), "LCG", string(l), "VCG", string(v), "TCG", string(t), ...
    "WeightMargin", string(margin));
end

function setStereo(c, stereotype, varargin)
c.applyStereotype(stereotype);
for k = 1:2:numel(varargin)
    c.setProperty(stereotype + "." + varargin{k}, varargin{k+1});
end
end
