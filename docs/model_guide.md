# Model Guide

Explains how the System Composer model in `model/system_composer/` is organized,
including architecture views, requirements linkage, and profiles.

## Contents

- Architecture overview
- Naming conventions
- How requirements are linked to model elements
- How profiles/stereotypes are used
- Exported views and when to regenerate them


## Architecture Overview

At the highest level the Architecture consists of the Ship, the Environment
and the Stakeholders. This model primarily focuses on representing the ship
and its major components and subsystems. The major ship systems are broken down
following SWBS within the ship component. The major ship systems are given  
numbers 100-700 increasing by 100 at a time. They are broken down further into 
major subsystems, which possess the hundreds digit of their parent system and
their own unique tens digit. The last digit in all subsystems is replaced by an X.
This is so that subsystems can be added later for greater model accuracy without
necessitating drastic changes to the architecture. For an understanding of the
specific numerical codes and their meanings, as well as a breakdown of the information
contained within the tags on each connection, please see the glossary. It should be noted that
the model was designed at the current level for generality and simplicity. For example, hydraulic
systems are assumed to be local components within sub systems that utilize them, not an independent s
system.

