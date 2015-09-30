# Python Tools

[![Build Status](https://travis-ci.org/MichaelAquilina/python-tools.svg?branch=master)](https://travis-ci.org/MichaelAquilina/python-tools)
[![Build Status Windows](https://ci.appveyor.com/api/projects/status/jnu90b2bgqar87es/branch/master?svg=true)](https://ci.appveyor.com/project/MichaelAquilina/python-tools)

Some handy tools to make developing Python code in Atom even more enjoyable.

Goes along really nicely with the [autocomplete-python](https://atom.io/packages/autocomplete-python) package to provide a full Python IDE experience in Atom.

## Details

This package uses [Jedi](https://pypi.python.org/pypi/jedi) in addition to other custom code to provide numerous pieces of functionality to make you more productive:

### Show Usages
Default shortcut: `ctrl+alt+u`

![demo](http://i.imgur.com/coOlBn7.gif?1)

Select the usages of a specific symbol in your file.

This is particularly handy for quickly refactoring/renaming variables and other symbols within your code.

Currently only supports detection of symbols within the same file. This will be extended to support usages outside the current file in the future.

### Goto Definition
Default shortcut: `ctrl+alt+g`

![demo](http://i.imgur.com/iXHY7HE.gif?1)

Go to to the original definition of the symbol under the cursor. This will open the corresponding file if it is not already open.

Files which form part of the standard library / are installed as third party modules are still opened, which is a really nice way of analysing and understanding behavior of code.

### Select String Contents
Default shortcut: `ctrl+alt+e`

![demo](http://i.imgur.com/tUeduTK.gif?1)

Select the entire contents of the string currently being selected.

Works with single line as well as block strings.

#### More tools to come?
Ideas and feature requests are welcome. Some ideas of potential features to be added:
* Swap string delimiters between ' and "
* Show usages and provide the ability to rename across multiple files
* Select entire symbols

## Windows Support
Windows should work, however I do not have access to a Windows machine and cannot therefore test out releases.

I have builds being tested on appveyor which should prevent any obvious errors from causing breakages. I have now also setup a virtual machine to test changes, but a lot of the issues that I would catch through normal day to day usage will not be found and I'll have to rely to the community to make me aware of them.

If you have any issue running this package on windows then please open an [Issue](https://github.com/michaelaquilina/python-tools/issues).

Common Problem: "python-tools was unable to find your machine's python executable"
* Make sure python is installed on your machine (jedi is used internally which runs off python)
* Make sure your python executable is added to your PATH environment variable

## Work In Progress

This Atom package is very much a Work In Progress and is far from currently being perfect! There are a lot of things I will be looking to improve.

If you find anything which does not seem like expected behavior or have any suggestions, feel free to open an [Issue](https://github.com/michaelaquilina/python-tools/issues) on my Github page.
