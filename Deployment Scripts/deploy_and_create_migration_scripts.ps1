param(

    # If windows, use C:\Data\sqlfiles. if Linux use /home/pvenkat/data/
    [parameter(Mandatory=$false)]
    [string]$SqlCmdSciptFolderPath="C:\Users\pvenkat\source\repos\fabric-migration\Scripts\",

    [parameter(Mandatory=$false)]
    [string]$TargetFolderPath="C:\Users\pvenkat\source\repos\fabric-migration\",

    [parameter(Mandatory=$false)]
    [string]$Server='pvenkat-test-ws.sql.azuresynapse.net',

    [parameter(Mandatory=$false)]
    [string]$Database='testsqlpool',

    [parameter(Mandatory=$false)]
    [string]$Recursive='true',

    [parameter(Mandatory=$false)]
    [string]$adls_gen2_location='abfss://primary@pvenkattestsa.dfs.core.windows.net/migration/',

    [parameter(Mandatory=$false)]
    [string]$storage_access_token='',

    [parameter(Mandatory=$false)]
    [int]$QueryTimeout = 90
)
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

    try {
        if (Test-Path -Path $SqlCmdSciptFolderPath)
        {
            Write-Host "==============================================================================";
            Write-Host "Calling Invoke-SqlCmd with the following parameters:";
            Write-Host "Server:                $Server";
            Write-Host "Database:              $Database";
            Write-Host "SqlCmdSciptFolderPath: $SqlCmdSciptFolderPath";
            Write-Host "Recursive:             $Recursive";
            Write-Host "AuthenticationUser:    $AuthenticationUser";
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


            Write-Host "SQLCMD folder:         $SqlCmdSciptFolderPath";
            if ($Recursive -eq 'true') {
                $SqlCmdFiles = Get-ChildItem -Path $SqlCmdSciptFolderPath -Recurse -Include *.sql;
            } else {
                $SqlCmdFiles = Get-ChildItem -Path "$SqlCmdSciptFolderPath\*" -Include *.sql;
            }

            #User Authentication
            $user = whoami /upn
            $token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token

            # Now Invoke-Sqlcmd for each script in the folder
            foreach ($SqlCmdFile in $SqlCmdFiles) {
                Write-Host "Running SQLCMD file:   $(Split-Path -Leaf $SqlCmdFile)";

                Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $SqlCmdFile
                Write-Host ""
            }
            
            $inputQuery = "dbo.sp_cetas_extract_script @adls_gen2_location='$adls_gen2_location', @storage_access_token = '$storage_access_token'"
            Write-Host "Running stored procedure: '$inputQuery'"
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
            
            
            $inputQuery = "EXEC dbo.generate_data_extract_and_data_load_statements @storage_access_token = '$storage_access_token', @external_data_source_base_location = '$adls_gen2_location'"
            Write-Host "Running stored procedure: '$inputQuery'"
            $results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
            
            foreach($name in $results | Select-Object  SchName -Unique)
            {
                $schemaName =  $name.SchName
                if (Test-Path $TargetFolderPath$schemaName) {
                    Remove-Item $TargetFolderPath$schemaName -verbose
                }
                New-Item -Path $TargetFolderPath$schemaName -ItemType Directory             
            }

            foreach($row in $results)
            {
                $tableName = $row.tblName
                $schemaName = $row.SchName
                $cetas = $row.data_extract_statement
                $copyinto = $row.data_load_statement
                Set-Content -Path $TargetFolderPath$schemaName'\'$tableName'_cetas.sql' -Value $cetas
                Set-Content -Path $TargetFolderPath$schemaName'\'$tableName'_copy_into.sql' -Value $copyinto
            }

            #$results | Export-Csv -Path "sproc.csv" -NoTypeInformation

            Write-Host "==============================================================================";
        } else {
            Write-Error "SQL Scripts Folder does not exist: $SqlCmdSciptFolderPath";
            exit 1;
        }
    } catch {
        Write-Error $_;
    }



