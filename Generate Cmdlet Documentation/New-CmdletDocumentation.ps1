function New-CmdletDocumentation {
    <#
        .LINK
            https://github.com/jerdub1993/Misc/tree/main/Generate%20Cmdlet%20Documentation
        .LINK
            Confluence Wiki syntax: https://confluence.atlassian.com/doc/confluence-wiki-markup-251003035.html
        .LINK
            Markdown syntax: https://www.markdownguide.org/cheat-sheet/
        .LINK
            PowerShell Comment-Based Help: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help
    #>
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]    
        [Object[]]$InputObject,
        [Parameter(
            Mandatory = $true
        )]
        [ValidateSet(
            'Markdown',
            'ConfluenceWiki'
        )]
        [string]$OutputType,
        [switch]$LoremIpsum,
        [ValidateSet(
            1,
            2,
            3
        )]
        [int]$HeadingLevel = 1
    )
    Begin {
        #region Functions
        function Get-TypeUri {
            param (
                [System.Reflection.TypeInfo]$Type
            )
            return "https://learn.microsoft.com/en-us/dotnet/api/{0}" -f $Type.FullName
        }
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
        function Get-Syntax {
            [CmdletBinding(
                DefaultParameterSetName = 'InputObject'
            )]
            param (
                [Parameter(
                    ValueFromPipeline = $true,
                    Mandatory = $true
                )]
                [Object]$InputObject
            )
            Begin {
                function Get-ParameterString {
                    param (
                        [Parameter(
                            Mandatory = $true,
                            ValueFromPipeline = $true
                        )]
                        [PSCustomObject[]]$Parameter
                    )
                    Process {
                        foreach ($Param in $Parameter){
                            $Name = $Param.Name
                            $Type = $Param.Type.Name
                            $Position = (Get-Culture).TextInfo.ToTitleCase($Param.Position)
                            $Mandatory = [Convert]::ToBoolean($Param.Required)
                            $NameMod = "-{0}" -f $Name
                            $TypeMod = "<{0}>" -f $Type
                            $Line = if ($Type -match 'SwitchParameter'){
                                $NameMod
                            } else {
                                if ($Position -match 'Named'){
                                    $NameMod = "[{0}]" -f $NameMod
                                }
                                "{0} {1}" -f $NameMod, $TypeMod
                            }
                            $Line = if ($Mandatory){
                                $Line
                            } else {
                                "[{0}]" -f $Line
                            }
                            $Line
                        }
                    }
                }
                function Get-ParameterSet {
                    param (
                        [Object]$Parameters
                    )
                    $ParametersOrdered = $Parameters | Where-Object Position -notmatch 'Named' | Sort-Object -Property Position
                    $ParametersNamed = $Parameters | Where-Object Position -match 'Named'
                    $ParamArray = @()
                    foreach ($Param in $ParametersOrdered){
                        $ParamArray += Get-ParameterString -Parameter $Param
                    }
                    foreach ($Param in $ParametersNamed){
                        $ParamArray += Get-ParameterString -Parameter $Param
                    }
                    return $ParamArray
                }
            }
            Process {
                try {
                    $Help = Get-Help $InputObject -ErrorAction Stop
                } catch {
                    throw $_
                    exit 1
                }
                $SyntaxItems = $Help.syntax.syntaxItem
                $ParameterSets = foreach ($set in $SyntaxItems){
                    $name = if ($set.Name -match '^\(All\)$'){
                        'All'
                    } else {
                        $set.Name
                    }
                    $Parameters = $Help.parameters.parameter | Where-Object Name -in $set.Parameter.name
                    [PSCustomObject]@{
                        Name = $name
                        Parameters = Get-ParameterSet -Parameters $Parameters
                    }
                }
                return [PSCustomObject]@{
                    Command = $Help.Name
                    ParameterSets = $ParameterSets
                }
            }
        }
        function Get-LoremIpsum {
            [CmdletBinding(
                DefaultParameterSetName = 'Paragraphs'
            )]
            param (
                [Parameter(
                    ParameterSetName = 'Paragraphs'
                )]
                [int]$Paragraphs = 1,
                [Parameter(
                    ParameterSetName = 'Sentences'
                )]
                [int]$Sentences = 1,
                [Parameter(
                    ParameterSetName = 'Words'
                )]
                [int]$Words = 1
            )
            function Get-LIWord {
                param (
                    [int]$Length = $(Get-Random -Minimum 1 -Maximum 10),
                    [ValidateSet(
                        'Upper',
                        'Title',
                        'Lower'
                    )]
                    [string]$Case = $(if ((Get-Random 10) -eq 1){'Title'}else{'Lower'})
                )
                $alphabet = @('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z')
                $LetterArr = foreach ($letter in 1..$Length){
                    Get-Random $alphabet
                }
                $LetterStr = $LetterArr -join ''
                $LetterStr = switch ($Case){
                    Upper   {
                        $LetterStr.ToUpper()
                    }
                    Title   {
                        $LetterStr.Substring(0,1).ToUpper() + $LetterStr.Substring(1).ToLower()
                    }
                    Lower   {
                        $LetterStr
                    }
                }
                return $LetterStr
            }
            function Get-LISentence {
                param (
                    [int]$Length = $(Get-Random -Minimum 4 -Maximum 22),
                    [switch]$Formatted
                )
                $WordArr = @(
                    Get-LIWord -Case Title
                )
                foreach ($word in 2..$Length){
                    $WordArr += Get-LIWord
                }
                return "{0}." -f ($WordArr -join ' ')
            }
            function Get-LIParagraph {
                param (
                    [int]$Length = $(Get-Random -Minimum 2 -Maximum 6)
                )
                $SentenceArr = foreach ($sentence in 1..$Length){
                    Get-LISentence
                }
                return $SentenceArr -join ' '
            }
            switch ($PSCmdlet.ParameterSetName){
                Paragraphs  {
                    $ParArray = foreach ($Par in 1..$Paragraphs){
                        Get-LIParagraph
                    }
                    return $ParArray -join "`n`n"
                }
                Sentences   {
                    $SenArray = foreach ($Sen in 1..$Sentences){
                        Get-LISentence
                    }
                    return $SenArray -join ' '
                }
                Words       {
                    $WordArray = foreach ($Word in 1..$Words){
                        Get-LIWord
                    }
                    return $WordArray -join ' '
                }
            }
        }
        function Get-Markdown {
            param (
                [Parameter(
                    Mandatory = $true
                )]    
                [Object]$Help,
                [switch]$LoremIpsum,
                [ValidateSet(
                    1,
                    2,
                    3
                )]
                [int]$HeadingLevel = 1
            )
            $hashChars = '#' * $HeadingLevel
            $OutArray = @()

            #region Cmdlet Name
            $OutArray += "{0} {1}" -f $hashChars, $Help.Name
            #endregion Cmdlet Name

            #region Synopsis
            $OutArray += if ($Help.Synopsis) {
                $Help.Synopsis.Trim()
            } elseif ($LoremIpsum){
                Get-LoremIpsum -Sentences 1
            }
            #endregion Synopsis

            #region Syntax
            $OutArray += "`n{0}# Syntax" -f $hashChars
            $spaces = ' ' * 4
            $Syntax = Get-Syntax -InputObject $inObj
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
            $OutArray += "`n{0}# Description" -f $hashChars
            $OutArray += if ($Help.description){
                $Help.description.text
            } elseif ($LoremIpsum){
                Get-LoremIpsum -Paragraphs 2
            }
            #endregion Description

            #region Examples
            $OutArray += "`n{0}# Examples" -f $hashChars
            $exCount = 1
            foreach ($example in $Help.examples.example){
                $OutArray += "`n{0}## Example {1}" -f $hashChars, $exCount
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
            $OutArray += "`n{0}# Parameters" -f $hashChars
            $htmlSpaces = '&ensp;' * 4
            $tablePattern = "| {0} | {1} |"
            foreach ($param in $Help.Parameters.parameter){
                $OutArray += "`n{0}## **`-{1}`**" -f $hashChars, $param.name
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
                if ($param.aliases -notmatch 'None|'){
                    $OutArray += $tablePattern -f "Aliases", $param.aliases
                }
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
            $OutArray += "`n{0}# Inputs" -f $hashChars
            $helpInputTypes = $Help.inputTypes.inputType.type.name -split "`n" | Where-Object { ![string]::IsNullOrEmpty($_) } | Sort-Object
            $parameterInputTypes = $Help.parameters.parameter.type.name.TrimEnd('[]') | Select-Object -Unique | Sort-Object
            $OutArray += if (([string]::IsNullOrEmpty($helpInputTypes) -or $helpInputTypes -match 'None') -and $parameterInputTypes.Count -gt 0) {
                foreach ($inputType in $parameterInputTypes){
                    $ErrorActionPreference = 'Stop'
                    try {
                        [type]$type = $inputType
                        "`n{0}### [**{1}**]({2})" -f  $hashChars, $type.name, (Get-TypeUri -Type $type)
                    }
                    catch {
                        "`n{0}### [**{1}**]()" -f $hashChars, $inputType
                    }
                    $ErrorActionPreference = 'Continue'
                    if ($LoremIpsum) {
                        Get-LoremIpsum -Sentences 1
                    }
                }
            } else {
                if ([string]::IsNullOrEmpty($helpInputTypes) -or $helpInputTypes -match 'None'){
                    "`n{0}### **None**`n" -f $hashChars
                } else {
                    foreach ($helpInput in $helpInputTypes){
                        [type]$type = $helpInput.Replace('[]', '')
                        "`n{0}### [**{1}**]({2})" -f $hashChars, $type.name, (Get-TypeUri -Type $type)
                        if ($LoremIpsum) {
                            Get-LoremIpsum -Sentences 1
                        }
                    }
                }
            }
            #endregion Inputs

            #region Outputs
            $OutArray += "`n{0}# Outputs" -f $hashChars
            $OutArray += if ([string]::IsNullOrEmpty($Help.returnValues) -or $Help.returnValues.returnValue.type.name -match 'None') {
                "`n{0}### **None**" -f $hashChars
            } else {
                foreach ($returnValue in ($Help.returnValues.returnValue.type.name -split "`n" | Where-Object { ![string]::IsNullOrEmpty($_.Trim()) } | Sort-Object)){
                    [type]$type = $returnValue.Trim().TrimEnd('[]')
                    "`n{0}### [**{1}**]({2})" -f  $hashChars, $type.name, (Get-TypeUri -Type $type)
                    if ($LoremIpsum){
                        Get-LoremIpsum -Sentences 1
                    }
                }
            }
            #endregion Outputs

            #region Notes
            $OutArray += "`n{0}# Notes" -f $hashChars
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
            $OutArray += "`n{0}# Related Links" -f $hashChars
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
            } elseif ($LoremIpsum){
                    $linkText = Get-LoremIpsum -Words 2
                    $OutArray += "- [{0}]()" -f $linkText
            }
            #endregion Related Links

            return $OutArray
        }
        function Get-ConfluenceWiki {
            param (
                [Parameter(
                    Mandatory = $true
                )]    
                [Object]$Help,
                [switch]$LoremIpsum,
                [ValidateSet(
                    1,
                    2,
                    3
                )]
                [int]$HeadingLevel = 1
            )
            $OutArray = @()

            #region Cmdlet Name
            $OutArray += "h{0}. {1}" -f $HeadingLevel, $Help.Name
            #endregion Cmdlet Name

            #region Synopsis
            $OutArray += if ($Help.Synopsis) {
                $Help.Synopsis.Trim()
            } elseif ($LoremIpsum){
                Get-LoremIpsum -Sentences 1
            }
            #endregion Synopsis

            #region Syntax
            $OutArray += "`nh{0}. Syntax" -f ($HeadingLevel + 1)
            $spaces = ' ' * 4
            $Syntax = Get-Syntax -InputObject $inObj
            foreach ($set in $Syntax.ParameterSets){
                $OutArray += '{code:language=powershell}'
                $OutArray += $Help.Name
                foreach ($param in $set.Parameters){
                    $OutArray += "{0}{1}" -f $spaces, $param
                }
                $OutArray += '{code}'
            }
            #endregion Syntax

            #region Description
            $OutArray += "`nh{0}. Description" -f ($HeadingLevel + 1)
            $OutArray += if ($Help.description){
                $Help.description.text
            } elseif ($LoremIpsum){
                Get-LoremIpsum -Paragraphs 2
            }
            #endregion Description

            #region Examples
            $OutArray += "`nh{0}. Examples" -f ($HeadingLevel + 1)
            $exCount = 1
            foreach ($example in $Help.examples.example){
                $OutArray += "`nh{0}. Example {1}" -f ($HeadingLevel + 2), $exCount
                $OutArray += '{code:language=powershell}'
                foreach ($line in ($example.code -split "`n")){
                    $OutArray += $line
                }
                $OutArray += '{code}'
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
            $OutArray += "`nh{0}. Parameters" -f ($HeadingLevel + 1)
            $htmlSpaces = '&ensp;' * 4
            $tablePattern = "|{0}|{1}|"
            foreach ($param in $Help.Parameters.parameter){
                $OutArray += "`nh{0}. *{1}*" -f ($HeadingLevel + 2), "{{-$($param.name)}}"
                $OutArray += if ($param.Description){
                    "{0}{1}" -f $htmlSpaces, $param.Description.Text
                } elseif ($LoremIpsum) {
                    "{0}{1}" -f $htmlSpaces, (Get-LoremIpsum -Sentences 1)
                }
                $OutArray += ''
                $TypeName = if ($param.type.name -eq 'switch'){
                    'SwitchParameter'
                } else {
                    $param.type.name
                }
                $OutArray += $tablePattern -f "Type", $TypeName
                if ($param.aliases -notmatch 'None|'){
                    $OutArray += $tablePattern -f "Aliases", $param.aliases
                }
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
            $OutArray += "`nh{0}. Inputs" -f ($HeadingLevel + 1)
            $helpInputTypes = $Help.inputTypes.inputType.type.name -split "`n" | Where-Object { ![string]::IsNullOrEmpty($_) } | Sort-Object
            $parameterInputTypes = $Help.parameters.parameter.type.name.TrimEnd('[]') | Select-Object -Unique | Sort-Object
            $OutArray += if (([string]::IsNullOrEmpty($helpInputTypes) -or $helpInputTypes -match 'None') -and $parameterInputTypes.Count -gt 0) {
                foreach ($inputType in $parameterInputTypes){
                    $ErrorActionPreference = 'Stop'
                    try {
                        [type]$type = $inputType
                        "`nh{0}. [*{1}*|{2}]" -f  ($HeadingLevel + 3), $type.name, (Get-TypeUri -Type $type)
                    }
                    catch {
                        "`nh{0}. [*{1}*|]" -f ($HeadingLevel + 3), $inputType
                    }
                    $ErrorActionPreference = 'Continue'
                    if ($LoremIpsum) {
                        Get-LoremIpsum -Sentences 1
                    }
                }
            } else {
                if ([string]::IsNullOrEmpty($helpInputTypes) -or $helpInputTypes -match 'None'){
                    "`nh{0}. **None**`n" -f ($HeadingLevel + 3)
                } else {
                    foreach ($helpInput in $helpInputTypes){
                        [type]$type = $helpInput.Replace('[]', '')
                        "`nh{0}. [**{1}**|{2}]" -f ($HeadingLevel + 3), $type.name, (Get-TypeUri -Type $type)
                        if ($LoremIpsum) {
                            Get-LoremIpsum -Sentences 1
                        }
                    }
                }
            }
            #endregion Inputs

            #region Outputs
            $OutArray += "`nh{0}. Outputs" -f ($HeadingLevel + 1)
            $OutArray += if ([string]::IsNullOrEmpty($Help.returnValues) -or $Help.returnValues.returnValue.type.name -match 'None') {
                "`nh{0}. *None*" -f ($HeadingLevel + 3)
            } else {
                foreach ($returnValue in ($Help.returnValues.returnValue.type.name -split "`n" | Where-Object { ![string]::IsNullOrEmpty($_.Trim()) } | Sort-Object)){
                    [type]$type = $returnValue.Trim().TrimEnd('[]')
                    "`nh{0}. [*{1}*|{2}]" -f  ($HeadingLevel + 3), $type.name, (Get-TypeUri -Type $type)
                    if ($LoremIpsum){
                        Get-LoremIpsum -Sentences 1
                    }
                }
            }
            #endregion Outputs

            #region Notes
            $OutArray += "`nh{0}. Notes" -f ($HeadingLevel + 1)
            $aliasList = Get-Alias -Definition $Help.Name -ErrorAction SilentlyContinue
            $OutArray += if ($aliasList) {
                'PowerShell includes the following aliases for {0}:' -f "{{$($Help.Name)}}"
                foreach ($alias in $aliasList){
                    '* {0}' -f "{{$($alias.Name)}}"
                }
            } elseif ($LoremIpsum){
                Get-LoremIpsum -Paragraphs 3
            }
            #endregion Notes

            #region Related Links
            $OutArray += "`nh{0}. Related Links" -f ($HeadingLevel + 1)
            $LinkPattern = '* [{0}|{1}]'
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
                            "* $linkText"
                        }
                    }
                }
            } elseif ($LoremIpsum){
                    $linkText = Get-LoremIpsum -Words 2
                    $OutArray += "* [{0}|]" -f $linkText
            }
            #endregion Related Links

            return $OutArray
        }
        #endregion Functions
    }
    Process {
        foreach ($inObj in $InputObject){
            try {
                $Help = Get-Help $inObj -ErrorAction Stop
            } catch {
                throw $_
                exit 1
            }
            $Params = @{
                Help = $Help
                LoremIpsum = $LoremIpsum
                HeadingLevel = $HeadingLevel
            }
            switch ($OutputType){
                Markdown {
                    return Get-Markdown @Params
                }
                ConfluenceWiki {
                    return Get-ConfluenceWiki @Params
                }
            }
        }
    }
}
