# CEE 492 Final Report Document

## To write the report in VS Code

1. Click on the "Extensions" item (which looks like four boxes, with one of the boxes at an angle) in the panel on the left side of the VS Code window.
2. Search for "tinymist" in the extensions marketplace search bar to the top left part of the window.
3. "Tinymist Typst" should be one of the top options that come up. Click on it and click install.
4. Now click on the "Explorer" item (which looks like two files stacked on top of each other) in the panel on the left side of the VS Code window.
5. Open the file named "cee492_report.typ"
6. Type Control (or Command) + Shift + P to get the VS Code "Command Palette"
7. Search for and run the command "Typst Preview: Preview Opened File"
8. The preview should automatically update as you edit the file. (This won't work in the prairielearn workspace version of VS Code, however.)
9. If it's not working, click on the "Problems" tab in the menu at the bottom of VS Code, which will show any errors encountered while trying to render the document, as well as typos and things like that.

For detailed information about report formatting, refer to https://typst.app/docs/reference.

## To download the report:

1. Go to the [github actions results page](../../actions/workflows/build.yml).
2. Click on the top link under the part of the page that says "Render Report".
3. Click the link that says "cee492_report.pdf" under the section that says "Artifacts"

A new build starts every time you push. You can also start one yourself without pushing: on the [github actions results page](../../actions/workflows/build.yml), click "Run workflow".
