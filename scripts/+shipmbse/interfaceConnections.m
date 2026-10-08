function conns = interfaceConnections(model)
%INTERFACECONNECTIONS End-to-end connections between leaf components.
%   conns = shipmbse.interfaceConnections() follows every port of every leaf
%   component in the active configuration through connectors, composite
%   boundaries (architecture ports) and variant containers, to the leaf
%   port(s) at the other end. Returns one row per unique leaf-to-leaf
%   connection:
%     EndA, PortA, EndB, PortB          component paths and port names
%     Interface                         interface name on PortA
%     InterfaceMatch                    PortA and PortB use the same interface
%     RedundancyA, RedundancyB          PortProfile.Redundancy.RedundancyScore
%                                       on each end's own port (NaN if absent)
%   A path that leaves the root architecture ends at EndB = "<external>".
%
%   See also generateInterfaceReport, shipmbse.activeComponents.

arguments
    model (1,1) systemcomposer.arch.Model = shipmbse.loadModel()
end

[leaves, leafPaths] = shipmbse.activeComponents(model, LeavesOnly=true);
pathOf = dictionary(double.empty, string.empty);
for k = 1:numel(leaves)
    pathOf(leaves(k).SimulinkHandle) = leafPaths(k);
end
redStereo = shipmbse.config().Stereotypes.PortRedundancy;

rows = cell(0, 8);
seen = strings(0);
for k = 1:numel(leaves)
    for p = leaves(k).Ports
        ends = traceFrom(p, model);
        for i = 1:numel(ends)
            e = ends(i);
            [a, b] = deal(leafPaths(k) + "|" + p.Name, endKey(e, pathOf));
            key = strjoin(sort([a, b]), " <-> ");
            if ismember(key, seen)
                continue
            end
            seen(end+1) = key; %#ok<AGROW>
            if isempty(e.port)
                [endB, portB, ifB, redB] = deal("<external>", e.name, "", NaN);
            else
                [endB, portB, ifB, redB] = deal(lookupPath(e.comp, pathOf), string(e.port.Name), ...
                    string(e.port.InterfaceName), portScore(e.port, redStereo));
            end
            ifA = string(p.InterfaceName);
            rows(end+1, :) = {leafPaths(k), string(p.Name), endB, portB, ifA, ifA == ifB, ...
                portScore(p, redStereo), redB}; %#ok<AGROW>
        end
    end
end
conns = cell2table(rows, 'VariableNames', {'EndA', 'PortA', 'EndB', 'PortB', 'Interface', ...
    'InterfaceMatch', 'RedundancyA', 'RedundancyB'});
conns = sortrows(conns, {'EndA', 'PortA'});

end

% ---------------------------------------------------------------------------
function ends = traceFrom(startPort, model)
% Leaf endpoints reachable from a leaf component port.
ends = struct('comp', {}, 'port', {}, 'name', {});
visited = [];
queue = {};
owner = startPort.Parent;
container = variantOf(owner);
if ~isempty(container)
    % A variant choice is wired through its container's port of the same name
    queue{end+1} = {"comp", container.getPort(startPort.Name)};
else
    queue{end+1} = {"comp", startPort};
end
while ~isempty(queue)
    item = queue{1}; queue(1) = [];
    port = item{2};   % item{1} records the side ("comp" or "arch") for debugging
    if isempty(port) || ismember(port.SimulinkHandle, visited)
        continue
    end
    visited(end+1) = port.SimulinkHandle; %#ok<AGROW>
    for conn = port.Connectors
        for q = conn.Ports
            if q.SimulinkHandle == port.SimulinkHandle
                continue
            end
            [ends, queue] = handlePort(q, ends, queue, model, startPort);
        end
    end
end
end

function [ends, queue] = handlePort(q, ends, queue, model, startPort)
if isa(q, 'systemcomposer.arch.ArchitecturePort')
    arch = q.Parent;
    if isequal(arch, model.Architecture)
        ends(end+1) = struct('comp', [], 'port', [], 'name', string(q.Name));
        return
    end
    outer = arch.Parent;                       % component owning this architecture
    container = variantOf(outer);
    if ~isempty(container)
        outer = container;                     % choice -> its variant container
    end
    queue{end+1} = {"comp", outer.getPort(q.Name)};
    return
end
% Component port of a sibling component
s = q.Parent;
if isa(s, 'systemcomposer.arch.VariantComponent')
    s = s.getActiveChoice();
    if isempty(s)
        return
    end
    q = s.getPort(q.Name);
    if isempty(q)
        return                                 % active choice lacks the port (e.g. ABSENT)
    end
end
if isempty(s.Architecture) || isempty(s.Architecture.Components)
    if q.SimulinkHandle ~= startPort.SimulinkHandle
        ends(end+1) = struct('comp', s, 'port', q, 'name', string(q.Name));
    end
else
    queue{end+1} = {"arch", q.ArchitecturePort};
end
end

function v = variantOf(comp)
% Variant container whose choice is COMP, or [] if COMP is not a choice
v = [];
if isa(comp, 'systemcomposer.arch.Component') && ~isempty(comp.Parent) ...
        && isa(comp.Parent.Parent, 'systemcomposer.arch.VariantComponent')
    v = comp.Parent.Parent;
end
end

function key = endKey(e, pathOf)
if isempty(e.port)
    key = "<external>|" + e.name;
else
    key = lookupPath(e.comp, pathOf) + "|" + e.port.Name;
end
end

function p = lookupPath(comp, pathOf)
if isKey(pathOf, comp.SimulinkHandle)
    p = pathOf(comp.SimulinkHandle);
else
    p = string(comp.getQualifiedName());
end
end

function s = portScore(port, stereotype)
% RedundancyScore from the port's own stereotype. (For ports, hasProperty and
% getStereotypeProperties do not report stereotype properties; getProperty does.)
s = NaN;
if any(string(port.getStereotypes()) == stereotype)
    s = str2double(string(port.getProperty(stereotype + ".RedundancyScore")));
end
end
