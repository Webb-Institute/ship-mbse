function configuration = configureShip(opts)
%CONFIGURESHIP Select the propulsion and fuel-system variant choices, then save.
%   configureShip() applies the default configuration (diesel, shaft drive
%   with maneuvering thruster, PTO, all fuel consumers) and saves the model.
%   configureShip(Name=Value) overrides settings:
%
%     Architecture         "DIESEL" (default) | "HYBRID" | "ELECTRIC"
%     PTO                  true (default): power take-off on the gearbox
%     Propulsor            "SHAFT" (default) | "ELECTRIC" | "WATERJET"
%     ManeuveringThruster  true (default)
%     MainEngine           true (default)
%     DieselGenerators     true (default)
%     MissionFuel          true (default)
%     Save                 true (default): save the model afterwards
%
%   Returns a table of the variant choices that were set. This MODIFIES THE
%   MODEL.
%
%   Example:
%     configureShip(Propulsor="WATERJET", ManeuveringThruster=false)
%
%   See also shipmbse.config.

arguments
    opts.Architecture (1,1) string {mustBeMember(opts.Architecture, ["DIESEL", "HYBRID", "ELECTRIC"])} = "DIESEL"
    opts.PTO (1,1) logical = true
    opts.Propulsor (1,1) string {mustBeMember(opts.Propulsor, ["SHAFT", "ELECTRIC", "WATERJET"])} = "SHAFT"
    opts.ManeuveringThruster (1,1) logical = true
    opts.MainEngine (1,1) logical = true
    opts.DieselGenerators (1,1) logical = true
    opts.MissionFuel (1,1) logical = true
    opts.Save (1,1) logical = true
end

cfg = shipmbse.config();
model = shipmbse.loadModel(cfg.ModelName);
prop = cfg.ModelName + "/" + cfg.Paths.Propulsion;
fuel = cfg.ModelName + "/" + cfg.Paths.Fuel;

propulsorChoice = dictionary(["SHAFT", "ELECTRIC", "WATERJET"], ...
    ["21X SHAFT DRIVE", "21X ELECTRIC DRIVE", "21X WATER JET"]);
choice21 = propulsorChoice(opts.Propulsor);
if opts.ManeuveringThruster
    choice21 = choice21 + " + MANEUVERING THRUSTER";
end

if opts.Architecture == "ELECTRIC"
    choice23 = "23X ABSENT";
elseif opts.PTO
    choice23 = "23X MECHANICAL WITH POWER TAKEOFF";
else
    choice23 = "23X MECHANICAL";
end

fuelNeeded = opts.MainEngine || opts.DieselGenerators || opts.MissionFuel;
settings = [ ...
    prop + "/20X (MAIN ENGINE)",        pick(opts.MainEngine, "20X DIESEL ENGINE", "20X ABSENT");
    prop + "/21X (PROPULSORS)",         choice21;
    prop + "/22X (SHAFTING)",           pick(opts.Propulsor == "WATERJET", "22X ABSENT", "22X MECHANICAL");
    prop + "/23X (POWER TRANSMISSION)", choice23;
    fuel,                               pick(fuelNeeded, "52X FUEL", "52X ABSENT")];
if fuelNeeded
    piping = fuel + "/52X FUEL";
    settings = [settings;
        piping + "/525 (ME FO PIPING)",      pick(opts.MainEngine, "525 ME FO PIPING", "525 ABSENT");
        piping + "/526 (GS FO PIPING)",      pick(opts.DieselGenerators, "526 GS FO PIPING", "526 ABSENT");
        piping + "/527 (MISSION FO PIPING)", pick(opts.MissionFuel, "527 MISSION FO PIPING", "527 ABSENT")];
end

for k = 1:size(settings, 1)
    selectVariant(lookup(model, 'Path', settings(k, 1)), settings(k, 2));
end
configuration = table(shipmbse.pathLeaf(settings(:, 1)), settings(:, 2), ...
    'VariableNames', {'Variant', 'ActiveChoice'});
disp(configuration);

if opts.Save
    model.save;
    disp("Ship configuration saved.");
end

end

function s = pick(condition, ifTrue, ifFalse)
if condition
    s = ifTrue;
else
    s = ifFalse;
end
end

function selectVariant(component, choiceName)
if isempty(component)
    error("configureShip:NotFound", "Variant component for choice ""%s"" not found.", choiceName);
end
choices = component.getChoices();
match = choices(string({choices.Name}) == choiceName);
if isempty(match)
    error("configureShip:NoChoice", "Variant ""%s"" has no choice ""%s"". Available: %s", ...
        component.Name, choiceName, strjoin(string({choices.Name}), ", "));
end
component.setActiveChoice(match);
end
