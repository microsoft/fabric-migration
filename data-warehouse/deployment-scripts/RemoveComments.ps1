function Remove-Comments
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $queryText
    )
    
    try {
        Add-Type -Path "C:\Users\pvenkat\source\repos\fabric-migration\TSQLValidation\TSQLValidator\bin\Debug\net7.0\Microsoft.SqlServer.TransactSql.ScriptDom.dll"
        
        $DDLParser = New-Object Microsoft.SqlServer.TransactSql.ScriptDom.TSql150Parser($true)
        $DDLparserErrors = New-Object System.Collections.Generic.List[Microsoft.SqlServer.TransactSql.ScriptDom.ParseError]
        # create a StringReader for the script for parsing
        $stringReader = New-Object System.IO.StringReader($queryText)
        # parse the script
        $tSqlFragment = $DDLParser.Parse($stringReader, [ref]$DDLParsererrors)

        # raise an exception if any parsing errors occur
        if($DDLParsererrors.Count -gt 0) {
            throw "$($DDLParsererrors.Count) parsing error(s): $(($DDLParsererrors | ConvertTo-Json))"
        }
       
    }
    catch {
        throw
    }
}

$fileContent = Get-Content "C:\Users\pvenkat\test_db_scripts\dbo\Stored Procedures\create_external_file_format.sql" -Raw
$consoleAppPath = "C:\Users\pvenkat\source\repos\fabric-migration\TSQLValidation\TSQLValidator\bin\Debug\net7.0\TSQLValidator.exe"
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = $consoleAppPath
$pinfo.RedirectStandardError = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.UseShellExecute = $false

$pinfo.Arguments = """$fileContent"""
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$p.WaitForExit()
Write-Host "stdout:" $p.StandardOutput.ReadToEnd()