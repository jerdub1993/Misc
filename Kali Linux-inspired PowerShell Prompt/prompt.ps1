function prompt {
    <#
        End goal:

        ┌──(<username><@repository>)-[<Present Working Directory>]
        └─$ 
    #>
    $ESC             = [char]27
    $RtAngleDown     = [char]9484
    $RtAngleUp       = [char]9492
    $Dash            = [char]9472

    # Full color list: https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#text-formatting
    $LineColor    = "[92m"   # Bright Green
    $BaseColor    = "[94m"   # Bright Blue
    $AccentColor  = "[0m"    # Uncolored
    $BracketColor = "[93m"    # Uncolored
    $PWDColor     = $AccentColor
    $RepoColor    = $BaseColor

    # If current directory is a Git repository, add "@reponame" to the prompt
    $RepoString = try {
        $TopLevel = git rev-parse --show-toplevel
        if (!$LASTEXITCODE){
            "{0}{1}@{0}{2}{3}" -f $ESC, $AccentColor, $RepoColor, (Get-Item $TopLevel).Basename
        }
    } catch {
        ""
    }

    # Replace the user's profile directory in path with "~"
    $PWDPath = $pwd.path -replace $env:USERPROFILE.replace('\','\\'), "~"

    $String = "`n{0}{1}{6}{8}{8}{0}{5}({0}{3}{9}{11}{0}{5}){0}{2}-{0}{5}[{0}{4}{10}{0}{5}]`n{0}{1}{7}{8}{0}{3}`${0}{2} " -f $ESC, $LineColor, $AccentColor, $BaseColor, $PWDColor, $BracketColor, $RtAngleDown, $RtAngleUp, $Dash, '{0}', '{1}', $RepoString
    $String -f $env:USERNAME, $PWDPath
}