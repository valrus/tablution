Tablution
=========

Tablution is a sort-of clone—written in pure Cocoa/Objective-C—of the venerable [eTktab](http://etktab.sourceforge.net/) tablature editor, itself apparently based on emacs [tablature mode](https://encrypted.google.com/url?sa=t&rct=j&q=emacs%20guitar%20tablature%20mode&source=web&cd=2&ved=0CFQQFjAB&url=http%3A%2F%2Fwww.maths.tcd.ie%2F~gfoster%2FGuitar%2FPrograms%2FTab-n-Fret%2Ftablature-mode.el&ei=bmbVT_vnB4fY2QWTmoyoDw&usg=AFQjCNGG2M4-6810YwCO8wowyzKNpQ-0QQ). Despite that the mechanisms for editing come from emacs, they are very vim-like: many tasks can be accomplished in just a few keystrokes, and eTktab is even modal in a way. I have tried, I think, most of the available tab editors for the Mac; all of them seem to be either overpriced for a hobbyist or poor at rapid tab entry. Tablution aims to fill the gap left by the available options.

While I think eTktab's input paradigm and price point are superior to those of other tab editors, no one, least of all Mac users, would call it pretty; further, considering its slapdash tcl/tk wrapper port and general unmaintainedness, I'd be surprised if it even runs on recent iterations of OS X. I am not a seasoned UX engineer so my initial steps will be to try to replicate eTktab's functionality completely in Cocoa. By the time I'm finished with that, hopefully I will have some ideas for how to improve on it.

Currently, and for the foreseeable future, Tablution only runs on OS X 10.7 and up. I'm using the newly introduced ARC (Automatic Reference Counting) and don't intend to backport to OSs that don't have it. This project is purely a hobby, I won't end up doing it if it's not fun, and going back to manual memory management isn't my idea of a good time.

Tablution is very obviously a work in progress, barely even fit to be called "pre-alpha" at this point. That said, as of this writing I am able to use it for basic tab editing, including saving, loading and an undo stack.
