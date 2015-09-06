# python-tools package

[![Build Status](https://travis-ci.org/MichaelAquilina/python-tools.svg)](https://travis-ci.org/michaelaquilina/python-tools)
[![Build Status Windows](https://ci.appveyor.com/api/projects/status/jnu90b2bgqar87es?svg=true)](https://ci.appveyor.com/project/MichaelAquilina/python-tools)

Some handy tools to make developing python in Atom even more enjoyable. Goes along really nicely with the [python-autocomplete](https://atom.io/packages/autocomplete-python) package to provide a full python IDE experience in Atom.

![Demo](http://i738.photobucket.com/albums/xx27/Michael_Aquilina/output_zps4qx1snfe.gif)

Uses [Jedi](https://pypi.python.org/pypi/jedi) internally to provide the following functionality:
- **Show usages**: select the usages of a specific symbol in your file.
- This should allow you to quickly refactor/rename variable within your code.
- **Goto definition**: goto to the original definition of the symbol under the cursor.
- This will open any corresponding files if they are not already open (even if they form part of the standard library / are installed as a third party module)
- More to come?

## Windows Support
Windows should work, however I do not have access to a Windows machine and cannot therefore test out releases (at least currently). If you have any issue running this
package on windows then you should open an [Issue](https://github.com/michaelaquilina/python-tools/issues).

## Work In Progress

This Atom package is very much a Work In Progress and is far from currently being perfect! There are a lot of things I will be looking to improve.

If you find anything which does not seem like expected behavior or have any suggestions, feel free to open an [Issue](https://github.com/michaelaquilina/python-tools/issues) on my Github page.
