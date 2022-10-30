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
  [Parameter(Mandatory=$true,
    ParameterSetName = "Default")]
  [Alias("P")]
  [string]$Path,

  #"[-Shelve -S] : Shelve the TODO blocks."
  [Parameter(Mandatory=$false,
    ParameterSetName = "Default")]
  [Alias("S")]
  [switch]$Shelve,
  
  #"[-Unshelve -U] : Unshelve the TODO blocks."
  [Parameter(Mandatory=$false,
    ParameterSetName = "Default")]
  [Alias("U")]
  [switch]$Unshelve,

  #"[-Help -H] : Invokes Get-Help response."
  [Parameter(Mandatory=$true,
    ParameterSetName = "Help")]
  [Alias("H")]
  [switch]$Help
)

#------- Includes --------------------------------------------------------------
. "$PSScriptRoot\UtilityLib.ps1"

#------- Variables -------------------------------------------------------------
[String] $TODOBlockStart               = "TODO:" 
[String] $ValidTODOBlockStartRegEx     = "^[ ]*//[ ]*TODO:"
[String] $InvalidTODOBlockStartRegEx   = "^[ ]*//[ ]*TODO:.*TODO:"

[String] $TODOBlockEnd                 = ":TODO"
[String] $ValidTODOBlockEndRegEx       = "^[ ]*//.*:TODO[ ]*$"
[String] $InvalidTODOBlockEndRegEx     = "^[ ]*//.*:TODO.*:TODO[ ]*$"

[String] $ShelfFile                    = "TODO.shelf" 

#------- Functions -------------------------------------------------------------
# Make sure that a TODO.shelf does not already exist in the -Path directory or
# sub-directories. 
function Assert-NoTODOShelf {
  Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
    $FileName = $_
    if ($FileName.Name -eq $ShelfFile) {
        Write-TSError -FileName $MyInvocation.ScriptName `
          -LineNumber $MyInvocation.ScriptLineNumber `
          -ErrorMsg (-join("${ShelfFile} already exists, manually delete ",
            "(${FileName}) if you would like to create a new ${ShelfFile}. ",
            "WARNING! the data saved in (${FileName}) will be lost if you ",
            "delete it."))
    }
  }
}

