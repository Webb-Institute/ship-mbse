function updated = propagatePipeFluids(opts)
%PROPAGATEPIPEFLUIDS Copy each fuel consumer's FuelType onto the pipe that supplies it.
%   updated = propagatePipeFluids() reads FuelProfile.FuelConsumer.FuelType
%   from each consumer listed in shipmbse.config().FuelSupplyPipes (its active
%   variant choice, if the consumer is a variant), writes it to
%   FuelComponentProfile.Pipe.Fluid on the active choice of the supplying
%   pipe, and saves the model. Returns a table of the changes.
%
%   Pipes whose active choice has no Pipe stereotype (e.g. ABSENT) are
%   skipped. A consumer without a FuelType is an error.
%
%   This MODIFIES THE MODEL. Name-value option Save (true) controls saving.
%
%   See also fuelAnalysis, shipmbse.config.

arguments
    opts.Save (1,1) logical = true
end

cfg = shipmbse.config();
st = cfg.Stereotypes;
model = shipmbse.loadModel();
pairs = cfg.FuelSupplyPipes;

n = size(pairs, 1);
updated = table(strings(n, 1), strings(n, 1), strings(n, 1), strings(n, 1), ...
    'VariableNames', {'Consumer', 'Pipe', 'Fluid', 'Action'});
for k = 1:n
    consumer = resolveActive(lookup(model, 'Path', cfg.ModelName + "/" + pairs(k, 1)), pairs(k, 1));
    pipe = resolveActive(lookup(model, 'Path', cfg.ModelName + "/" + pairs(k, 2)), pairs(k, 2));
    updated.Consumer(k) = consumer.Name;
    updated.Pipe(k) = pipe.Name;

    if ~any(string(consumer.getStereotypes()) == st.FuelConsumer)
        updated.Action(k) = "skipped: consumer has no FuelConsumer stereotype";
        continue
    end
    fluid = strtrim(string(shipmbse.getProp(consumer, st.FuelConsumer + ".FuelType")));
    if fluid == ""
        error("propagatePipeFluids:NoFuelType", "Consumer ""%s"" has no FuelType.", consumer.Name);
    end
    updated.Fluid(k) = fluid;
    if ~any(string(pipe.getStereotypes()) == st.Pipe)
        updated.Action(k) = "skipped: pipe choice has no Pipe stereotype";
        continue
    end
    pipe.setProperty(st.Pipe + ".Fluid", "'" + fluid + "'");   % string properties are stored quoted
    updated.Action(k) = "set";
end

if opts.Save && any(updated.Action == "set")
    model.save;
end
disp(updated);

end

function c = resolveActive(c, path)
if isempty(c)
    error("propagatePipeFluids:NotFound", "Component ""%s"" not found.", path);
end
if isa(c, 'systemcomposer.arch.VariantComponent')
    c = c.getActiveChoice();
end
end
