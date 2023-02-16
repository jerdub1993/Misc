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