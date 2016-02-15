DarkStar headlamp
=================

Small, lightweight and waterproof LED headlamp with two Cree XP-G2 leds. Can be
used in biking, caving, mine exploration, hiking... But **always** carry a
**backup** light source.

Features
--------
* Two 5W Cree XP-G LEDs with independently controlled brightness
* Up to 916lm (is using cool white LED), software cropped to about 600lm to reduce heat generation
* Always on LED with spread beam to illuminate surroundings
* One wide beam (115 degrees) LED to illuminate long tunnels, big caves, etc.
* Small red status LED, can be replaced with UV or used as emergency light when the battery is almost dead (required swapping one resistor)
* Controlled by PIC 16F616 MCU (source code included)
* Low power off current (TODO uA), no need to unplug battery during power off state
* Waterproof aluminium body
* 3D printed battery box (hopefully waterproof) for two 18650 cells
* Whole headlamp including batteries weights only TODO grams

Controls
--------
* Connect headlamp to battery, LEDs will flash and device goes to sleep
* Press and hold up button for about 2 seconds, first LED turns on
* Use up/down buttons to increase/decrease LEDs intensity
* Press and hold down button for about 2 seconds to turn on/off second LED
* When the second LED is on, use up/down buttons to control its intensity
* Press and hold up button for about 2 seconds to turn the lamp off

Warning
-------
LiIon cells can catch fire or explode if not handled properly. The hardware
design has not been extensively tested, the headlamp could die any time, don't
rely on it as a single source of light.

License
-------
This headlamp is provided under opensource license WITHOUT ANY WARRANTY, see
[LICENSE](./LICENSE) for more details.

HowTo
-----
* **cad** directory contains body designs in FreeCad
* **pcb** contains all kicad files including BillOfMaterials for electronics,
	please note plated vias under Cree LEDs are required to move heat from
	LED to heatsink (body). Gerber files for manufacturing are included
* **pic** contains assembly source code for the headlamp MCU
