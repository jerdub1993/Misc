function New-CmdletDocumentation {
    param (
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'InputObject',
            ValueFromPipeline = $true
        )]    
        [Object[]]$InputObject,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Name'
        )]    
        [string[]]$Name,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Script'
        )]    
        [string[]]$Script,
        [switch]$LoremIpsum
    )
    Begin {
        function Split-Link {
            param (
                [string]$Text
            )
            $Split = $Text -split ': '
            if ($Text -match '^.*: https?:\/\/(.+\.)+.+\/?[^\s\t\n\r]*$' -and [System.Uri]::IsWellFormedUriString($Split[1], [System.UriKind]::Absolute)) {
                return [PSCustomObject]@{
                    Label   = $Split[0].TrimEnd(':')
                    Uri     = $Split[1]
                }
            }
        }
        switch ($PSCmdlet.ParameterSetName){
            InputObject {
                foreach ($Obj in $InputObject){
                    if ($Obj.GetType() -notin [System.Management.Automation.CmdletInfo],[System.Management.Automation.FunctionInfo]){
                        throw [System.Management.Automation.ParameterBindingException] "Cannot process argument transformation on parameter 'InputObject'. Cannot convert the `"$Obj`" value of type `"$($Obj.GetType().Name)`" to type `"CmdletInfo`" or `"FunctionInfo`"."
                        exit 1
                    }
                }
            }
            Name        {
                try {
                    $InputObject = Get-Command -Name $Name
                } catch {
                    throw [System.Management.Automation.CommandNotFoundException] "Unable to find command '$Name'."
                    exit 1
                }
            }
            Script      {
                try {
                    $InputObject = (Get-Item -LiteralPath $Script).FullName
                } catch {
                    throw [System.Management.Automation.ItemNotFoundException] "Cannot find path '$($PWD.Path)\$Script' because it does not exist."
                    exit 1
                }
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
            foreach ($indvCommand in ($Mod.Value | Where-Object {![string]::IsNullOrEmpty($_.trim())})){
                try {
                    Get-Command -Name $indvCommand -ErrorAction Stop | Out-Null
                } catch {
                    $ScriptPath = "{0}\{1}" -f $pwd.path, $Mod.key
                    try {
                        . $ScriptPath | Out-Null
                        Get-Command -Name $indvCommand -ErrorAction Stop | Out-Null
                    } catch {
                        throw [System.Management.Automation.CommandNotFoundException] "Unable to find cmdlet '$indvCommand'. Make sure the '$($Mod.Key)' module is imported."
                        exit 1
                    }
                }
            }
        }
    }
    Process {
        foreach ($Obj in $InputObject){
            $Help = Get-Help $Obj.Name
            $OutArray = @()

            #region Cmdlet Name
            $OutArray += "# {0}`n" -f $Help.Name
            #endregion Cmdlet Name

            #region Synopsis
            $OutArray += if ($Help.Synopsis) {
                $Help.Synopsis.Trim()
            } elseif ($LoremIpsum){
                Get-LoremIpsum -Sentences 1
            }
            #endregion Synopsis

            #region Syntax
            $OutArray += "`n## Syntax"
            $spaces = ' ' * 4
            $Syntax = Get-CommandSyntax -Command $Obj
            foreach ($set in $Syntax.ParameterSets){
                $OutArray += '```PowerShell'
                $OutArray += $Help.Name
                foreach ($param in $set.Parameters){
                    $OutArray += "{0}{1}" -f $spaces, $param
                }
                $OutArray += '```'
            }
            #endregion Syntax

            #region Description
            $OutArray += "`n## Description"
            $OutArray += if ($Help.description){
                $Help.description
            } elseif ($LoremIpsum){
                Get-LoremIpsum -Paragraphs 2
            }
            #endregion Description

            #region Examples
            $OutArray += "`n## Examples"
            $exCount = 1
            foreach ($example in $Help.examples.example){
                $OutArray += "`n### Example {0}" -f $exCount
                $OutArray += '```PowerShell'
                foreach ($line in ($example.code -split "`n")){
                    $OutArray += $line
                }
                $OutArray += '```'
                $OutArray += if ($example.remarks){
                    foreach ($line in (($example.remarks.text | Where-Object {![string]::IsNullOrEmpty($_.Trim())}) -split "`n")){
                        "`n$line"
                    }
                } elseif ($LoremIpsum){
                    Get-LoremIpsum -Sentences 2
                }
                $exCount++
            }
            #endregion Examples

            #region Parameters
            $OutArray += "`n## Parameters"
            $htmlSpaces = '&ensp;' * 4
            $tablePattern = "| {0} | {1} |"
            foreach ($param in $Help.Parameters.parameter){
                $OutArray += "`n#### **`-{0}`**" -f $param.name
                $OutArray += if ($param.Description){
                    "{0}{1}" -f $htmlSpaces, $param.Description.Text
                } elseif ($LoremIpsum) {
                    "{0}{1}" -f $htmlSpaces, (Get-LoremIpsum -Sentences 1)
                }
                $OutArray += ''
                $OutArray += $tablePattern -f "Attribute", "Value"
                $OutArray += $tablePattern -f "---", "---"
                $TypeName = if ($param.type.name -eq 'switch'){
                    'SwitchParameter'
                } else {
                    $param.type.name
                }
                $OutArray += $tablePattern -f "Type", $TypeName
                $OutArray += $tablePattern -f "Position", (Get-Culture).TextInfo.ToTitleCase($param.position)
                $DefaultValue = if ($param.type.name -eq 'switch') {
                    $false
                } elseif ($param.defaultValue) {
                    $param.defaultValue.Trim()
                } else {
                    "None"
                }
                $OutArray += $tablePattern -f "Default value", $DefaultValue
                $OutArray += $tablePattern -f "AcceptPipelineInput", [System.Convert]::ToBoolean($param.pipelineInput.split()[0])
            }
            #endregion Parameters

            #region Inputs
            $OutArray += "`n## Inputs"
            $inputText = foreach ($inputType in ($Help.parameters.parameter.type.name | Select-Object -Unique | Sort-Object)){
                "`n#### [**{0}**]()" -f $inputType
                if ($LoremIpsum) {
                    Get-LoremIpsum -Sentences 1
                }
            }
            $OutArray += if ($inputText.Count -gt 0){
                $inputText
            } else {
                $OutArray += "`n#### **None**`n"
            }
            #endregion Inputs

            #region Outputs
            $OutArray += "`n## Outputs"
            $returnValues = foreach ($returnValue in $Help.returnValues.returnValue){
                "`n#### [**{0}**]()" -f $returnValue.type.name.Trim()
                if ($returnValue.Description){
                    $returnValue.Description
                } elseif ($LoremIpsum){
                    Get-LoremIpsum -Sentences 1
                }
            }
            $OutArray += if ($returnValues.Count -eq 0){
                "`n#### **None**"
            } else {
                $returnValues
            }
            #endregion Outputs

            #region Notes
            $OutArray += "`n## Notes"
            $aliasList = Get-Alias -Definition $Help.Name -ErrorAction SilentlyContinue
            $OutArray += if ($aliasList) {
                'PowerShell includes the following aliases for `{0}`:' -f $Help.Name
                foreach ($alias in $aliasList){
                    '- `{0}`' -f $alias.Name
                }
            } elseif ($LoremIpsum){
                Get-LoremIpsum -Paragraphs 3
            }
            #endregion Notes

            #region Related Links
            $OutArray += "`n## Related Links"
            $LinkPattern = '- [{0}]({1})'
            $Links = $help.relatedLinks.navigationLink
            if ($Links){
                $defaultUri = $true
                foreach ($uri in ($Links.Uri | Where-Object {![string]::IsNullOrEmpty($_)})){
                    $OutArray += switch ($defaultUri){
                        $true   {
                            $LinkPattern -f $Help.Name, $uri
                        }
                        $false  {
                            $LinkPattern -f $uri, $uri
                        }
                    }
                    $defaultUri = $false
                }
                if ($Links.linkText){
                    foreach ($linkText in ($Links.linkText | Where-Object {![string]::IsNullOrEmpty($_)})){
                        $splitLink = Split-Link -Text $linkText
                        $cmd = Get-Command -Name $linkText -ErrorAction SilentlyContinue
                        $OutArray += if ([System.Uri]::IsWellFormedUriString($linkText, [System.UriKind]::Absolute)){
                            $LinkPattern -f $linkText, $linkText
                        } elseif ($splitLink){
                            $LinkPattern -f $splitLink.Label, $splitLink.Uri
                        } elseif ($cmd -and $cmd.helpUri) {
                            $LinkPattern -f $linkText, $cmd.helpUri
                        } else {
                            "- $linkText"
                        }
                    }
                }
            } else {
                $linkText = if ($LoremIpsum){
                    Get-LoremIpsum -Words 2
                } else {
                    "Link 1"
                }
                $OutArray += "- [{0}]()" -f $linkText
            }
            #endregion Related Links

            return $OutArray
        }
    }
}