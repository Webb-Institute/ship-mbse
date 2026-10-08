# Traceability Repair Log — October 2026 (Phase 0, task P0.7)

During the July–August 2026 requirements rework, several requirements in `ShipRequirements.slreqx` were deleted and some were recreated under new IDs. Links that pointed at the deleted items were left dangling: **41 of 213** allocation links in `model/system_composer/SYSTEM~mdl.slmx` and **4** test verification links in `scripts/tests/*~m.slmx`.

Each deleted requirement was traced through git history and handled as follows:

- **Recreated with an identical summary** → link re-targeted to the new requirement, or removed if the component already linked to it.
- **No successor** → link removed. A *suggested* re-link is listed below. It is **not applied**, because choosing the successor is an engineering allocation decision.

After repair, all 9 link sets resolve: **187 links, 0 unresolved**.

## Allocation links (`SYSTEM~mdl.slmx`)

**Already linked?** shows whether the component already links to the suggested requirement(s) today. If it does, the removed link was redundant and no action is needed.

| Component | Deleted requirement (old SID) | Action | Suggested re-link | Already linked? |
|---|---|---|---|---|
| 32X (BATTERY) | Stored-Energy Supply (46) | removed (no successor) | REQ-105, REQ-107 | yes |
| 32X (BATTERY) | Electrical Energy Storage (5) | removed (no successor) | REQ-107 | yes |
| 41X (RADIO/SATCOM) | Mission Communications (90) | retargeted to REQ-604 | — | — |
| 42X (CONSOLES) | Mission Systems Integration (87) | retargeted to REQ-601 | — | — |
| 42X (CONSOLES) | Mission Systems Operation (88) | removed (duplicate of existing link to REQ-602) | — | — |
| 42X (CONSOLES) | Mission Information (89) | removed (duplicate of existing link to REQ-603) | — | — |
| 42X (CONSOLES) | Mission Communications (90) | retargeted to REQ-604 | — | — |
| 42X (CONSOLES) | Mission Resources (91) | retargeted to REQ-605 | — | — |
| 44X (AIR SURVEILLANCE) | Mission Information (89) | retargeted to REQ-603 | — | — |
| 45X (WATER SURVEILLANCE) | Mission Information (89) | retargeted to REQ-603 | — | — |
| 50X (COOLING AND FRESHWATER) | Freshwater Cooling (19) | removed (no successor) | REQ-109 | yes |
| 50X (COOLING AND FRESHWATER) | Thermal Environment Control (26) | removed (no successor) | REQ-114, REQ-139 | partly (REQ-114) |
| 50X (COOLING AND FRESHWATER) | Thermal Energy Transfer (38) | removed (no successor) | REQ-114 | yes |
| 50X (COOLING AND FRESHWATER) | Freshwater Distribution (53) | removed (no successor) | REQ-120, REQ-421 | yes |
| 50X (COOLING AND FRESHWATER) | Potable Water Storage (56) | removed (duplicate of existing link to REQ-420) | — | — |
| 50X (COOLING AND FRESHWATER) | Potable Water Distribution (57) | removed (duplicate of existing link to REQ-421) | — | — |
| 51X (LUBE OIL) | Thermal Energy Transfer (38) | removed (no successor) | REQ-114 | no — re-linked 2026-10-08 |
| 523 (FUEL CONDITIONING) | Flow Capacity Requirement (140) | removed (no successor) | REQ-406 | no — re-linked 2026-10-08 |
| 52X (FUEL) | Propulsion Machinery Fuel Oil Supply (14) | removed (no successor) | REQ-111, REQ-409 | partly (REQ-111) |
| 52X (FUEL) | Fuel Consumption (144) | removed (no successor) | REQ-406 | no — re-linked 2026-10-08 |
| 52X (FUEL) | Auxiliary Machinery Fuel Oil Supply (15) | removed (no successor) | REQ-111, REQ-409 | partly (REQ-111) |
| 53X (COMPRESSED AIR) | Compressed Air Supply (17) | removed (no successor) | REQ-113 | yes |
| 55X (CARGO/MISSION) | Mission Systems Integration (87) | removed (duplicate of existing link to REQ-601) | — | — |
| 57X (WASTE MANAGEMENT) | Thermal Environment Control (26) | removed (no successor) | REQ-114, REQ-139 | partly (REQ-114) |
| 57X (WASTE MANAGEMENT) | Thermal Energy Recovery (29) | removed (no successor) | REQ-116 | yes |
| 57X (WASTE MANAGEMENT) | Recovered Thermal Energy Utilization (31) | removed (no successor) | REQ-116 | yes |
| 57X (WASTE MANAGEMENT) | Environmental Heat Rejection (32) | removed (no successor) | REQ-115 | no — re-linked 2026-10-08 |
| 57X (WASTE MANAGEMENT) | Seawater Heat Rejection (35) | removed (no successor) | REQ-115 | no — re-linked 2026-10-08 |
| 57X (WASTE MANAGEMENT) | Air Heat Rejection (36) | removed (no successor) | REQ-115 | no — re-linked 2026-10-08 |
| 57X (WASTE MANAGEMENT) | Thermal Energy Transfer (38) | removed (no successor) | REQ-114 | yes |
| 57X (WASTE MANAGEMENT) | Oily Waste Management (72) | removed (no successor) | REQ-124 | yes |
| 57X (WASTE MANAGEMENT) | Sewage Management (73) | removed (no successor) | REQ-126 | yes |
| 57X (WASTE MANAGEMENT) | Garbage Management (74) | removed (no successor) | REQ-128 | yes |
| 57X (WASTE MANAGEMENT) | Hazardous Gases Management (77) | removed (no successor) | REQ-202, REQ-130 | yes |
| 58X (FIRE) | Hazardous Gases Management (77) | removed (no successor) | REQ-202, REQ-130 | no — re-linked 2026-10-08 |
| 59X (HOTEL) | Thermal Environment Control (26) | removed (no successor) | REQ-114, REQ-139 | yes |
| 59X (HOTEL) | Ventilation (76) | removed (no successor) | REQ-134, REQ-135, REQ-139 | partly (REQ-139) |
| 59X (HOTEL) | Hazardous Gases Management (77) | removed (no successor) | REQ-202, REQ-130 | no — re-linked 2026-10-08 |
| 59X (HOTEL) | Consumables Storage (80) | retargeted to REQ-423 | — | — |
| 60X (ACCOMODATION) | Consumables Storage (80) | removed (duplicate of existing link to REQ-423) | — | — |
| SHIP | Mission Systems Support (86) | retargeted to NEED-06 | — | — |

