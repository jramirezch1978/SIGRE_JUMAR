DW2XLS 4.0 release notes.

New features in 4.0
- Added support for the new Excel file format, OOXML (XML based Excel 2007 format)
  Set parm.is_version = "OOXML"
  Default is still 97.

- Added support for rectangles and solid lines (only vertical and horizontal). 
  Set parm.ib_lines and parm.ib_rectangles.
  These objects are emulated using slim cells. 

- Added support for band background color and color expressions

- Added support for exporting more than one datawindow on a single sheet
  See doc/multidwexample.htm

- Overlapping objects are trimmed so that they do not overlap

- Grid column's header is not exported anymore if the column is hidden


Known issues.
These issues will be fixed in future releases.
- Size of resulting cells is not exactly the same as in the original DW,
  but the proportion is preserved (this comes from 2.X).
- SlideLeft, SlideUp are not supported yet.
- If a line or a rectangle is too close to another cell, then it may be 
  displayed not properly in Excel.
- When exporting to OOXML format, inserting pictures is not yet supported.



