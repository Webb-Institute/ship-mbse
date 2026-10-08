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
- **Tests:** 8 tests. 3 fail by design until requirement custom attributes are added.

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
runAllTests                        % run the verification test suite
runAllReports                      % write reports to outputs/reports/
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
  scripts/
    runAllTests.m, runAllReports.m   Entry points
    utilities/                Property application, variant configuration, roll-ups
    plugins/                  Reports and analyses
    tests/                    Requirement verification tests (+ link sets)
  outputs/                    Generated reports, tables, figures (not committed)
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
| [`docs/plugin_guide.md`](docs/plugin_guide.md) | Report and analysis scripts |
| [`docs/assumptions_and_limits.md`](docs/assumptions_and_limits.md) | Modeling assumptions and limitations |
| [`docs/case_study_guide.md`](docs/case_study_guide.md) | Reference case study (planned) |
| [`handoff/known_issues.md`](handoff/known_issues.md) | Open defects and gaps |
| [`handoff/future_work.md`](handoff/future_work.md) | Roadmap |

## Working conventions

- Always open the MATLAB Project; never use `addpath` manually.
- Add new files to the project and keep **Project > Run Checks** clean.
- Commit model (`.slx`) changes in small, focused PRs. Binary model files merge through the
  MATLAB merge tool (`mlAutoMerge`, configured in `.gitattributes`).
- Report scripts write only to `outputs/`, which is not committed.

## License

To be determined. The project is intended to be released as open source. **MIT** or **BSD 3-Clause** is the likely choice, pending confirmation of how the release is approved (Webb Institute and project sponsor). Until a `LICENSE` file is added, all rights are reserved.
