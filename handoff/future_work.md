# Future Work

Roadmap agreed in October 2026. Each phase builds on the previous one.

## Decisions in force

| ID | Decision |
|---|---|
| D1 | The ship is an MSC **multi-purpose vessel concept**: common fore and aft sections with a swappable mission midbody. Missions that fit a standard hull and plant come first: **command/C2** and **submarine/destroyer tender**, then hospital and range instrumentation. Missions that don't fit a standard hull (oiler/UNREP, SWATH surveillance, sea base, salvage) are deferred. |
| D2 | **Keep the model IDs**; do not renumber to ESWBS. Publish a full model-ID → ESWBS mapping in the documentation. |
| D3 | **`SYSTEM.slx` is the master parent model.** Each primary group (100–700) becomes a referenced architecture model, and each mission midbody module is a referenced model under a `MIDBODY` variant. All cross-group connectors live in `SYSTEM` and are typed by one shared interface dictionary, so integration is enforced at the interfaces. |

## Phases

0. **Stabilize the repo** (done, October 2026): MATLAB Project as the entry point, plain-text live
   code, single output folder, repaired traceability, documentation triage, ESWBS mapping.
1. **Correctness** (in progress: shared package, read-only analyses, fixed defects, tests,
   requirement thresholds and `buildfile` done; units overhaul and Excel ingestion hardening next):
   - Central configuration; one component traversal and one property reader, aware of
     referenced models.
   - Analyses that never modify the model.
   - Unit and bug fixes (see `known_issues.md`), tests that can fail, and
     requirement-parameterized verification (custom attributes).
   - `buildfile.m` orchestration.
2. **Restructure and governance:**
   - A tooling spike that proves the full hierarchy is covered across model references.
   - Interface dictionary with real elements, and one consolidated stereotype profile.
   - Split into group and module referenced models.
   - Mission Module Interface (MMI) envelope.
   - Model Advisor integration checks and CI.
3. **Operational and requirements foundation:**
   - Concept of operations, operating conditions, and a context diagram with external
     interfaces.
   - Requirement schema and sets (Platform, Module Interface, one per mission).
   - Quantified KPPs and a functional architecture with an allocation set.
   - 3-digit decomposition and ESWBS cross-check.
4. **Mission modules:** template and envelope verification; C2, then tender, then hospital,
   then range instrumentation; envelope trade study.
5. **Analyses, behavior and safety:**
   - Weights and CoG with section offsets, interface (N²) matrix, electric load analysis by
     operating condition, fuel endurance and range, fluid and thermal balances.
   - Change impact and trade studies.
   - Operating-mode and sequence behavior, and FHA/FMEA.
6. **Documentation and delivery:** guides, a model-generated design data book, mission module
   datasheets, a reference case study, and exported views.
