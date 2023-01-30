function New-CmdletDocumentation {
    param (
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Cmdlet',
            ValueFromPipeline = $true
        )]    
        [Object[]]$InputObject,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Name'
        )]    
        [string[]]$Name
    )
    Begin {
        foreach ($Obj in $InputObject){
            if ($Obj.GetType() -notin [System.Management.Automation.CmdletInfo],[System.Management.Automation.FunctionInfo]){
                throw [System.Management.Automation.ParameterBindingException] "Cannot process argument transformation on parameter 'InputObject'. Cannot convert the `"$Obj`" value of type `"$($Obj.GetType().Name)`" to type `"CmdletInfo`" or `"FunctionInfo`"."
                exit 1
            }
        }
        if ($Name){
            try {
                $InputObject = Get-Command -Name $Name
            } catch {
                throw [System.Management.Automation.CommandNotFoundException] "Unable to find command '$Name'."
                exit 1
            }
        }
        $Required_Modules = @{
            'Get-LoremIpsum.ps1' = @(
                'Get-LoremIpsum'
            )
            'Get-CommandSyntax.ps1' = @(
                'Get-CommandSyntax'
            )
        }
        foreach ($Mod in $Required_Modules.GetEnumerator()){
            foreach ($indvCommand in $Mod.Value){
                try {
                    Get-Command -Name $indvCommand -ErrorAction Stop | Out-Null
                } catch {
                    $ScriptPath = "{0}\{1}" -f $pwd.path, $Mod.key
                    try {
                        . $ScriptPath | Out-Null
                        Get-Command -Name $indvCommand -ErrorAction Stop | Out-Null
                    } catch {
                        throw [System.Management.Automation.CommandNotFoundException] "Unable to find cmdlet '$InputObject'. Make sure the '$($Mod.Key)' module is imported."
                        exit 1
                    }
                }
            }
        }
    }
    Process {
        foreach ($Obj in $InputObject){
            $OutArray = @()
            $OutArray += "# {0}`n" -f $Obj.Name
            $OutArray += Get-LoremIpsum -Sentences 1
            $OutArray += "## Syntax`n"
            $Syntax = Get-CommandSyntax -Command $Obj
            $spaces = ' ' * 4
            foreach ($set in $Syntax.ParameterSets){
                $OutArray += "{0}{1}" -f $spaces, $Obj.Name
                foreach ($param in $set.Parameters){
                    $OutArray += "{0}{1}" -f ($spaces * 2), $param
                }
                $OutArray += ''
            }
            $OutArray += "## Description`n"
            $OutArray += Get-LoremIpsum -Paragraphs 2
            $OutArray += "## Examples`n"
            $Help = Get-Help $Obj.Name
            $exCount = 1
            foreach ($example in $Help.examples.example){
                $OutArray += "### {0}`n" -f $example.title.trim('-').trim() -replace 'Example \d+', ('Example {0}' -f $exCount)
                foreach ($line in ($example.code -split "`n")){
                    $OutArray += "{0}{1}" -f $spaces, $line
                }
                $OutArray += $example.remarks
                $exCount++
            }
            $OutArray += "## Parameters`n"
            foreach ($param in $Help.Parameters.parameter){
                $OutArray += "#### **`-{0}`**`n" -f $param.name
                $OutArray += Get-LoremIpsum -Sentences 1
                $OutArray += ''
                $OutArray += "| Attribute | Value |"
                $OutArray += "| --- | --- |"
                $OutArray += "| Type | {0} |" -f $param.type.name
                $OutArray += "| Position | {0} |" -f $param.position
                $OutArray += "| AcceptPipelineInput | {0} |" -f [System.Convert]::ToBoolean($param.pipelineInput.split()[0])
            }
            $OutArray += "## Inputs`n"
            foreach ($input in ($Help.inputTypes.inputType.type.name.split("`n").split(",").trim().trimEnd('[]') | Where-Object {![string]::IsNullOrEmpty($_.Trim())})){
                $OutArray += "#### [**{0}**]()`n" -f $input
                $OutArray += Get-LoremIpsum -Sentences 1
            }
            $OutArray += "## Outputs"
            if (!$Obj.OutputType){
                $OutArray += "#### **None**`n"
            } else {
                foreach ($output in $Obj.OutputType.type.name){
                    $OutArray += "#### [**{0}**]()`n" -f $output
                    $OutArray += Get-LoremIpsum -Sentences 1
                }
            }
            $OutArray += "## Notes`n"
            $OutArray += Get-LoremIpsum -Paragraphs 3
            $OutArray += "## Related Links`n"
            $OutArray += "- [Link 1](url.com)"
            return $OutArray
        }
    }
}