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

* Clicking crossover: if a crossover is left-clicked while m is pressed, then the backbone rotation angles and anchors of the two helices connected by the crossover will be adjusted to point them at each other at their respective offsets.

* Ctrl and Shift: pressing these enables one to select objects, either by left-clicking on them individually, or by "click-and-drag". 
If Shift is pressed, then the objects touched are selected. 
If Ctrl is pressed, then the object selections are toggled (i.e., unselected if they were selected before).

* Esc: If helices are selected, this unselects all of them. Note that unlike other interactive applications, items are not deselected when you left-click elsewhere. This helps to avoid accidentally unselecting many items when using the cursor for other tasks such as panning.

## Edit modes

These are not very well-defined yet. The general idea is to toggle an edit mode by clicking it on the right side, or pressing the keyboard shortcut. 

* w: This shows mouseover data when the cursor is positioned over a helix or crossover in the main view. The backbone rotation angle of the two strands on the helix is shown in the side view, and the information about the helix and (if present) DNA strand is shown in the footer. Furthermore, while this is enabled, clicking on a crossover can alter the backbone rotation of the two helices it connects to point them at each other.


## Exporting SVG

Exporting the design to SVG is currently not directly supported. However, by installing the Chrome extension
[Export SVG with Style](https://chrome.google.com/webstore/detail/export-svg-with-style/dkjdcaddoplepioppogpckelchefhddi),
you can export it yourself:


Add the extension, then restart scadnano (press F5 button to refresh the page), and after loading the design you want to export to SVG, click the Export SVG Button.
It will report that there are two SVG elements on the page.
These are the side view and main view, respectively, and the extension will save both of them.