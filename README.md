---
title: "scadnano help"
---

[scadnano](https://web.cs.ucdavis.edu/~doty/scadnano2) 
("**s**criptable-cadnano") 
is a program for designing synthetic DNA structures such as DNA origami. 
Its design is based on [cadnano](https://cadnano.org/), 
specifically [version 2](https://github.com/douglaslab/cadnano2), 
with two main differences: 

1. It runs entirely in the browser, with no installation required.
2. scadnano designs, while they can be edited manually in scadnano, can also be created and edited by a Python scripting library ([documentation here](./docs/)), to help automate tedious tasks.

This document does not assume any familiarity with cadnano, 
although some parts explain slight differences between cadnano and scadnano for the benefit of those who have used cadnano.



## Terms

The main parts of the program are the *side view* on the left, and the *main view* on the right.
The side view shows DNA helices "head on", with the interpretation that as you move left-to-right in the main view, this is like moving "into the screen" in the side view.

TODO: 5'/3' ends, strands, substrands, loopouts, helix rotations and anchors, etc.



## Keyboard and mouse/touchpad

Some features of scadnano are enabled by depressing a certain key while using the mouse/touchpad:

* m: This shows mouseover data when the cursor is positioned over a helix or crossover in the main view. The backbone rotation angle of the two strands on the helix is shown in the side view, and the information about the helix and (if present) DNA strand is shown in the footer. When pressed over a crossover, information for the two helices it connects is shown.

* Clicking crossover: if a crossover is left-clicked while m is pressed, then the backbone rotation angles and anchors of the two helices connected by the crossover will be adjusted to point them at each other at their respective offsets.

* Ctrl and Shift: pressing these enables one to select objects, either by left-clicking on them individually, or by "click-and-drag". 
If Shift is pressed, then the objects touched are selected. 
If Ctrl is pressed, then the object selections are toggled (i.e., unselected if they were selected before).

* h: In the side view, this allows one to add or remove helices by left-clicking.

* Esc: If helices are selected, this unselects all of them.


## Exporting SVG

Exporting the design to SVG is currently not directly supported. However, by installing the Chrome extension
[Export SVG with Style](https://chrome.google.com/webstore/detail/export-svg-with-style/dkjdcaddoplepioppogpckelchefhddi),
you can export it yourself:


Add the extension, then restart scadnano, and after loading the design you want to export to SVG, click the Export SVG Button.
It will report that there are two SVG elements on the page.
These are the side view and main view, respectively, and the extension will save both of them.