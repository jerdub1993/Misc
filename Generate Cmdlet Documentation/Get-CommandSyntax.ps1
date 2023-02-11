function Get-Syntax {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject'
    )]
    param (
        [Parameter(
            ParameterSetName = 'InputObject',
            Mandatory = $true
        )]
        [string]$InputObject,
        [Parameter(
            ParameterSetName = 'Command',
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [Object]$Command
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
        $Help = switch ($PSCmdlet.ParameterSetName){
            InputObject {
                Get-Help $InputObject
            }
            Command     {
                if ($Command.GetType() -notin [System.Management.Automation.FunctionInfo],[System.Management.Automation.CmdletInfo]){
                    throw [System.Management.Automation.ParameterBindingException] "Cannot process argument transformation on parameter 'Command'. Cannot convert the `"$($Command)`" value of type `"$($Command.GetType().FullName)`" to type `"System.Management.Automation.FunctionInfo`" or `"System.Management.Automation.CmdletInfo`"."
                    exit 1
                }
                Get-Help $Command
            }
        }
        $Parameters = $Help.Parameters.Parameter
        $ParameterSets = switch ($Help.Category){
            ExternalScript  {
                [PSCustomObject]@{
                    Name = 'All'
                    Parameters = Get-ParameterSet -Parameters $Parameters
                }
            }
            Default         {
                $Group = $Parameters | Group-Object -Property ParameterSetName
                foreach ($set in $Group){
                    $name = if ($set.Name -match '^\(All\)$'){
                        'All'
                    } else {
                        $set.Name
                    }
                    [PSCustomObject]@{
                        Name = $name
                        Parameters = Get-ParameterSet -Parameters $set.Group
                    }
                }
            }
        }
        return [PSCustomObject]@{
            Command = $Help.Name
            ParameterSets = $ParameterSets
        }
    }
}