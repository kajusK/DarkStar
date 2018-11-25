New version!
============

There's a whole new version with mutch more features and power:
https://github.com/kajusK/Darkstar-Mk.II/


DarkStar headlamp
=================

Small, lightweight and waterproof LED headlamp with two Cree XP-G2 leds. Can be
used in biking, caving, mine exploration, hiking... But **always** carry a
**backup** light source.

![Top side](./images/box.jpg)

Features
--------
* Waterproof aluminium lamp body
* Lightweight - whole headlamp, including two 18650 batteries, weights 220 grams
* Two 5W Cree XP-G2 LEDs with independently controlled brightness
* Always on LED with wide (115 degrees) beam to illuminate surroundings
* One narrow beam (10 degrees) LED to illuminate long tunnels, big caves, etc.
* Real Lab-measured light output is over 200lm (ebay value, based only on LED datasheet, would be over 600lm), see [Measurement](./Measurement.md) for more details
* Small red status LED (can be replaced by UV LED, etc.)
* Controlled by PIC 16F616 MCU (source code included)
* Low power off current (3,2 uA), no need to unplug battery during power off state
* Low power mode when battery is almost dead (single LED on lowest power, ~40mA)
* Long run time (up to 110 hours on lowest power (~40mA), over 24 hours on reasonable walking power (~150mA))
* 3D printed waterproof battery box for two 18650 Li-Ion cells

![Top side](./images/waterproof.jpg)

Weight
------
* Lamp head: 80g
* Battery box: 45g
* 2x18650 battery pack: 96g

Controls
--------
* Connect headlamp to battery, LEDs will flash and device goes to sleep
* Press and hold up button for about 2 seconds, first LED turns on
* Use up/down buttons to increase/decrease LEDs intensity
* Press and hold down button for about 2 seconds to turn on/off second LED
* When the second LED is on, use up/down buttons to control its intensity
* Press and hold up button for about 2 seconds to turn the lamp off

![Helmet](./images/helmet.jpg)

Warning
-------
Li-Ion cells can catch fire or explode if not handled properly. The hardware
design was NOT extensively tested, the headlamp could die any time, don't
rely on it as a single source of light.

The headlamp body can get quite hot if both LEDs are running on full power,
there's no thermal protection, **you have been warned**.

![Body](./images/battery.jpg)

License
-------
This headlamp is provided under open source license WITHOUT ANY WARRANTY, see
[LICENSE](./LICENSE) for more details.

HowTo
=====
Directories
-----------
* **cad** headlamp body and battery box design (FreeCad)
* **pcb** contains all kicad files including BillOfMaterials for electronics,
	please note plated vias under Cree LEDs are mandatory to move heat from
	LED to heatsink (body). Gerber files for manufacturing are included.
* **pic** contains assembly source code for the headlamp MCU

Electronics & software
----------------------
For overview how the hardware works, check
[microchip application note](http://ww1.microchip.com/downloads/en/AppNotes/00874C.pdf)
and [source code README](./pic/README.md).

To reduce manufacturing costs, the heat from CREE LEDs is transferred to aluminium
body using several plated vias under the LED itself thus avoiding the need for
aluminium PCB or big star heat sink for each LED. For some math background, check
the [Cree thermal management guide](http://www.cree.com/~/media/Files/Cree/LED%20Components%20and%20Modules/XLamp/XLamp%20Application%20Notes/XLamp_PCB_Thermal.pdf).

Power wires are soldered directly to the PCB. To program the MCU, solder
wires to ICSP pins or build some kind of pin-touch interface. Use *make* in
pic directory to compile the sources (assuming you are running Linux),
you can use *make burn* to upload the firmware using pickit2.

Lenses
------
The wide beam LED can be used without lenses, the beam is wide enough for my
needs, for the narrow beam LED you can buy any compatible lens (it will require
some modifications due to limited space on PCB though). I used [17mm 10deg lens]
(http://www.aliexpress.com/item/Free-shipping-cree-xp-g-lens-Diameter-17mm-Smooth-surface-with-stand-Condenser-lenses-10-deg/777222733.html)

![Body](./images/bare.jpg)

Body
----
The body is made from a piece of aluminium *6082 T6* using a small lathe. The top
cover is made from plexiglass taken from old diving goggles. Waterproofness is
ensured by big O-ring between body and glass and two small O-rings on the
control knob. The body works also as a heat sink for LEDs, therefore it cannot
be made from plastic (e.g. on 3D printer).

The battery box is printed on 3D printer from ABS (I would rather use aluminium,
but I don't have access to milling machine).

See [Bill of Materials](./BOM.md).

![Headlamp body](./images/body.jpg)
