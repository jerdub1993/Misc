function prompt {
    <#
        End goal:

        ┌──(<username><@repository>)-[<Present Working Directory>]
        └─$ 
    #>
    $ESC = [char]27
    $RtAngleDown = [char]9484
    $RtAngleUp = [char]9492
    $Dash = [char]9472

    # Full color list: https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#text-formatting
    $LineColor   = "[92m"   # Bright Green
    $BaseColor   = "[94m"   # Bright Blue
    $AccentColor = "[0m"    # Uncolored
    $PWDColor    = $AccentColor
    $RepoColor   = $BaseColor

    # If current directory is a Git repository, add "@reponame" to the prompt
    $RepoString = try {
        $TopLevel = git rev-parse --show-toplevel
        if (!$LASTEXITCODE){
            "{0}{1}@{0}{2}{3}" -f $ESC, $AccentColor, $RepoColor, (Get-Item $TopLevel).Basename
        }
    } catch {
        ""
    }

    # If current directory is the user's profile directory, path will be simply "~"; otherwise, it will be the PWD
    $PWDPath = switch ($pwd.Path){
        $env:USERPROFILE {"~"}
        Default {$_}
    }
    $String = "`n{0}{1}{5}{7}{7}{0}{2}({0}{3}{8}{10}{0}{2})-[{0}{4}{9}{0}{2}]`n{0}{1}{6}{7}{0}{3}`${0}{2} " -f $ESC, $LineColor, $AccentColor, $BaseColor, $PWDColor, $RtAngleDown, $RtAngleUp, $Dash, '{0}', '{1}', $RepoString
    $String -f $env:USERNAME, $PWDPath
}