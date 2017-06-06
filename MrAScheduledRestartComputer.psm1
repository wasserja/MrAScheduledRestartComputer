foreach ($file in Get-ChildItem $PSScriptRoot\*.ps1) {
    $ExecutionContext.InvokeCommand.InvokeScript(
        $false, 
        (
            [scriptblock]::Create(
                [io.file]::ReadAllText(
                    $file.FullName,
                    [Text.Encoding]::UTF8
                )
            )
        ), 
        $null, 
        $null
    )
}