function Assert-ValidTODOBlocks {
  Assert-NoTODOShelf
  
  # Iterate over the files in $Path directory.
  Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
    [Bool] $InTODOBlock  = $false
    $FileName            = $_
    $FileContent         = Get-Content $FileName
    $LineNumber          = 0
    $TODOStartLineNumber = $LineNumber
    
    # Iterate over the lines in a file.
    foreach ($Line in $FileContent) {
      $LineNumber++
      
      # If we are inside a TODO comment block, catch unexpected syntax and 
      # the end of the TODO comment block.
      if ($InTODOBlock) {
        # Unexpected opening "TODO:" keyword inside TODO comment block.
        if ($Line.ToUpper().Contains($TODOBlockStart.ToUpper())) {
          Write-TSError -FileName $FileName -LineNumber $LineNumber `
            -ErrorMsg (-join("Unexpected opening `"TODO:`" keyword inside TODO",
              " comment block."))
        }

        # Write an error if the TODO comment block does NOT start with a "//".
        if(-not ($Line -match "^[ ]*//")) {
          Write-TSError -FileName $FileName -LineNumber $LineNumber `
            -ErrorMsg (-join("Expected double slash comment `"//`" on line ",
              "(${LineNumber}) in TODO comment block."))
        }

        # Catch the end of a TODO comment block.
        if ($Line.ToUpper().Contains($TODOBlockEnd.ToUpper())) {
          # Make sure the ":TODO" keyword is formatted correctly.
          if ($Line -match $ValidTODOBlockEndRegEx) {
            if ($Line -match $InvalidTODOBlockEndRegEx) {
              Write-TSError -FileName $FileName -LineNumber $LineNumber `
                -ErrorMsg (-join("Closing `":TODO`" keyword not properly ",
                  "formatted. Make sure that the `":TODO`" keyword is in a ",
                  "comment `"//`" and is the last statement on a line."))
            }
            else {
              $InTODOBlock = $false  
            }
          }
          else {
            Write-TSError -FileName $FileName -LineNumber $LineNumber `
              -ErrorMsg (-join("Closing `":TODO`" keyword not properly ",
                "formatted. Make sure that the `":TODO`" keyword is in a ",
                "comment `"//`" and is the last statement on a line."))
          }
        }
      }

      # If we are NOT inside a TODO comment block, catch unexpected syntax and 
      # the start of a TODO comment block.
      else {        
        # Catch the start of a TODO comment block.
        if ($Line.ToUpper().Contains($TODOBlockStart.ToUpper())) {
          # Make sure the "TODO:"" keyword is formatted correctly.
          if($Line -match $ValidTODOBlockStartRegEx) {
            if($Line -match $InvalidTODOBlockStartRegEx) {
              Write-TSError -FileName $FileName -LineNumber $LineNumber `
                -ErrorMsg (-join("Opening `"TODO:`" keyword not properly ",
                  "formatted. Make sure that the `"TODO:`" keyword is in a ",
                  "comment `"//`" and is the first statement after the comment",
                  " `"//`"."))
            }
            else {
              $InTODOBlock = $true
              $TODOStartLineNumber = $LineNumber
            }
          }
          else {
            Write-TSError -FileName $FileName -LineNumber $LineNumber `
              -ErrorMsg (-join("Opening `"TODO:`" keyword not properly ",
                "formatted. Make sure that the `"TODO:`" keyword is in a ",
                "comment `"//`" and is the first statement after the comment ",
                "`"//`" ."))
          }
        }

        # Catch the end of TODO comment block. or unexpected closing ":TODO" 
        # keyword outside TODO comment block.
        if ($Line.ToUpper().Contains($TODOBlockEnd.ToUpper())) {
          if ($InTODOBlock) {
            # Make sure the ":TODO" keyword is formatted correctly.
            if ($Line -match $ValidTODOBlockEndRegEx) {
              if ($Line -match $InvalidTODOBlockEndRegEx) {
                Write-TSError -FileName $FileName -LineNumber $LineNumber `
                  -ErrorMsg (-join("Closing `":TODO`" keyword not properly ",
                    "formatted. Make sure that the `":TODO`" keyword is in a ",
                    "comment `"//`" and is the last statement on a line."))
              }
              else {
                $InTODOBlock = $false  
              }
            }
            else {
              Write-TSError -FileName $FileName -LineNumber $LineNumber `
                -ErrorMsg (-join("Closing `":TODO`" keyword not properly ",
                  "formatted. Make sure that the `":TODO`" keyword is in a ",
                  "comment `"//`" and is the last statement on a line."))
            }
          }
          else {
            Write-TSError -FileName $FileName -LineNumber $LineNumber `
              -ErrorMsg (-join("Unexpected closing `":TODO`" keyword outside ",
                "TODO comment block."))
          }
        }
      }
    }

    if($InTODOBlock) {
      Write-TSError -FileName $FileName -LineNumber $TODOStartLineNumber `
        -ErrorMsg (-join("Opening `"TODO:`" keyword without a closing ",
          "`":TODO`" keyword."))
    }
  }
}

function Move-TODOBlocks {
  [String[]] $TODOShelfContent
  [String[]] $NewFileContent
  
  # Iterate over the files in $Path directory.
  Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
    $NewFileContent            = @()
    [Bool] $FirstIteration     = $true
    [Bool] $InTODOBlock        = $false
    [String] $FileName         = $_
    $FileContent               = Get-Content $FileName
    $LineNumber                = 0
    $TODOStartLineNumber       = $LineNumber
    $FileRelativePath          = $Filename.Substring($Path.Length)
    
    $TODOShelfContent += "FILE:<${FileRelativePath}>"
    # Iterate over the lines in a file.
    foreach ($Line in $FileContent) {
      $LineNumber++

      # If we are inside a TODO comment block, save the TODO block information
      if ($InTODOBlock) {
        $TODOShelfContent += "`n($TODOStartLineNumber,$LineNumber):$Line"

        # Catch the end of a TODO comment block.
        if ($Line.ToUpper().Contains($TODOBlockEnd.ToUpper())) {
          # Make sure the ":TODO" keyword is formatted correctly.
          if ($Line -match $ValidTODOBlockEndRegEx) {
            $InTODOBlock = $false
          }
        }
      }

      # If we are NOT inside a TODO comment block, catch unexpected syntax and 
      # the start of a TODO comment block.
      else {        

        # Catch the start of a TODO comment block.
        if ($Line.ToUpper().Contains($TODOBlockStart.ToUpper())) {
          # Make sure the "TODO:"" keyword is formatted correctly.
          if($Line -match $ValidTODOBlockStartRegEx) {            
            $InTODOBlock = $true
            $TODOStartLineNumber = $LineNumber
            $TODOShelfContent += "`n($TODOStartLineNumber,$LineNumber):$Line"
          }
        }

        if (-not ($InTODOBlock)) {
          if ($FirstIteration) {
            $NewFileContent += "$Line"         
            $FirstIteration = $false
          }
          else {
            $NewFileContent += "`n$Line"
          }
        }

        # Catch the end of TODO comment block.
        if ($Line.ToUpper().Contains($TODOBlockEnd.ToUpper())) {
          # Make sure the ":TODO" keyword is formatted correctly.
          if ($Line -match $ValidTODOBlockEndRegEx) {
            $InTODOBlock = $false  
          }
        }
      }
    }

    [String] $FileHash = (Get-FileHash ${Path}${FileRelativePath}).Hash
    $TODOShelfContent += "`nHASH:<${FileHash}>`n`n"
    [io.file]::WriteAllText((-join($Path, $FileRelativePath)), $NewFileContent)
  }

  Write-Host "TODO Blocks moved to (${Path}\${ShelfFile})."
  [io.file]::WriteAllText((-join($Path, "\", $ShelfFile)), $TODOShelfContent)
}

#------- Script Body -----------------------------------------------------------
Assert-Help $MyInvocation.MyCommand.Source
Assert-Path $Path

$Shelve = $true
if ($Shelve -and $Unshelve) { 
  Write-TSError `
    -FileName   $MyInvocation.MyCommand.Source `
    -LineNumber 0 `
    -ErrorMsg "The -Shelve and -Unshelve flags can not be used simultaneously."
}

if ($Shelve) {
  Assert-ValidTODOBlocks
  Move-TODOBlocks
}

