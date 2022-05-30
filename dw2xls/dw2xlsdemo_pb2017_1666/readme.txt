DW2XLS 5.1 release notes.

New features in 5.1
- Supported 64-bit applications.
- Supported TreeView DW.
- Supported .NET WinForms deployments.
- Supported Appeon deployments (with additional license fee. Visit www.desta.com.ua/dw2xls).

Known issues.
- Size of resulting cells is not exactly the same as in the original DW,
  but the proportion is preserved (this comes from 2.X).
- SlideLeft, SlideUp are not supported yet.
- If a line or a rectangle is too close to another cell, then it may be 
  displayed not properly in Excel.
- Pictures are supported only for OOXML (XLSX-files) format.
- Sometimes in resulting Excel-file space between text lines inside multiline cell is greater than it was in PowerBuilder.
- Expressions with case() without "else" are not supported.
- .NET WebForm deployments are not supported



