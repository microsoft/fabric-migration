<#
Known Issues

1. tables with sys.sysnames datatypes are not supported
2. tables with nchar/char/nvarchar/varchar of max is not supported
3. Limitation - The name of the database should be same in Microsoft Fabric DW for naming consistency used in views. 
   People often use 3 part naming convention and it may break the deployment
#>

param(

    # If windows, use C:\Data\sqlfiles. if Linux use /home/pvenkat/data/
    [parameter(Mandatory=$false)]
    [string]$SourceFolderPath="C:\Users\pvenkat\test_db_scripts\",

    [parameter(Mandatory=$false)]
    [string]$Server='x6eps4xrq2xudenlfv6naeo3i4-bmmuvve2hnru3anhfqidprgjai.msit-datawarehouse.pbidedicated.windows.net',

    [parameter(Mandatory=$false)]
    [string]$Database='testsqlpool',

    [parameter(Mandatory=$false)]
    [int]$QueryTimeout = 90
)

$logpath = "C:\logs\$($([System.Datetime]::Now.ToString("MMddyyyyhhmmssmmm"))).txt"
Start-Transcript -Path $logpath
<#
	.SYNOPSIS
    Run all SQL Scripts in folder in SQLCMD mode, passing in an array of SQLCMD variables if supplied.

    .DESCRIPTION
    Run all SQL Scripts in folder in SQLCMD mode, passing in an array of SQLCMD variables if supplied.

    .NOTES
    Script written by (c) Dr. John Tunnicliffe, 2019 https://github.com/DrJohnT/AzureDevOpsExtensionsForSqlServer/tree/master/extensions/RunSqlCmdScripts
	This PowerShell script is released under the MIT license http://www.opensource.org/licenses/MIT
