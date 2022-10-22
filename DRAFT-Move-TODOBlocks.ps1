[bool]$InvalidFormat = $false

# Assert-ValidTODOBlocks
Get-ChildItem -Path "C:\Users\sanzo\OneDrive\Desktop\C++\Sandbox\Sandbox\src\" | ForEach-Object { 
    [bool]$inTODO = $false
    $filename     = $_
    $filecontent = Get-Content $filename
    
    Write-Output $filename.Name
    if ($filename.Name -eq "TODO.shelf")
    {
        $Name = $filename.Name
        Write-Host "${filename}(0) : Error 42 : ${name} file already exists. Please, manually delete ${filename} if you would like to create a new $name. Warning the TODO comment blocks saved in ${filename} will be lost if you delete ${filename}. Make sure you are okay with losing that data before deleting." -ForegroundColor Red
        $filecontent = ""
    }

    # Confirm that each TODO comment block is formated correctly
    $linenumber = 1
    $TODOStartLineNumber = $linenumber
    foreach ($line in $filecontent)
    {
        # If we are inside a TODO comment block
        if ($inTODO)
        {
            # Write an error if the comment block is NOT formatted properly, i.e. the comment does not start with "//"
            if(-not ($line -match "^[ ]*//"))
            {
                Write-Host "${filename}(${linenumber}) : Error 42 : Opening `"TODO:`" keyword without a closing `":TODO`" keyword. Expected (`"//`") on line (${lineNumber}) to signify we are in a TODO comment block." -ForegroundColor Red
                $InvalidFormat = $true
            }
        }

        # Catch the start of a TODO comment block.
        if ($line -match "^\s*//\s*TODO:")
        {
            if(-not $inTODO)
            {
                $inTODO = $true
                $TODOStartLineNumber = $linenumber
            }
        }

        # Catch the end of a TODO comment block.
        if($line -match ":TODO")
        {
            if(-not $inTODO)
            {
                Write-Host "${filename}(${linenumber}) : Error 42 : Closing `":TODO`" keyword without an opening `"TODO:`" keyword. " -ForegroundColor Red
                $InvalidFormat = $true
            }
            $inTODO = $false
        }

        $linenumber++
    }

    if($inTODO)
    {
        echo "${filename}($TODOStartLineNumber) : Error 42 : Opening `"TODO:`" keyword without a closing `":TODO` keyword. "
        $InvalidFormat = $true
    }
}

# If the TODO comment blocks are not formatted correctly abort mission without modifying anything.
if($InvalidFormat)
{
    $path = Get-Location
    $scriptName = $MyInvocation.MyCommand
    Write-Host "${path}\${scriptName}(44) : Error 42 : Script aborted, project contained incorrectly formatted TODO statements." -ForegroundColor Red
}


else
{
    # Save-TODOBlocks 
    Get-ChildItem -Path "C:\Users\sanzo\OneDrive\Desktop\C++\Sandbox\Sandbox\src\" | ForEach-Object { 
        [bool]$inTODO = $false
        $filename     = $_
        $filecontent = Get-Content $filename


        Out-File -FilePath "C:\Users\sanzo\OneDrive\Desktop\C++\Sandbox\Sandbox\src\TODO.shelf" -InputObject "FILE# ${filename}" -Append
        $linenumber = 1
        $TODOStartLineNumber = $linenumber
        foreach ($line in $filecontent)
        {
            # Catch the start of a TODO comment block.
            if ($line -match "^\s*//\s*TODO:")
            {
                if(-not $inTODO)
                {
                    $inTODO = $true
                    $TODOStartLineNumber = $linenumber
                }
            }

            if($inTODO)
            {
                Out-File -FilePath "C:\Users\sanzo\OneDrive\Desktop\C++\Sandbox\Sandbox\src\TODO.shelf" -InputObject "${filename}(${TODOStartLineNumber}:${linenumber}): ${line}" -Append
            }

            # Catch the end of a TODO comment block.
            if($line -match ":TODO")
            {
                $inTODO = $false
            }

            $linenumber++
        }
    }
}

