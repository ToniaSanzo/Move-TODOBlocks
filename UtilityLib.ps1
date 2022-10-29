# Utility Library - Contains a library of commonly used functions.
# Copyright Tonia T. Sanzo 2022

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
            -ErrorMsg (-join("Invalid `$Path argument in Assert-Help function ",
                "call. Call Assert-Help with a path to the current script. ",
                "For example `"Assert-Help `$MyInvocation.MyCommand.Source`"."))
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