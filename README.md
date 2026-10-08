# ship-mbse

Model-Based Systems Engineering (MBSE) architecture for the concept design of a
**Military Sealift Command multi-purpose vessel**: common fore and aft sections with a
swappable mission midbody (command ship, submarine/destroyer tender, and others).
Built with MATLAB System Composer and Requirements Toolbox.

## Status

Early concept architecture, under active cleanup (October 2026).

- **Architecture:** `SYSTEM.slx` holds an SWBS-style physical hierarchy (groups 100–700, 77
  components, variant choices for propulsion and fuel). Ports are fully wired, but interfaces
  have no elements yet.
- **Requirements:** 122 requirements in `ShipRequirements.slreqx`, allocated to components, all
  links resolving.
- **Property data** in `data/input_tables/` is **placeholder** and not engineering data.
- **Tools:** shared `+shipmbse` package with code tests (96% coverage), Code Analyzer clean.
- **Verification:** 8 requirement tests; REQ-402/403 (fuel endurance) currently **fail** on the
  placeholder data (5.8 days vs. 100 required).

See [`handoff/known_issues.md`](handoff/known_issues.md) for current limitations.

## Prerequisites

MATLAB **R2026a** with:

- System Composer
- Simulink
- Requirements Toolbox
- MATLAB Report Generator / Simulink Report Generator (for future model-generated reports)

## Quickstart

```matlab
openProject("path/to/ship-mbse")   % sets the MATLAB path; or double-click ship-mbse.prj
buildtool                          % code checks + code tests
buildtool verify trace             % requirement verification tests + traceability audit
runAllReports                      % all reports to outputs/reports/, plus a snapshot
```

Open the model with the project shortcut **Open SYSTEM (master model)**, or run
`systemcomposer.openModel("SYSTEM")`.

## Repository layout

```
ship-mbse/
  ship-mbse.prj, resources/   MATLAB Project definition (always open the project)
  model/
    system_composer/          SYSTEM.slx (master model) and its requirement link set
    requirements/             ShipRequirements.slreqx
    profiles/                 Stereotype profiles (XML)
    exported_views/           Exported diagrams
  InterfaceDictionary.sldd    Interface data dictionary (not yet attached to SYSTEM)
  data/input_tables/          Excel property tables applied to the model
  buildfile.m                 Build tasks (buildtool)
  scripts/
    runAllTests.m, runAllReports.m   Entry points
    +shipmbse/                Shared package: traversal, properties, calculations
    analysis/                 Reports and analyses (read-only)
    build/                    Utilities that modify the model (properties, variants, ports)
    utilities/                Legacy wrappers and getOutputDir
    tests/                    Requirement verification tests (+ link sets)
    tests/unit/               Code tests (MiniShip fixture, regression baseline)
  outputs/                    Generated reports, figures, snapshots, test results (not committed)
  docs/                       Documentation
  handoff/                    Known issues, future work, maintenance logs
```

## Documentation

| Document | Contents |
|---|---|
| [`docs/developer_guide.md`](docs/developer_guide.md) | Setup, architecture, profiles, utilities, reports, requirements and testing workflow |
| [`docs/model_guide.md`](docs/model_guide.md) | How the System Composer model is organized |
| [`docs/glossary.md`](docs/glossary.md) | Terms, model ID numbering, connection naming convention |
| [`docs/eswbs_mapping.md`](docs/eswbs_mapping.md) | Model ID → Navy ESWBS mapping, with number-collision warnings |
| [`docs/scripts_guide.md`](docs/scripts_guide.md) | Where scripts go and how to add one |
| [`docs/assumptions_and_limits.md`](docs/assumptions_and_limits.md) | Modeling assumptions and limitations |
| [`docs/case_study_guide.md`](docs/case_study_guide.md) | Reference case study (planned) |
| [`handoff/known_issues.md`](handoff/known_issues.md) | Open defects and gaps |
| [`handoff/future_work.md`](handoff/future_work.md) | Roadmap |

## Working conventions

- Always open the MATLAB Project; never use `addpath` manually.
- Add new files to the project and keep **Project > Run Checks** clean.
- Commit model (`.slx`) changes in small, focused PRs. Binary model files merge through the
  MATLAB merge tool (`mlAutoMerge`, configured in `.gitattributes`).
- Analyses never modify the model; model-changing scripts live in `scripts/build/`.
- Run `buildtool` before committing; Code Analyzer warnings fail the build.

## License

To be determined. The project is intended to be released as open source. **MIT** or **BSD 3-Clause** is the likely choice, pending confirmation of how the release is approved (Webb Institute and project sponsor). Until a `LICENSE` file is added, all rights are reserved.
