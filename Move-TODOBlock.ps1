  <#
  .SYNOPSIS
  Shelves and unshelves TODO comment blocks.

  .DESCRIPTION
  Tool to shelve and unshelve TODO comment blocks. 

  The process of "shelving" involves moving TODO blocks from original text 
  file(s) to a [generated] TODO.shelf. 

  The process of "unshelving" involves moving TODO blocks from a [generated] 
  TODO.shelf to original text file(s). 

  .PARAMETER Path
  Path to the source code root directory.

  .PARAMETER Shelve
  Use this switch when you want to shelve the TODO blocks in source code.

  .PARAMETER Unshelve
  Use this switch when you want to unshelve a [generated] TODO.shelf.

  .PARAMETER Force
  Use this switch when you want to continue through warning's without prompting
  the user.

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

  #"[-Force -F] : Continue through warning prompts without prompting the user."
  [Parameter(Mandatory=$false,
    ParameterSetName = "Default")]
  [Alias("F")]
  [switch]$Force,

  #"[-Help -H] : Invokes Get-Help response."
  [Parameter(Mandatory=$true,
    ParameterSetName = "Help")]
  [Alias("H")]
  [switch]$Help
)

#------- Includes --------------------------------------------------------------
# Utility Library - A library of commonly used functions.
#------- Functions -------------------------------------------------------------
# Throw a custom ts420 error.
function Write-TSError {
  param (
      # FileName - Name of the file the error is being thrown in.
      [Parameter(Mandatory=$true)] 
      [String] $FileName, 
      
      # LineNumber - Line number the error is being thrown at.
      [Parameter(Mandatory=$true)] 
      [String] $LineNumber,

      # ErrorMsg - Message to display to the user.
      [Parameter(Mandatory=$true)] 
      [String] $ErrorMsg
  )

  Write-Error "${FileName}(${LineNumber}): error ts420 : ${ErrorMsg}"
  exit 420
}

# Handles if a non-standard help argument is passed to the script.
function Assert-Help {
  param (
      [Parameter(Mandatory=$true)]
      [String] $ThisScriptPath
  )

  # Assert the $ThisScriptPath argument is valid.
  if (-not (Test-Path $ThisScriptPath)) {
      Write-TSError `
          -FileName   $MyInvocation.ScriptName `
          -LineNumber $MyInvocation.ScriptLineNumber `
          -ErrorMsg (-join("Invalid `$ThisScriptPath argument in Assert-Help ",
              "function call. Call Assert-Help with a path to the current ",
              "script. For example `"Assert-Help ",
              "`$MyInvocation.MyCommand.Source`"."))
  }

  if ($Help) { Get-Help $ThisScriptPath; exit 0 }
}

