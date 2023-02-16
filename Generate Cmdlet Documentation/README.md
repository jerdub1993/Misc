# CmdletDocumentation
For automating making Cmdlet Documentation from PowerShell's [comment-based help](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help). The better the comment-based help on the command/function/script, the better the documentation. Use the `-LoremIpsum` parameter to populate the documentation with random filler text.

Output can be returned in [Markdown language](https://www.markdownguide.org/cheat-sheet/) or in [Confluence Wiki](https://confluence.atlassian.com/doc/confluence-wiki-markup-251003035.html) format.

Everything below was drafted using the following command:

    Get-Command -Name New-CmdletDocumentation | New-CmdletDocumentation -OutputType Markdown -HeadingLevel 2 | Out-File -FilePath README.md

## New-CmdletDocumentation
Automatically generates documentation for a command, function, or script.

### Syntax
```PowerShell
New-CmdletDocumentation
    -InputObject <Object[]>
    -OutputType <String>
    [-HeadingLevel <Int32>]
    [-LoremIpsum]
```

### Description
New-CmdletDocumentation will generate the documentation for a command, function, or script from PowerShell's builtin comment-based help. It will return the documentation formatted in either Markdown language or Confluence Wiki.

### Examples

#### Example 1
```PowerShell
Get-Command Get-Service | New-CmdletDocumentation -OutputType Markdown | Out-File Get-Service.md
```

This command generates the documentation in Markdown language for the Get-Service command and outputs to the Get-Service.md file.

#### Example 2
```PowerShell
New-CmdletDocumentation -InputObject MyScript.ps1 -OutputType ConfluenceWiki
```

This command generates the documentation in Confluence Wiki format for the MyScript.ps1 script.

#### Example 3
```PowerShell
New-CmdletDocumentation -InputObject Get-Help -OutputType ConfluenceWiki -LoremIpsum
```

This command generates the documentation in Confluence Wiki format for the Get-Help command, and adds filler text (LoremIpsum).

#### Example 4
```PowerShell
Get-Command MyFunction | New-CmdletDocumentation -OutputType Markdown -HeadingLevel 2 | Out-File MyFunction.md
```

This command generates the documentation in Markdown language, with headings starting at H2, for the MyFunction function and outputs to the MyFunction.md file.

### Parameters

#### **-InputObject**
&ensp;&ensp;&ensp;&ensp;The InputObject parameter can take a function, command, or script--essentially anything that can be passed to the Get-Help command.

| Attribute | Value |
| --- | --- |
| Type | Object[] |
| Position | 1 |
| Default value | None |
| AcceptPipelineInput | True |

#### **-OutputType**
&ensp;&ensp;&ensp;&ensp;The type of output desired. Options are 'Markdown' or 'ConfluenceWiki'.

| Attribute | Value |
| --- | --- |
| Type | String |
| Position | 2 |
| Default value | None |
| AcceptPipelineInput | False |

#### **-LoremIpsum**
&ensp;&ensp;&ensp;&ensp;A switch parameter; if true, will populate any empty/blank sections with filler-text.

| Attribute | Value |
| --- | --- |
| Type | SwitchParameter |
| Position | Named |
| Default value | False |
| AcceptPipelineInput | False |

#### **-HeadingLevel**
&ensp;&ensp;&ensp;&ensp;Specifies the heading level (H1, H2, etc.) at which to start. Default is 1 (H1).

| Attribute | Value |
| --- | --- |
| Type | Int32 |
| Position | 3 |
| Default value | 1 |
| AcceptPipelineInput | False |

### Inputs

##### [**Int32**](https://learn.microsoft.com/en-us/dotnet/api/System.Int32)

##### [**Object**](https://learn.microsoft.com/en-us/dotnet/api/System.Object)

##### [**String**](https://learn.microsoft.com/en-us/dotnet/api/System.String)

### Outputs

##### [**String**](https://learn.microsoft.com/en-us/dotnet/api/System.String)

### Notes

### Related Links
- [New-CmdletDocumentation](https://github.com/jerdub1993/Misc/tree/main/Generate%20Cmdlet%20Documentation)
- [Confluence Wiki syntax](https://confluence.atlassian.com/doc/confluence-wiki-markup-251003035.html)
- [Markdown syntax](https://www.markdownguide.org/cheat-sheet/)
- [PowerShell Comment-Based Help](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help)