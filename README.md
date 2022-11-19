# Move-TODOBlocks
![TODO-Blocks Logo](/Pictures/TODOBlocks-Logo.png?raw=true "TODO-Blocks Logo")


Move-TODOBlocks saves TODO block comments to a TODO.shelf file, and moves TODO block comments from a TODO.shelf back to source code. 


------------------------------------------------------------------------------------------------------------------------
TODO Block comment example:


`\\ TODO: A TODO block is a comment that starts with the todo keyword and ends with the todo keyword :TODO`


------------------------------------------------------------------------------------------------------------------------
Shelving example:


`.\Move-TODOBlocks.ps1 -Path "X:\SourceCodeRootDir" -Shelve` 


------------------------------------------------------------------------------------------------------------------------
Unshelving example:


`.\Move-TODOBlocks.ps1 -Path "X:\SourceCodeRootDir" -Unshelve` 