#>
    $global:ErrorActionPreference = 'Stop';

    if ($env:Processor_Architecture -eq 'x86') {
        Write-Error "The SQLSERVER PowerShell module will not run correctly in when the processor architecture = x86. Please use a 64-bit Azure DevOps agent. See https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-windows?view=azure-devops";
        exit 1;
    }

    function Get-Script
    {
        param (
            [string] $filePath
        )

        $fileContent = Get-Content $filePath | Select-Object -Skip 2
        return $fileContent
    }

    function Confirm-Script
    {
        param (
            [string] $queryText
        )
        
        $queryText = $queryText.Replace("'","''")   

        $query = 
@"
BEGIN TRY
    SET PARSEONLY ON;    
    EXEC('<<REPLACE>>')
    SET PARSEONLY OFF;
END TRY
BEGIN CATCH
    DECLARE 
    @ErrorMessage  VARCHAR(8000), 
    @ErrorSeverity INT, 
    @ErrorState    INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(), 
        @ErrorSeverity = ERROR_SEVERITY(), 
        @ErrorState = ERROR_STATE();
    
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

END CATCH
"@
        $ErrorMessage = ""
        $query = $query.Replace("<<REPLACE>>", $queryText)
        try {
            Write-Host $query
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $query
        }
        catch {
            # Handle the error
    $err = $_.Exception
    #There could possibly be multiple inner exceptions but not in this example. 
    while( $err.InnerException ) 
        {
            $err = $err.InnerException
            #Write-Host "InnerException: $($err.Message)" 
            $ErrorMessage = $err.Message
        }
        
        }
        return $ErrorMessage

    }

    try {

        #Error Log
        $error_log = New-Object System.Data.DataTable
        $error_log.Columns.Add("Schema", "System.String") | Out-Null
        $error_log.Columns.Add("Error", "System.String") | Out-Null
        $error_log.Columns.Add("ScriptPath", "System.String") | Out-Null
        
        #User Authentication
        Connect-AzAccount
        $token = (Get-AzAccessToken -ResourceUrl https://database.windows.net/).Token

        if (Test-Path -Path $SourceFolderPath)
        {
            Write-Host "==============================================================================";
            Write-Host "Calling Invoke-SqlCmd with the following parameters:";
            Write-Host "Server:                $Server";
            Write-Host "Database:              $Database";
            Write-Host "AuthenticationUser:    $user";
            Write-Host "TargetFolderPath:      $SourceFolderPath";
            Write-Host "==============================================================================";
            Write-Host ""

            # ensure SqlServer module is installed
            $Name = 'SqlServer';
            if (!(Get-Module -ListAvailable -Name $Name)) {
                # if module is not installed
                Write-Output "Installing PowerShell module $Name for current user"
                Install-PackageProvider -Name NuGet -Force -Scope CurrentUser;
                Install-Module -Name $Name -Force -AllowClobber -Scope CurrentUser -Repository PSGallery -SkipPublisherCheck;
            }

            if (-not (Get-Module -Name $Name)) {
                # if module is not loaded
                Import-Module -Name $Name -DisableNameChecking;
            }
            $Name = 'Az.Accounts'
            if (!(Get-Module -ListAvailable -Name $Name)) {
                # if module is not installed
                Write-Output "Installing PowerShell module $Name for current user"
                Install-PackageProvider -Name NuGet -Force -Scope CurrentUser;
                Install-Module -Name $Name -MinimumVersion 2.2.0 -Force -AllowClobber -Scope CurrentUser -Repository PSGallery -SkipPublisherCheck;
            }

            if (-not (Get-Module -Name $Name)) {
                # if module is not loaded
                Import-Module -Name $Name -MinimumVersion 2.2.0 -DisableNameChecking;
            }

           
            
            # Write-Host "Creating Schemas in the target database"
            
            # foreach ($Schema in (Get-ChildItem -Path $SourceFolderPath"Schemas\")) {
            #     Write-Host "Creating Schema: "$SourceFolderPath"Schemas\"$Schema
            #     Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $SourceFolderPath"Schemas\"$Schema
            # }
            
            Write-Host "`nExecuting DDL statements on target database"
            foreach($schema in (Get-ChildItem -Path $SourceFolderPath -Exclude "Schemas" -Directory)) {
                
                # foreach($Table in (Get-ChildItem -Path $Schema"\Tables\")) {
                #     Write-Host "Creating Table: "$Table " in " $(Split-Path -Leaf $Schema)
                #     $path = "$($SourceFolderPath)$($Schema.Name)\Tables\$($Table)"
                #     Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $path
                # }

                # foreach($View in (Get-ChildItem -Path $Schema"\Views\")) {
                #     Write-Host "Creating View: "$View " in " $(Split-Path -Leaf $Schema)
                #     $path = "$($SourceFolderPath)$($Schema.Name)\Views\$($View)"
                #     Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $path
                # }

                foreach($Sp in (Get-ChildItem -Path $Schema"\Stored Procedures\")) {
                    Write-Host "Creating Stored Procedure: "$Sp " in " $(Split-Path -Leaf $Schema)
                    $path = "$($SourceFolderPath)$($Schema.Name)\Stored Procedures\$($Sp)"
                    $fileContent = Get-Script $path                    
                    $Scriptmsg = Confirm-Script -queryText $fileContent
                    Write-Host "Error Message: $($Scriptmsg)"
                    if([string]::IsNullOrEmpty($Scriptmsg)) {
                        
                        try {
                            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $path 
                        }
                        catch {
                            $nRow = $error_log.NewRow()
                            $nRow.Schema = $Schema.Name
                            $nRow.Error = $path
                            $nRow.ScriptPath = $_.Exception.Message
                            $error_log.Rows.Add($nRow)
                        }
                    } 
                    else {                        
                        $nRow = $error_log.NewRow()
                        $nRow.Schema = $Schema.Name
                        $nRow.Error = $Scriptmsg
                        $nRow.ScriptPath = $path
                        $error_log.Rows.Add($nRow)                        
                    }
                }

                # Foreach ($row in $error_log)
                # {
                #     Write-Host "Schema: $($row.Schema)"
                #     Write-Host "Schema: $($row.Error)"
                #     Write-Host "Schema: $($row.ScriptPath)"
                # }

                # foreach($Fnc in (Get-ChildItem -Path $Schema"\Functions\")) {
                #     Write-Host "Creating Function: "$Fnc " in " $(Split-Path -Leaf $Schema)
                #     # Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $Fnc
                # }
            }

            Write-Host "`nCopying data to target database"
            foreach($Schema in (Get-ChildItem -Path $SourceFolderPath -Exclude "Schemas" -Directory)) {
                
                foreach($Table in (Get-ChildItem -Path $Schema"\Copy INTO\")) {
                    Write-Host "COPY INTO: "$Table " in " $(Split-Path -Leaf $Schema)
                    # Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $Table
                }
            }

            Write-Host "==============================================================================";
        } else {
            Write-Error "SQL Scripts Folder does not exist: $SourceFolderPath";
            exit 1;
        }
    } catch {
        Write-Error $_;
    }
    Stop-Transcript