# Assert that the ArgPath parameter is a valid filepath.
function Assert-Path {
  param (
      [Parameter(Mandatory=$true)]
      [String] $ArgPath
  )

  if (-not (Test-Path $ArgPath)) {
      Write-TSError `
          -FileName $MyInvocation.ScriptName `
          -LineNumber $MyInvocation.ScriptLineNumber `
          -ErrorMsg "Cannot find path (${ArgPath}) because it does not exist."
  }
}

#------- Variables -------------------------------------------------------------
[String] $TODOBlockStart               = "TODO:" 
[String] $ValidTODOBlockStartRegEx     = "^\s*//\s*TODO:"
[String] $InvalidTODOBlockStartRegEx   = "^\s*//\s*TODO:.*TODO:"

[String] $ValidTODOBlockBodyRegEx      = "^\s*//"

[String] $TODOBlockEnd                 = ":TODO"
[String] $ValidTODOBlockEndRegEx       = "^\s*//.*:TODO\s*$"
[String] $InvalidTODOBlockEndRegEx     = "^\s*//.*:TODO.*:TODO\s*$"

[String] $TODOShelfRegex               = "^✝(?<Tag>[^✝]*)✝(?<Value>[^✝]*)✝$"
[String] $TODOLineNumberRegex          = "\((?<LineNumber>\d+)\)"

[String] $ShelfFile                    = "TODO.shelf" 

#------- Functions -------------------------------------------------------------
# Make sure that a TODO.shelf does not already exist in the -Path directory or
# sub-directories. 
function Assert-NoTODOShelf {
  Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
    $FileName = $_.Name
    if ($FileName -eq $ShelfFile) {
        Write-TSError -FileName $MyInvocation.ScriptName `
          -LineNumber $MyInvocation.ScriptLineNumber `
          -ErrorMsg (-join("${ShelfFile} already exists, manually delete the ",
            "${FileName} if you would like to create a new ${ShelfFile}. ",
            "WARNING! the data saved in the (${FileName}) will be lost if you ",
            "delete it."))
    }
  }
}

# Confirm the TODO comment blocks are formatted correctly.
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
        if(-not ($Line -match $ValidTODOBlockBodyRegEx)) {
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

# Export TODO comment blocks from source code to the TODO.shelf file.
function Export-TODOBlocks {
  [String[]] $TODOShelfContent
  [String[]] $NewFileContent
  
  # Iterate over the files in $Path directory.
  Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
    $NewFileContent                = @()
    [Bool] $FirstIteration         = $true
    [Bool] $InTODOBlock            = $false
    [String] $FileName             = $_
    $FileContent                   = Get-Content $FileName
    [Bool] $FileContainsTODOBlocks = $false
    [int] $LineNumber              = 0
    [int] $TODOStartLineNumber     = $LineNumber
    $FileRelativePath              = $Filename.Substring($Path.Length)
    
    $TODOShelfContent += "✝FILE✝${FileRelativePath}✝"
    # Iterate over the lines in a file.
    foreach ($Line in $FileContent) {
      $LineNumber++

      # If we are inside a TODO comment block, save the TODO block information
      if ($InTODOBlock) {
        $TODOShelfContent += -join("`n✝($LineNumber)✝$Line✝")

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
            $FileContainsTODOBlocks = $true
            $TODOStartLineNumber = $LineNumber
            $TODOShelfContent += -join("`n✝($LineNumber)✝$Line✝")
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

    # Remove the TODO block comments from the source code file.
    if ($FileContainsTODOBlocks) {
      Out-File -FilePath (-join($Path, $FileRelativePath)) `
        -InputObject $NewFileContent `
        -NoNewline
    }

    # Save the file's hash so we know if the source code has been modified since
    # the TODO block comments were removed.
    [String] $FileHash = (Get-FileHash ${Path}${FileRelativePath}).Hash
    $TODOShelfContent += "`n✝HASH✝${FileHash}✝`n✝☮︎`n"
  }

  # Save TODO block comments to the TODO.shelf file.
  $TODOShelfContent += "✝☮︎"
  [io.file]::WriteAllText((-join($Path, "\", $ShelfFile)), $TODOShelfContent)
  Write-Host "TODO Blocks moved to (${Path}\${ShelfFile})."
}

# Confirm a TODO.shelf is present in the -Path directory.
function Assert-TODOShelf {
  $ShelfExist = $false
  Get-ChildItem -Path $Path -File | ForEach-Object {
    $FileName = $_.Name
    if ($FileName -eq $ShelfFile) { $ShelfExist = $true; return }
  }
  if ($ShelfExist) { return }

  Write-TSError -FileName $MyInvocation.ScriptName `
    -LineNumber 0 `
    -ErrorMsg "${ShelfFile} not found in ($Path) directory."
}

# Confirm the TODO.shelf is formatted correctly.
function Assert-ValidTODOShelf {
  Assert-TODOShelf

  $LineNumber       = 0
  $ExpectingFileTag = $true
  $ShelfContent     = Get-Content $Path/$ShelfFile 

  # Iterate over the content in the TODO.shelf.
  foreach ($Line in $ShelfContent) {
    $LineNumber++
    
    # Ignore blank lines.
    if (-not ($Line -match "✝☮︎")) {

      # Make sure that non-blank lines are formatted correctly.
      if ($Line -match $TODOShelfRegex) {
        
        # Grab the Tag and Value group from the TODO.shelf.
        $Match = Select-String -InputObject $Line -Pattern $TODOShelfRegex
        $Tag, $Value = $Match.Matches[0].Groups[1..2].Value

        if ($ExpectingFileTag) {
          $ExpectingFileTag = $false

          # Throw an error if the FILE tag is missing.
          if($Tag -ne "FILE") {
            Write-TSError -FileName "$Path\$ShelfFile" `
              -LineNumber $LineNumber `
              -ErrorMsg "Missing 'FILE' keyword."
          }

          $CurrentFile = "${Path}${Value}"
          # Throw an error if the file path is invalid.
          if (-not (Test-Path -Path $CurrentFile -PathType Leaf)) { 
            Write-TSError -FileName "$Path\$ShelfFile" `
              -LineNumber $LineNumber `
              -ErrorMsg (-join("Missing file! `"$CurrentFile`"... re-add the ",
                "file or remove the file's metadata from the TODO.shelf"))
          }
        }
        else {
          
          # If the tag is NOT formatted like a LINENUMBER tag.
          if (-not ($Tag -match $TODOLineNumberRegex)) { 
            $ExpectingFileTag = $true

            # Throw an error if the HASH tag is missing.
            if($Tag -ne "HASH") {
              Write-TSError -FileName "$Path\$ShelfFile" `
                -LineNumber $LineNumber `
                -ErrorMsg "Invalid LINENUMBER or HASH tag."
            }

            $CurrentFileHash = (Get-FileHash $CurrentFile).Hash
            # Check if the current file has been modified since the previous 
            # unshelve.
            if ($Value -ne $CurrentFileHash) {

              # Continue without prompting, if the user included the -Force 
              # switch.
              if (-not $Force) {

                Write-Host (-join("`nWarning! $CurrentFile appears to have ",
                  "been modified.`nWould you like to continue with the ",
                  "unshelve?")) `
                  -ForegroundColor Red -NoNewline

                # Prompt user if they would like to continue.
                do {
                  $Continue = Read-Host -Prompt " [y|n]" 
                } 
                until ($Continue -eq "y" -or $Continue -eq "n")
  
                # Exit at the request of the user.
                if ($Continue -eq "n") { exit 0 }
              }
            }
          }
        }
      }
      else {
        Write-TSError -FileName "$Path\$ShelfFile" `
          -LineNumber $LineNumber `
          -ErrorMsg "Line $LineNumber in TODO.shelf not formatted correctly."
      }
    }
  }
}

# Write TODO Blocks to a file.
function Write-TODOBlocksToFile {
  param (
    [string] $FilePath,
    $TODOBlocks
  )
  
  $TODOBlockIdx    = 0
  $CurrLine        = 0
  $PrevLineCount   = 0
  $NewFileContent  = @()
  $PrevFileContent = Get-Content $FilePath
  # Combine the file's content and the file's TODO block comments.
  foreach ($Line in $PrevFileContent) {
    $CurrLine++

    # If the $CurrLine and a TODO block comments line number matches, add the 
    # TODO block comment to the $NewFileContent.
    while ($CurrLine -eq $TODOBlocks[$TODOBlockIdx].LineNumber) {
      $TODOBlockLine = $TODOBlocks[$TODOBlockIdx++].Value
      $NewFileContent += $TODOBlockLine + "`n"
      $CurrLine++
    }
  
    $PrevLineCount++
    $NewFileContent += $Line + "`n"
  }

  # If we still have TODO block comments add them to the end of our 
  # $NewFileContent. 
  while ($TODOBlockIdx -lt $TODOBlocks.Length) {
    if(($NewFileContent.Length + 1) -eq $TODOBlocks[$TODOBlockIdx].LineNumber) {
      $Line = $TODOBlocks[$TODOBlockIdx++].Value
      $NewFileContent += $Line + "`n"
    }
    else {
      $NewFileContent += "`n"
    }
  }

  # Remove the final lines newline character, just a little cleanup before 
  # writing the $NewFileContent to the source code file.
  $NewFileContent[$NewFileContent.Length - 1] = `
    $NewFileContent[$NewFileContent.Length - 1].Substring(0, `
      ($NewFileContent[$NewFileContent.Length - 1].Length) - 1)
  
  Out-File -FilePath $FilePath `
    -InputObject $NewFileContent -NoNewline
}

function Import-TODOBlocks {
  $ExpectingFileTag    = $true
  $ShelfContent        = Get-Content "$Path\$ShelfFile"
  $TODOBlockCollection = @()

  # Iterate over the content in the TODO.shelf.
  foreach ($Line in $ShelfContent) {

    # Ignore blank lines.
    if (-not ($Line -match "✝☮︎")) {

      # Grab the Tag and Value group from the TODO.shelf.
      $Match = Select-String -InputObject $Line -Pattern $TODOShelfRegex
      $Tag, $Value = $Match.Matches[0].Groups[1..2].Value

      if ($ExpectingFileTag) {
        $ExpectingFileTag = $false

        $CurrentFile = "${Path}${Value}"
      }
      else {
              
        # If the tag is a LINENUMBER tag continue building the current file's
        # TODO block collection.
        if ($Tag -match $TODOLineNumberRegex) {
          $TagMatch = `
            Select-String -InputObject $Tag -Pattern $TODOLineNumberRegex
          $LineNumber = $TagMatch.Matches[0].Groups[1].Value
                  
          $TODOBlockCollection += [PSCustomObject]@{
            LineNumber = $LineNumber
            Value = $Value
          }
        }

        # If the tag is not a LINENUMBER tag it is the HASH tag so that's our 
        # trigger to write our TODO block collection to the current file.
        else {
          if($TODOBlockCollection.Count -gt 0){
            Write-TODOBlocksToFile -FilePath $CurrentFile `
              -TODOBlocks $TODOBlockCollection 
              $TODOBlockCollection = @()
          }
          $ExpectingFileTag = $true
        }
      }
    }
  } 

  # Remove the generated TODO.shelf.
  Remove-Item $Path/$ShelfFile
}

#------- Script Body -----------------------------------------------------------
Assert-Help $MyInvocation.MyCommand.Source
Assert-Path $Path

# Throw an error if the Shelve and Unshelve options are used at the same time.
if ($Shelve -and $Unshelve) { 
  Write-TSError `
    -FileName   $MyInvocation.MyCommand.Source `
    -LineNumber 0 `
    -ErrorMsg "The -Shelve and -Unshelve flags can not be used simultaneously."
}

# Shelve - Move TODO blocks from source code to the TODO.shelf
if ($Shelve) {
  Assert-ValidTODOBlocks
  Export-TODOBlocks
}

# Unshelve - Move TODO blocks from the TODO.shelf to source code.
elseif ($Unshelve) {
  Assert-ValidTODOShelf
  Import-TODOBlocks
}

else {
  Write-Host (-join("Warning! no-operations done. Specify whether the ",
    "[-Shelve] or [-Unshelve] operations should be executed.")) `
    -ForegroundColor Yellow
}
