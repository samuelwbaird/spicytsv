# Spicy TSV

TSV with just a few extras, when you want a bit more than a flat TSV but JSON or YAML is too much.

This is useful if your data is a little bit more complicated than a flat file, but you want to maintain the straight forward user friendly table editing of a spreadsheet to the extent possible.

You can add comments, multiple tables, and add lists or subobjects to each table entry, but only one extra layer deep, the format is NOT fully recursive or capabable of modelling arbitrarily complex structures.

The intended use case is for hand edited files, manually defining configuration or content for apps and games.

## Features ##

 * Comment lines
 * Blank lines are used to separate multiple sections
 * Each section has its own header row, defining the field names, so multiple tables can be included in one sheet
 * Entries can include list fields, and sub-objects

## Spec ##


## Example ##


## Implementation ##

A reference Lua implementation is included. It takes a string of the entire

