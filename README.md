# Move-TODOBlocks


![TODO-Blocks Logo](/Pictures/TODOBlocks-Logo.png?raw=true "TODO-Blocks Logo") 



<br><br><div align="center">
Move-TODOBlocks is an organization tool!
</div><br><br>

## What is a TODO Block comment?
A TODO Block comment is a double-slash `\\` comment that starts with `TODO:` and ends with `:TODO`<br><br>

![TODO-Blocks example](/Pictures/TODOBlock-example.png?raw=true "TODO-Blocks example")
<br><br>

## Move-TODOBlocks.ps1 Work Flow
The work flow of Move-TODOBlocks is to add TODO Block comments to your source code. Then when you shelve those TODO Block comments into a **TODO.shelf**. Then after the commit/push you unshelve the TODO Block comments.<br><br>

![Move-TODOBlocks work flow](/Pictures/Move-TODOBlock-flow.png?raw=true "TODO-Blocks work flow")
<br><br>

### Shelving example:
In the PowerShell terminal you can run the script with the `-Shelve` flag to shelve your TODO blocks. 

`PS> .\Move-TODOBlocks.ps1 -Path "X:\SourceCodeRootDir" -Shelve`
<br>
### Unshelving example:
In the PowerShell terminal you can run the script with the `-Unshelve` flag to unshelve your TODO blocks.

`PS> .\Move-TODOBlocks.ps1 -Path "X:\SourceCodeRootDir" -Unshelve`