## Test verification links (`scripts/tests/*~m.slmx`)

Each test's link source was a text range over the whole file. Ranges were narrowed to the test function (line range shown), so file headers and helper functions are no longer inside the linked range. Link identities are preserved.

| Test | Item | Action |
|---|---|---|
| `test_ExistComp_01` | text range | [1 153] -> [6 63] |
| `test_ExistComp_01` | link | kept Verify -> REQ-104 |
| `test_Req_FuelEndurance_01` | text range | [1 17] -> [5 17] |
| `test_Req_FuelEndurance_01` | link | removed Verify -> deleted SID 14 |
| `test_Req_FuelEndurance_01` | link | retargeted Verify REQ-406 -> REQ-402 |
| `test_Req_FuelEndurance_02` | text range | [1 14] -> [5 14] |
| `test_Req_FuelEndurance_02` | link | removed Verify -> deleted SID 15; later linked Verify -> REQ-403 (2026-10-08) |
| `test_cAir` | text range | [1 16] -> [5 16] |
| `test_cAir` | link | kept Verify -> REQ-113 |
| `test_cooling` | text range | [1 16] -> [5 16] |
| `test_cooling` | link | kept Verify -> REQ-109 |
| `test_elec` | text range | [1 16] -> [5 16] |
| `test_elec` | link | kept Verify -> REQ-103 |
| `test_fuel` | text range | [1 16] -> [5 16] |
| `test_fuel` | link | removed Verify -> deleted SID 15 |
| `test_fuel` | link | removed Verify -> deleted SID 14 |
| `test_fuel` | link | kept Verify -> REQ-111 |
| `test_lube` | text range | [1 16] -> [5 16] |
| `test_lube` | link | kept Verify -> REQ-110 |

## Follow-up decisions (2026-10-08)

1. **Re-link review:** all suggested re-links in rows marked "re-linked" were accepted and applied as
   `Implement` links: 51X → REQ-114; 523 and 52X → REQ-406; 57X → REQ-115; 58X and 59X → REQ-202 and
   REQ-130. Model link set: 188 links, 0 unresolved. Rows marked "partly" were not changed. Their
   remaining suggestions (REQ-139 for 50X and 57X; REQ-409 for 52X) were not flagged for re-linking.
2. **`test_Req_FuelEndurance_02` now verifies REQ-403 Reserve Fuel Quantity.** It checks that endurance
   covers the REQ-402 operational period (read through `test_Req_FuelEndurance_01`'s link) plus the
   REQ-403 reserve percentage. Like `_01`, it fails until requirement custom attributes are added.
3. `.slmx` files record the absolute path of the machine that last saved them (`artifactUri`). This is
   normal Requirements Toolbox behavior; links resolve by file name on the project path.
