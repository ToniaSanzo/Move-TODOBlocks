  <#
  .SYNOPSIS
  Shelves and unshelves TODO comment blocks in source code.

  .DESCRIPTION
  Has the option to shelve and unshelve TODO comment blocks from source code. 

  The process of "shelving" involves removing properly formatted TODO blocks in
  source code and saving the TODO blocks in a [generated] TODO.shelf. 

  The process of "unshelving" involves restoring TODO blocks saved in a 
  [generated] TODO.shelf back to source code. 

  .PARAMETER Path
  Path to the source code root directory.

  .PARAMETER Unshelve
  Use this switch when you intend to unshelve a [generated] TODO.shelf.

  .PARAMETER Shelve
  Use this switch when you intend to shelve TODO blocks in source code.

  .PARAMETER Path
  The path to the root directory of the source code.

  .INPUTS
  None. You cannot pipe objects to Move-TODOBlock.ps1.

  .OUTPUTS
  None. Move-TODOBlock.ps1 does not generate any output.

  .EXAMPLE
  PS> .\Move-TODOBlock.ps1 -Path "C:/Sandbox/src" -Shelve
  < Shelve TODO comment blocks in the "C:/Sandbox/src" in a TODO.shelf file. >

  .EXAMPLE
  PS> .\Move-TODOBlock.ps1 -Path "C:/Sandbox/src" -Unshelve  
  < Unshelve TODO comment blocks in a TODO.shelf in"C:/Sandbox/src". >  
#>
#------- Parameters ------------------------------------------------------------
param (
  #"[-Path -P] : Path to the source code root directory."
  [Alias("P")]
  [string]$Path,

  #"[-Shelve -S] : Shelve the TODO blocks."
  [Alias("S")]
  [switch]$Shelve,
  
  #"[-Unshelve -U] : Unshelve the TODO blocks."
  [Alias("U")]
  [switch]$Unshelve,

  #"[-Help -H] : Invokes Get-Help response."
  [Alias("H")]
  [switch]$Help
)

#------- Variables -------------------------------------------------------------
[String] $TODOBlockStart = "TODO:"
[String] $TODOBlockEnd   = ":TODO"
[String] $ShelfFile      = "TODO.shelf"

#------- Functions -------------------------------------------------------------
# Handles if a non-standard help argument is passed to the script.
function Assert-Help {
  param ([String]$ThisScriptPath)
  
  # Throw an error if $ThisScriptPath is invalid.
  if (-not (Test-Path $ThisScriptPath)) {
    Write-Error (
      -join (
        "Missing argument in Assert-Help function call, call with path to this",
        " script. For example `"Assert-Help `$MyInvocation.MyCommand.Source`"."
      )
    )
    exit 4911
  }

  if ($Help) { Get-Help $ThisScriptPath; exit 0 }
}

function Assert-NoTODOShelf {
  Get-ChildItem -Path $Path | ForEach-Object {
    $FileName = $_
    if ($FileName.Name -eq $ShelfFile) {
      Write-Error (
        -join (
          "${ShelfFile} already exists, manually delete ${FileName} ",
          "if you would like to create a new ${ShelfFile}. Warning the TODO ",
          "comment blocks saved in ${FileName} will be lost if you delete it."
        )
      )
      exit 6855
    }
  }
}

function Assert-ValidTODOBlocks {
  Assert-NoTODOShelf
  [string[]] $TODOShelfContent
  [Bool]     $InTODOBlock = $false

  # For every file in $Path.
  Get-ChildItem -Path $Path | ForEach-Object {
    $FileName    = $_
    $FileContent = Get-Content $FileName
    
    $LineNumber  = 1
    $TODOStartLineNumber = $LineNumber
    foreach ($Line in $FileContent) {
      if ($InTODOBlock) {
        if(-not ($line -match "^[ ]*//")) {
          Write-Error (
            -join (
              "Expected double slash comments `'//`' on line (${lineNumber}) ",
              "in TODO comment block."
            )
          )
          exit 8478
        }
        $TODOShelfContent
      }

      if ($line -match "^\s*//\s*TODO:")
      {
          if(-not $inTODO)
          {
              $inTODO = $true
              $TODOStartLineNumber = $linenumber
          }
      }

      $LineNumber++
    }
  }
}

#------- Script Body -----------------------------------------------------------
Assert-Help $MyInvocation.MyCommand.Source
$Shelve = $true
if ($Shelve -and $Unshelve) {
  Write-Error "The -Shelve and -Unshelve flags can not be used simultaneously."
  exit 7769
}

if (-not $Path) {
  $Path = $PWD
}

if ($Shelve) {
  Save-TODOBlocks
}

