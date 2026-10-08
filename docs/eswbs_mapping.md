# Model ID → ESWBS Mapping

The ship-mbse model keeps its own **SWBS-style IDs** (decision D2, October 2026). This
document maps every model ID to the Navy **Expanded Ship Work Breakdown Structure (ESWBS)**
so that model data can be compared with Navy weight, cost and configuration data.

> **Verification status:** ESWBS element numbers and titles below were cross-checked against a
> published third-party SWBS 3-digit weight-group listing
> ([mnvdet.com — SWBS weight systems](https://mail.mnvdet.com/WeightSystems.html)). Before
> formal weight reporting, confirm against the current NAVSEA ESWBS publication
> (S9040-AA-IDX-010/SWBS 5D; NAVSEA 4790.1 references). Rows marked **Confirm** involve an
> allocation judgment (where an item is booked), not just a lookup.

## ⚠ Number collisions — read first

Below the group level, model numbers **do not mean the same thing** as ESWBS numbers. The same
three digits can name a different system:

| Model ID | Model meaning | Same number in ESWBS |
|---|---|---|
| 52X, 520–529 | Fuel oil system | 520 group = **Sea water systems** (521 Firemain, 522 Sprinkling, 523 Washdown, 524 Aux seawater, 526 Scuppers/deck drains, 527 Firemain-actuated services, 528 Plumbing drainage, 529 Drainage and ballasting) |
| 53X | Compressed air | 530 group = **Fresh water systems** |
| 54X | Ballast and saltwater | 540 group = **Fuels and lubricants, handling and storage** |
| 55X | Cargo / mission | 550 group = **Air, gas and miscellaneous fluid systems** |
| 56X | Deck machinery | 560 group = **Ship control systems** |
| 57X | Waste management | 570 group = **Underway replenishment systems** |
| 58X | Fire | 580 group = **Mechanical handling systems** |
| 59X | Hotel | 590 group = **Special purpose systems** |
| 43X | Steerage (in the 400 group) | Steering is **561/562** in the 500 group |
| 73X, 74X | EW, countermeasures (700 group) | Countermeasures and EW are **470** in the 400 group |

Always write ESWBS numbers with an `ESWBS` prefix in documents and reports (e.g. "ESWBS 541")
to avoid confusion with model IDs.

## ESWBS one-digit groups

| ESWBS | Group | Modeled? |
|---|---|---|
| 100 | Hull structure | Yes (model 100) |
| 200 | Propulsion plant | Yes (model 200) |
| 300 | Electric plant | Yes (model 300) |
| 400 | Command and surveillance | Yes (model 400) |
| 500 | Auxiliary systems | Yes (model 500) |
| 600 | Outfit and furnishings | Yes (model 600) |
| 700 | Armament | Yes (model 700) |
| 800 | Integration / engineering | No (not a physical item) |
| 900 | Ship assembly and support services | No (not a physical item) |

## Mapping

**Mapping** column: **1:1** = one model item to one ESWBS element; **1:N** = model item spans
several elements; **Partial** = model item covers part of an element or the booking is a
judgment call.

### Integration level (no ESWBS equivalent)

| Model element | Notes |
|---|---|
| SHIP | Whole ship. Sum of ESWBS 100–700 |
| ENVIRONMENT | External context. Not part of the ship |
| STAKEHOLDERS | External context. Not part of the ship |

### 100 Hull

| Model ID | Model name | ESWBS element(s) | Mapping | Notes |
|---|---|---|---|---|
| 100 | HULL | 100 | 1:N | |
| 10X | PLATE | 111 Plating; 113 Inner bottom; 121–124 Structural bulkheads; 131–139 Decks; 141–149 Platforms and flats | 1:N | Model plate covers shell, bulkheads, decks and platforms |
| 11X | FRAMING | 116 Longitudinal framing; 117 Transverse framing | 1:N | |
| 12X | STIFFENERS | 116, 117; stiffening within 12x/13x/14x elements | Partial — **Confirm** | ESWBS books stiffeners with the plating or framing they stiffen |
| — | *(not modeled)* | 150 Deckhouse structure; 160 Special structures; 171–179 Masts and service platforms; 181–187 Foundations; 197 Welding | — | Foundations are implied by the 10X ↔ group `W##X` connections. Masts and deckhouse are needed for the C2 and range-instrumentation modules |

### 200 Propulsion

| Model ID | Model name | ESWBS element(s) | Mapping | Notes |
|---|---|---|---|---|
| 200 | PROPULSION | 200 | 1:N | |
| 20X | MAIN ENGINE | 233 Diesel engines | 1:1 | Engine support systems: 251 Combustion air, 259 Uptakes |
| 20X DIESEL ENGINE | (variant choice) | 233 | 1:1 | |
| 20X ABSENT | (variant choice) | — | — | No engine (e.g. all-electric) |
| 21X | PROPULSORS | 245 Propulsors; 247 Water jet propulsors; 235 Electric propulsion; 568 Maneuvering systems | 1:N | |
| 21X SHAFT DRIVE | (variant choice) | 245 | 1:1 | |
| 21X SHAFT DRIVE + MANEUVERING THRUSTER | (variant choice) | 245 + 568 | 1:N | Thruster booked in 568 (or 237 Auxiliary propulsion devices). **Confirm** |
| 21X ELECTRIC DRIVE | (variant choice) | 235 + 245 | 1:N | Propulsion motor 235, propeller 245 |
| 21X ELECTRIC DRIVE + MANEUVERING THRUSTER | (variant choice) | 235 + 245 + 568 | 1:N | **Confirm** thruster booking |
| 21X WATER JET | (variant choice) | 247 | 1:1 | |
| 21X WATER JET + MANEUVERING THRUSTER | (variant choice) | 247 + 568 | 1:N | **Confirm** thruster booking |
| 21X ABSENT | (variant choice) | — | — | |
| 22X | SHAFTING | 243 Shafting; 244 Shaft bearings | 1:N | |
| 22X MECHANICAL | (variant choice) | 243 + 244 | 1:N | |
| 22X ABSENT | (variant choice) | — | — | |
| 23X | POWER TRANSMISSION | 241 Reduction gears; 242 Clutches and couplings | 1:N | |
| 23X MECHANICAL | (variant choice) | 241 + 242 | 1:N | |
| 23X MECHANICAL WITH POWER TAKEOFF | (variant choice) | 241 + 242; PTO generator → 311 | 1:N | **Confirm** PTO generator booking (ship service generation) |
| 23X ABSENT | (variant choice) | — | — | |

### 300 Electrical

| Model ID | Model name | ESWBS element(s) | Mapping | Notes |
|---|---|---|---|---|
| 300 | ELECTRICAL | 300 | 1:N | |
| 30X | GENERATOR SETS | 311 Ship service power generation; 312 Emergency generators; 342 Diesel support systems | 1:N | |
| 31X | POWER DISTRIBUTION | 321 Ship service power cable; 322 Emergency power cable; 323 Casualty power cable; 324 Switchgear and panels; 314 Power conversion equipment; 331–332 Lighting | 1:N | Lighting (REQ-138) is allocated here |
| 32X | BATTERY | 313 Batteries and service facilities | 1:1 | BESS (REQ-107) |
| 33X | SHORE POWER | 324 Switchgear and panels; 321 Ship service power cable | Partial — **Confirm** | ESWBS has no dedicated shore-power element |

### 400 Command and control

| Model ID | Model name | ESWBS element(s) | Mapping | Notes |
|---|---|---|---|---|
| 400 | COMMAND CONTROL | 400 | 1:N | |
| 40X | NAVIGATION/AIS | 421–428 Navigation aids and systems | 1:N | |
| 41X | RADIO/SATCOM | 441 Radio systems; 443 Visual and audible systems; 444 Telemetry; 445 Teletype and facsimile | 1:N | |
| 42X | CONSOLES | 411 Data display; 412 Data processing; 413–415 Digital data switchboards, interfaces, comms; 431–439 Interior communications (incl. 436 Alarms, 438 Integrated control); 252 Propulsion control system | 1:N | Integrated platform management spans several elements. **Confirm** split |
| 43X | STEERAGE | 561 Steering and diving control systems; 562 Rudder | 1:N | ESWBS books steering in the 500 group |
| 44X | AIR SURVEILLANCE | 452 Air search radar (2D); 453 Air search radar (3D); 455 Identification systems (IFF) | 1:N | |
| 45X | WATER SURVEILLANCE | 451 Surface search radar; 461–464 Sonar | 1:N | **Confirm** scope: surface radar vs. underwater |

### 500 Auxiliary systems

| Model ID | Model name | ESWBS element(s) | Mapping | Notes |
|---|---|---|---|---|
| 500 | AUXILLIARY SYSTEMS | 500 | 1:N | Name typo is hard-coded in scripts |
| 50X | COOLING AND FRESHWATER | 531 Distilling plant; 532 Cooling water; 533 Potable water; 536 Auxiliary fresh water cooling; 514 Air conditioning (chilled water); 516 Refrigeration | 1:N | |
| 51X | LUBE OIL | 262 Main propulsion lube oil system; 264 Lube oil handling; 543 Aviation and general purpose lube oil | 1:N | |
| 52X | FUEL | 261 Fuel service system; 541 Ship fuel and compensating system; 542 Aviation and general purpose fuels; 545 Tank heating | 1:N | ⚠ Collision with ESWBS 520 (Sea water) |
| 52X FUEL | (variant choice) | as 52X | 1:N | |
| 52X ABSENT | (variant choice) | — | — | |
| 520 | FUEL INTAKE/RETURN | 541 | Partial | Fill, sounding, overflow. ⚠ ESWBS 520 = Sea water systems |
| 521 | FUEL STORAGE | 541 (tanks) | Partial | Tank structure itself is hull structure (100). ⚠ ESWBS 521 = Firemain |
| 522 | FUEL TRANSFER | 541 | Partial | ⚠ ESWBS 522 = Sprinkling |
| 523 | FUEL CONDITIONING | 541 (purifiers); 261 | Partial — **Confirm** | ⚠ ESWBS 523 = Washdown |
| 524 | FUEL DISTRIBUTION | 261 Fuel service system | Partial | ⚠ ESWBS 524 = Auxiliary seawater |
| 525 | ME FO PIPING | 261 | Partial | ⚠ No ESWBS 525 element listed |
| 525 ME FO PIPING / 525 ABSENT | (variant choices) | 261 / — | | |
| 526 | GS FO PIPING | 342 Diesel support systems | Partial | ⚠ ESWBS 526 = Scuppers and deck drains |
| 526 GS FO PIPING / 526 ABSENT | (variant choices) | 342 / — | | |
| 527 | MISSION FO PIPING | 542 Aviation and general purpose fuels; 544 Liquid cargo | Partial — **Confirm** | Depends on mission module. ⚠ ESWBS 527 = Firemain-actuated services |
| 527 MISSION FO PIPING / 527 ABSENT | (variant choices) | 542 or 544 / — | | |
| 528 | FO CONTROL | 261; 252 Propulsion control | Partial — **Confirm** | ⚠ ESWBS 528 = Plumbing drainage |
| 529 | FO POWER DISTRIBUTION | 321, 324 | Partial | ⚠ ESWBS 529 = Drainage and ballasting |
| 53X | COMPRESSED AIR | 551 Compressed air systems; 552 Compressed gases | 1:N | ⚠ ESWBS 530 = Fresh water |
| 54X | BALLAST AND SALTWATER | 529 Drainage and ballasting; 524 Auxiliary seawater; 256 Circulating and cooling sea water | 1:N | ⚠ ESWBS 540 = Fuels and lubricants |
| 55X | CARGO/MISSION | 571 Replenishment-at-sea; 572 Stores handling; 573 Cargo handling; 574 Vertical replenishment; 544 Liquid cargo; 588 Aircraft handling; 591 Scientific and ocean engineering; 673 Cargo stowage | 1:N — **Confirm per mission** | Becomes the mission midbody modules (D1). ⚠ ESWBS 550 = Air, gas, misc. fluids |
| 56X | DECK MACHINERY | 581 Anchor handling; 582 Mooring and towing; 583 Boats handling; 589 Misc. mechanical handling; 556 Hydraulic fluid system | 1:N | ⚠ ESWBS 560 = Ship control |
| 57X | WASTE MANAGEMENT | 593 Environmental pollution control systems; 528 Plumbing drainage; 259 Uptakes; 656 Trash disposal spaces | 1:N | ⚠ ESWBS 570 = Underway replenishment |
| 58X | FIRE | 555 Fire extinguishing systems; 521 Firemain; 522 Sprinkling | 1:N | ⚠ ESWBS 580 = Mechanical handling |
| 59X | HOTEL | 511 Compartment heating; 512 Ventilation; 514 Air conditioning; 533 Potable water; 528 Plumbing drainage; 651–655 Service spaces | 1:N | ⚠ ESWBS 590 = Special purpose systems. Overlaps 50X (chilled water, potable water); **Confirm** split |

### 600 Outfitting

| Model ID | Model name | ESWBS element(s) | Mapping | Notes |
|---|---|---|---|---|
| 600 | OUTFITTING | 600 | 1:N | |
| 60X | ACCOMODATION | 641 Officer berthing and messing; 642 Non-commissioned officer berthing and messing; 643 Enlisted berthing and messing; 644 Sanitary spaces; 645 Leisure and community spaces | 1:N | Name typo is hard-coded in scripts |
| 61X | SHOPS | 665 Workshops, labs, test areas; 661 Offices | 1:N | Tender module shops will also map to 665 |
| 62X | LSA | 583 Boats, handling and stowage systems; lifesaving outfit (6xx) | Partial — **Confirm** | Life rafts and lifesaving equipment booking to be confirmed |
| — | *(not modeled)* | 611–613 Hull fittings, rails, rigging; 621–625 Hull compartmentation; 631–639 Preservatives and coverings; 671–672 Lockers and storerooms | — | |

### 700 Weapons

| Model ID | Model name | ESWBS element(s) | Mapping | Notes |
|---|---|---|---|---|
| 700 | WEAPONS | 700 | 1:N | Scope for a sealift vessel is an open question |
| 70X | ASW | 751–753 Torpedo tubes, handling, stowage; 483 Underwater fire control; 461–464 Sonar | 1:N | Sensors are in the 400 group in ESWBS |
| 71X | SS | 711–713 Guns and ammunition; 721–729 Missiles; 481–482 Fire control | 1:N | Surface-to-surface |
| 72X | SA | 721–729 Missiles; 711–713 Guns; 482 Missile fire control | 1:N | Surface-to-air |
| 73X | EW | 471 Active ECM; 472 Passive ECM | 1:N | ESWBS books EW in the 400 group |
| 74X | COUNTERMEASURES | 473 Torpedo decoys; 474 Decoys (other); 475 Degaussing; 476 Mine countermeasures | 1:N | ESWBS books countermeasures in the 400 group |

## Maintaining this document

- Every component in `SYSTEM.slx` (including variant choices and future referenced group and
  mission-module models) must appear here.
- When a component is added or renamed, update this table in the same pull request.
- Planned: an `ESWBS` property on every component, populated from this table, and a test that
  checks the model and this document agree. Weight reports will also roll up by ESWBS group.
