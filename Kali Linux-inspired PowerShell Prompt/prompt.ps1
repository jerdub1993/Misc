function prompt {
    <#
        End goal:

        ┌──(<username><@repository>)-[<Present Working Directory>]
        └─$ 
    #>
    $LineColor = "[92m" # Bright Green
    $BaseColor = "[94m" # Bright Blue
    $AccentColor = "[0m" # Uncolored
    $PWDColor = "[93m" # Bright Yellow
    $RepoColor = $BaseColor
    $ESC = [char]27
    $RepoString = try {
        git status *>$null
        if (!$LASTEXITCODE){
            "{0}{1}@{0}{2}{3}" -f $ESC, $AccentColor, $RepoColor, (Get-Item (git rev-parse --show-toplevel)).Basename
        }
    } catch {
        ""
    }
    $PWDPath = if ($pwd.Path -eq $USERPROFILE){
        "~"
    } else {
        $pwd.Path
    }
    $String = "`n{0}{1}┌──{0}{2}({0}{3}{5}{7}{0}{2})-[{0}{4}{6}{0}{2}]`n{0}{1}└─{0}{3}`${0}{2} " -f $ESC, $LineColor, $AccentColor, $BaseColor, $PWDColor, '{0}', '{1}', $RepoString
    $String -f $USERNAME, $PWDPath
}