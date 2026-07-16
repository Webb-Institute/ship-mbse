# Glossary

Terms and abbreviations used throughout the ship-mbse project.

| Term | Definition |
|------|------------|
| MBSE | Model-Based Systems Engineering |
| TODO | Add terms as the model develops |

## Identification Numbers

Every compenent of the MBSE Project is identified with a Identification Number of the form XXX_XXX
Where the first three characters are letters refering to the Ship, Stakeholders and Environment, and
the last three charaters are numbers refering to a specific component.

The letter identification may be any of the following:

| Abbreviation | Definition |
|------|------------|
| SHP | Ship |
| STK | Stakeholders |
| ENV | Environment |


The number identification will fall into the following categories:

| Series | Definition |
|------|------------|
| 100 | Hull Structure |
| 200 | Propulsion Plant |
| 300 | Electric Plant |
| 400 | Command and Serveillance Systems |
| 500 | Auxiliary Systems |
| 600 | Outfit and Furnishings |
| 700 | Armament |

The specific identification numbers are as follows:

| Number | Definition |
|------|------------|
| 10X | Plate |
| 11X | Framing |
| 12X | Stiffeners |
| 20X | Main Engine |
| 21X | Propulsors |
| 22X | Shafting |
| 23X | Power Transmission |
| 30X | Generator Sets |
| 31X | Power Distribution |
| 32X | Battery |
| 33X | Shore Power |
| 40X | Navigation / AIS |
| 41X | Radio / SATCOM |
| 42X | Consoles |
| 43X | Steerage |
| 44X | Air Surveillance |
| 45X | Water Surveillance |
| 50X | Cooling and Freshwater |
| 51X | Lubrication Oil |
| 52X | Fuel Oil |
| 53X | Compressed Air |
| 54X | Ballast and Saltwater|
| 55X | Cargo / Mission |
| 56X | Deck Machinery |
| 57X | Waste Management |
| 58X | Fire System |
| 59X | Hotel System |
| 60X | Accomodations |
| 61X | Shops |
| 62X | Lifesaving Appliances |
| 70X | Anti-Submarine Warfare |
| 71X | Surface to Surface Warfare |
| 72X | Surface to Air Warfare |
| 73X | Electronic Warfare |
| 74X | Coutermeasures |


 ## Model Nomenclature

Systems used to refer to model elements in the System Composer Model. 

Each connection and port are labled in such a way as to convey specific 
information regarding the path, type, and contents of the connection. Physical
connections and ports are labled as ##X-##X, where the first half refers to
the source or upstream system and the later the downstream component. For 
example, given AAX-BBX, component AAX supports or drives BBX. This still holds
true for non-physical connections; the first component before the dash is the 
source. Signal connections are used to represent every other type of dependency besides 
physical attachements. Unlike physical connections, signal connections representing 
dependency or a flow of mass, power, or information are always followed by a tag 
that describes the interface within the connection. The label for non-physical connections is
##X-##X$$$, where $$$ is the tag describing the nature of the flow. 

A table of tags currently in use and their definitions is below. 

 | Tag | Definition | Data Type |
|------|------------| ---------|
| C | Control | Information |
| CA | Compressed Air | Mass | 
| CFW | Cooling Fresh Water | Mass |
| FO | Fuel Oil | Mass |
| LO | Lube Oil | Mass |
| P | Power | Electrical Power |
| SW | Salt Water | Mass |
| WG | Waste Gas | Mass |
| WS | Waste Solid | Mass |
| WW | Waste Water | Mass |