# Spicy TSV

TSV with a some set conventions, and a few extras, that are useful if your data is a little bit more complicated than a flat file, but you want to maintain flat table editing of a spreadsheet to the extent possible.

You can add comments, multiple tables, and add lists or sub-objects to each table entry, but only one extra layer deep, the format is NOT fully recursive or capabable of modelling arbitrarily complex structures.

The intended use case is for hand edited files, manually defining configuration or content for apps and games. After parsing the end result will be similar to having parsed a JSON file containing a list of objects.

## Features ##

### TSV conventions ###

 * use UTF8 files with unix \n line ends
 * cells that contain tabs or new lines should be quoted in double or single quotes
 * when parsing non-quoted cells, data types can *optionally* be converted automatically
   * ie. numbers are parsed as numbers instead of text, and true and false are parsed as booleans
 
### Comment lines ###

Any line that starts with a # is a comment line and is ignore when parsing

### Blank lines ###

Blank lines are ignored while parsing

### Header rows ###

The first non-comment, non-blank line is a header row, that defines the name of each field in each column. The name of each column will be used when converting following rows to something more like objects or maps during parsing.

Header rows can use optional markup to incorporate a sub-list into a row, or a sub-object, or a list of sub-objects.

 * field names enclosed in closed brackets, denote fields that are sub lists, eg. [tags]
 * field names enclosed in curly brackets, denote fields that target properties of a sub object, eg. { image.url }
  * the propery should be split with a dot, between the name of the sub object, and the proerty being defined in this column
 * field names enclodes in closed and curly brackets, denote lists of subobjects, targeting a specific property of those sub objects in this column, eg. [{images.url}]	[{images.alt__text}]
 
### Multiple sections ###

By default the file defines a single table, or list, of objects, but a file can optionally include multiple sections.

To define multiple secitons use a section header at the start of each section, section headers are rows with a single value formatted in angle brackets like this:

&lt;section__name&gt;

Each section header should be followed by the header row of that section. If using named sections, make sure all sections are named, you cannot mix named and unnamed sections in the same file.

See example2.tsv for an example of this in use.

## Example ##

| name | [random_descriptions] | [locations] | [{weapons.name}] | [{weapons.damage}] |
| ---- | ---- | ---- | ---- | ---- |
|Threatening Bear | A threatening bear appears | Forest | claws | 10 |
| | You've woken a very grump bear | River | bite | 15 |
| Angry Beaver | This beaver wants you to leave its river | River | bite | 10 |
| | These rapids are getting rapidly more dangerous as an angry beaver appears |  |  |  |
| | Knock knock, whose there? BEAVER! |  |  |  |
| Tiger | Tiger Tiger Burning Bright Right NOW! | Forest | claws | 10 |
| | Surprise, it is I, a Tiger |  | bite | 15 |
| Tourist | Oh no, its people | Forest | complaint | 5 |
| |  | River | litter | 25 |
| |  | Plains | pollution | 50 |
| |  | Town |  |  |

## Implementation ##

It's really just a set of conventions, but a reference Lua implementation is included, that demonstrates converting two supplied example files into equivalent JSON.

