---
title: "scadnano help"
---

[scadnano](https://web.cs.ucdavis.edu/~doty/scadnano2) 
("***S***criptable-cadnano") 
is a program for designing synthetic DNA structures such as DNA origami. 
Its design is based on [cadnano](https://cadnano.org/), 
specifically [version 2](https://github.com/douglaslab/cadnano2), 
with two main differences: 

1) It runs entirely in the browser, with no installation required.
2) scadnano designs, while they can be edited manually in scadnano, can also be created and edited by a Python scripting library ([download](https://github.com/UC-Davis-molecular-computing/scadnano-python-package)/[documentation](./docs/)), to help automate tedious tasks.

A secondary goal is that the file format should be easily readable, to help when debugging scripts.

This document does not assume any familiarity with cadnano, 
although some parts explain slight differences between cadnano and scadnano for the benefit of those who have used cadnano.



## Terms

The main parts of the program are the *side view* on the left, and the *main view* on the right.
The side view shows DNA helices "head on", with the interpretation that as you move left-to-right in the main view, this is like moving "into the screen" in the side view.

![screenshot](doc-images/screenshot-initial-marked-up.png)

The screenshot above shows many of the terms used in scadnano.


TODO: 5'/3' ends, strands, substrands, loopouts, helix rotations and anchors, etc.

## Menu

* **Export DNA:**
Exports a file containing DNA sequences. A few defaults are available, but it is not very configurable. For more advanced control, the Python scripting package can be used to customize how DNA sequences are exported.

* **Save:**
Saves the current design in a .dna file. This is the same format output by (and readable by) the Python scripting package.

* **Load:**
Loads a .dna file. Note that due to browser security restrictions on accessing the local file system it is not possible for a changed design to be automatically loaded. This precludes the possibility of repeatedly re-running a local Python script and seeing the changed design immediately re-loaded in the browser; the Load button must be clicked and a local file selected whenever you wish to re-load the file.

* **show DNA:**
Shows any DNA sequences that have been assigned to the strands. For large designs (e.g., DNA origami using a > 7000-base scaffold), it can take a long time to render the DNA and slow down panning and zooming. Thus, it is recommended to uncheck this option most of the time unless actually inspecting the DNA sequences. Hopefully implementing [this feature request](https://github.com/UC-Davis-molecular-computing/scadnano/issues/30) will reduce the rendering time.

* **show mismatches:**
Shows DNA base pair mismatches. When assigning DNA sequences, the default is to assign a specified DNA sequence to one strand and to automatically assign the complement to any strands bound to it, which would result in no mismatches. However, using the Python scripting library (and this will be supported in the future in the web interface) it is possible to manually assign DNA sequences independently to strands without automatically assigning the complement to bound strands. This allows intentional mismatches to be placed in the design.

## Edit modes

There are different edit modes available, shown on the right side of the screen. Currently most of them are mutually exclusive, so selecting one will unselect the others. However, a few can be on simultaneously.

* **Select:**
This is similar to the Select edit mode in cadnano. It allows one to select one or more items and delete, move, or copy/paste them. Which are allowed to be selected depends on the "Select Mode", shown below the Edit modes. Some of these are mutually exclusive as well.

  - **5' end (strand), 3' end (strand):**
  These allow one to select the 5' end (square) or 3' end (triangle) of a whole strand. 

  - **5' end (other), 3' end (other):**
  Each strand is composed of one or more *bound substrands*, defined to be a portion of a strand that exists on a single helix. A 5'/3' end of a bound substrand that is not the 5'/3' end of the whole strand is one of these. They are not normally visible, but when these select modes are enabled, they become visible on mouseover and can be selected and dragged. An important note is that bound substrands cannot be selected, but anything one would want to do with them can be done via their ends. Deleting a 5'/3' end of a bound substrand deletes the whole bound substrand. To move the whole bound substrand, simply select both of its ends and move them.

  - **crossover, loopout:**
  Two consecutive bound substrands on a strand can be joined by either a *crossover*, which consists of no DNA bases, or a *loopout*, which is a single-stranded portion of the strand with one or more DNA bases.[^1] 

  - **strand:**
  The whole strand can be selected.

  - **scaffold/staple:**
  In the case of a DNA origami design---one in which at least one strand is marked as a *scaffold*---all non-scaffold strands are called *staples*. This option allows one to select only scaffold strands/strand parts, only staples, or both.
  
  

* Clicking crossover: if a crossover is left-clicked while backbone mode is enabled, then the backbone rotation angles and anchors of the two helices connected by the crossover will be adjusted to point them at each other at their respective offsets.

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


  [^1]: Technically bound substrands do not have to be bound to another strand, but the idea is that generally in a finished design, most of the bound substrands will actually be bound to another. However, currently it is [unsupported](https://github.com/UC-Davis-molecular-computing/scadnano/issues/34) for a strand to begin or end with a loopout, so single-stranded bound substrands are currently necessary to support single-stranded extensions on the end of a strand.
