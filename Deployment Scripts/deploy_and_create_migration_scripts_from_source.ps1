param(

    [parameter(Mandatory=$false)]
    [string]$Server='pvenkat-test-ws.sql.azuresynapse.net',

    [parameter(Mandatory=$false)]
    [string]$Database='testsqlpool',

    [parameter(Mandatory=$false)]
    [string]$adls_gen2_location='abfss://primary@pvenkattestsa.dfs.core.windows.net/migration/',

    [parameter(Mandatory=$false)]
    [string]$storage_access_token='',

    [parameter(Mandatory=$false)]
    [int]$QueryTimeout = 90,

    [parameter(Mandatory=$false)]
    [bool]$IncludeDropScript = $false,

    [parameter(Mandatory=$false)]
    [bool]$CreateSQlProject = $true,

    [parameter(Mandatory=$false)]
    [bool]$DeploySQlProject = $true,

    [parameter(Mandatory=$false)]
    [string]$dotnet = 'C:\Program Files\dotnet\dotnet.exe',

    [parameter(Mandatory=$false)]
    [bool]$skipViews = $false,

    [parameter(Mandatory=$false)]
    [bool]$skipSp = $false,

    [parameter(Mandatory=$false)]
    [bool]$skipfunctions = $false,
    
    [parameter(Mandatory=$false)]
    [string]$systemDacpacLocation = "c:\Users\pvenkat\.azuredatastudio-insiders\extensions\microsoft.sql-database-projects-1.3.0\BuildDirectory",

    #dotnet add package Microsoft.SqlServer.DacFx --version 162.1.142-preview
    [parameter(Mandatory=$false)]
    [string]$sqlPackageLocation = "C:\Users\pvenkat\Downloads\sqlpackage-win7-x64-en-162.1.143.0\SqlPackage.exe",

    [parameter(Mandatory=$false)]
    [string]$targetServerName = "x6eps4xrq2xudenlfv6naeo3i4-bmmuvve2hnru3anhfqidprgjai.msit-datawarehouse.pbidedicated.windows.net",

    [parameter(Mandatory=$false)]
    [string]$targetDatabase = "sqlpackagetest6",
    
    [parameter(Mandatory=$false)]
    [bool]$extractDataFromSource = $true,

    [parameter(Mandatory=$false)]
    [bool]$exportDataToTarget = $true
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

    function execute-query
    {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true, Position=0)]
            [string] $connectionString,

            [Parameter(Mandatory=$true, Position=1)]
            [string] $query,

            [Parameter(Mandatory=$true, Position=2)]
            [string] $accessToken            
        )

        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.AccessToken = $accessToken
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $result = $command.ExecuteReader()    
        $table = new-object "System.Data.DataTable"

        $table.Load($result)
        $connection.Close()
        return $table
    }
    
    try {
        
        #Initializing paths
        $DeploymentScriptsFolderPath = Split-Path -parent $MyInvocation.MyCommand.Path
        $DeploymentScriptsFolderPath = $DeploymentScriptsFolderPath +"\"
        $resourceXmlPath = Join-Path -Path $DeploymentScriptsFolderPath  -ChildPath "Resources" | Join-Path -ChildPath "sqlproject.xml"
        $MigrationProjectPath = (get-item $DeploymentScriptsFolderPath ).parent.FullName + "\"
        $SqlCmdScriptFolderPath = Join-Path -Path $MigrationProjectPath  -ChildPath "Scripts"
        Remove-Item (Join-Path -Path $MigrationProjectPath  -ChildPath "Output") -Recurse -Force -Confirm:$false
        $TargetFolderPath = $MigrationProjectPath + "Output\SSDT_$($([System.Datetime]::Now.ToString("yyyyMMddhhmmss")))\" #Join-Path -Path $MigrationProjectPath  -ChildPath "Output\" | Join-Path -ChildPath "SSDT_$($([System.Datetime]::Now.ToString("yyyyMMddhhmmss")))"
        $targetConnectionString = "Server=$targetServerName;Initial Catalog=$targetDatabase;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        
        $targetDir = mkdir $TargetFolderPath
        
        #Setting up connection string
        Connect-AzAccount
        $token_context = (Get-AzAccessToken -ResourceUrl https://database.windows.net/)
        $token = $token_context.Token

        $token_expiry_local_time = $token_context.ExpiresOn.LocalDateTime

        $connectionString = "Server=$Server;Initial Catalog=$Database;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"

        if (Test-Path -Path $SqlCmdScriptFolderPath)
        {
            Write-Host "==============================================================================";
            Write-Host "Calling Invoke-SqlCmd with the following parameters:";
            Write-Host "Source Server:                $Server";
            Write-Host "Source Database:              $Database";
            Write-Host "Target Connection string:     $targetConnectionString"
            Write-Host "TargetFolderPath:             $TargetFolderPath";
            Write-Host "==============================================================================";
            Write-Host ""

            Write-Host "Installing & importing dependecies if not available...."
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
            Write-Host ""

            Write-Host "Deploying SQL Scripts to extract DDL & DML from Source..."
            $SqlCmdFiles = Get-ChildItem -Path $SqlCmdScriptFolderPath -Recurse -Include *.sql;

            Write-Host "Deploying :   $(Split-Path -Leaf "$SqlCmdScriptFolderPath\Create_Schema.sql")";
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile "$SqlCmdScriptFolderPath\Create_Schema.sql"
            
            # Deploying Migration scripts
            foreach ($SqlCmdFile in $SqlCmdFiles) {
            
                Write-Host "Deploying :   $(Split-Path -Leaf $SqlCmdFile)";
                Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $SqlCmdFile
            }

            # Extracting Schema
            $inputQuery = "EXEC migration.SynapseMigration_ExtractSchemas"
            Write-Host "Extracting Schemas from source: '$inputQuery'"
            #$schema_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
            $schema_results = execute-query -connectionString $connectionString -query $inputQuery -accessToken $token
            
            # Create schema folder
            mkdir $TargetFolderPath'Schemas' | Out-Null
            foreach($name in $schema_results)
            {
                $schemaName =  $name.SchName
                $createSchemaScript = $name.Script
                $dropStatement = $name.DropStatement
                
                if($schemaName -ne 'dbo') {                      
                    if($IncludeDropScript -eq $false) {
                        Set-Content -Path $TargetFolderPath'Schemas\'$schemaName'.sql' -Value $createSchemaScript
                    } else {
                        Set-Content -Path $TargetFolderPath'Schemas\'$schemaName'.sql' -Value $dropStatement"`r`nGO`r`n"$createSchemaScript
                    }
                    
                } else {
                    Set-Content -Path $TargetFolderPath'Schemas\'$schemaName'.sql' -Value "`r`nGO`r`n"
                }
                
                mkdir $TargetFolderPath$schemaName | Out-Null
                mkdir $TargetFolderPath$schemaName'\Tables' | Out-Null
                mkdir $TargetFolderPath$schemaName'\Views' | Out-Null
                mkdir $TargetFolderPath$schemaName'\Functions' | Out-Null
                mkdir $TargetFolderPath$schemaName'\Stored Procedures' | Out-Null
                mkdir $TargetFolderPath$schemaName'\External Tables' | Out-Null
                mkdir $TargetFolderPath$schemaName'\Copy INTO' | Out-Null
            }

            # Extracting DDL
            $inputQuery = "EXEC migration.SynapseMigration_ExtractAllDDL"
            Write-Host "Extracting table definition from source compatible with Fabric DW: '$inputQuery'"
            $ddl_results = execute-query -connectionString $connectionString -query $inputQuery -accessToken $token       

            # Create table scripts
            foreach($row in $ddl_results)
            {
                $tableName = $row.objName
                $schemaName = $row.SchName
                $ddlScript = $row.Script
                $dropStatement = $row.DropStatement
                if($IncludeDropScript -eq $false) {
                Set-Content -Path $TargetFolderPath$schemaName'\Tables\'$tableName'.sql' -Value $ddlScript
                } else {
                    Set-Content -Path $TargetFolderPath$schemaName'\Tables\'$tableName'.sql' -Value $dropStatement"`r`nGO`r`n"$ddlScript
                }

            }
            
            if($skipViews -eq $false) {
                # Extracting Views
                $inputQuery = "EXEC migration.SynapseMigration_ExtractAllViews"
                Write-Host "Extracting view definition from source: '$inputQuery'"
                $view_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
            
                # Create view scripts
                foreach($row in $view_results)
                {
                    $objName = $row.objName
                    $schemaName = $row.SchName
                    $viewScript = $row.Script
                    $dropStatement = $row.DropStatement
                    if($IncludeDropScript -eq $false) {
                        Set-Content -Path $TargetFolderPath$schemaName'\Views\'$objName'.sql' -Value $viewScript
                    } else {
                        Set-Content -Path $TargetFolderPath$schemaName'\Views\'$objName'.sql' -Value $dropStatement"`r`nGO`r`n"$viewScript
                    }
                }
            }
            
            if($skipSp -eq $false) {
                # Extracting stored procedures
                $inputQuery = "EXEC migration.SynapseMigration_ExtractAllSP"
                Write-Host "Extracting stored procedures definition from source: '$inputQuery'"
                $sp_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
            
                # Create stored procedure scripts
                foreach($row in $sp_results)
                {
                    $objName = $row.objName
                    $schemaName = $row.SchName
                    $spScript = $row.Script
                    $dropStatement = $row.DropStatement
                    if($IncludeDropScript -eq $false) {
                        Set-Content -Path $TargetFolderPath$schemaName'\Stored Procedures\'$objName'.sql' -Value $spScript
                    } else {
                        Set-Content -Path $TargetFolderPath$schemaName'\Stored Procedures\'$objName'.sql' -Value $dropStatement"`r`nGO`r`n"$spScript
                    }
                }
            }

            if($skipfunctions -eq $false) {
                # Extracting functions
                $inputQuery = "EXEC migration.SynapseMigration_ExtractAllFunctions"
                Write-Host "Extracting function definitions from source: '$inputQuery'"
                $fn_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
                
                # Create function scripts
                foreach($row in $fn_results)
                {
                    $objName = $row.objName
                    $schemaName = $row.SchName
                    $fnScript = $row.Script
                    $dropStatement = $row.DropStatement
                    if($IncludeDropScript -eq $false) {
                        Set-Content -Path $TargetFolderPath$schemaName'\Functions\'$objName'.sql' -Value $fnScript
                    } else {
                        Set-Content -Path $TargetFolderPath$schemaName'\Functions\'$objName'.sql' -Value $dropStatement"`r`nGO`r`n"$fnScript
                    }
                }
            }
            Write-Host ""

            if($CreateSQlProject -eq $true) {                
                Write-Host "Creating a SQL Project of Target type - SqlDwUnifiedDatabaseSchemaProvider"
                $ssdtString =   [XML](Get-Content $resourceXmlPath)
                $ssdtString.save($TargetFolderPath+'dwssdt.sqlproj')
                
                if($DeploySQlProject -eq $true){

                    try {
                        Write-Host "Building DACPAC file"
                        $buildFolder = $TargetFolderPath+'dwssdt.sqlproj'
                        & $dotnet build $buildFolder /p:NetCoreBuild=true /p:SystemDacpacsLocation=$systemDacpacLocation
                        
                        
                        Write-Host "Deplying DACPAC file to target"
                        $deploymentFolder = $TargetFolderPath+'bin\Debug\dwssdt.dacpac'
                        & $sqlPackageLocation /Action:Publish /SourceFile:$deploymentFolder `
                        /TargetConnectionString:$targetConnectionString /at:$token

                    } catch {
                        $string_err = $_ | Out-String
                        throw $string_err
                    }
                }
            }
            Write-Host ""

            if($extractDataFromSource -eq $true) {
                # Running data extract script
                $inputQuery = "EXEC migration.sp_cetas_extract_script @adls_gen2_location='$adls_gen2_location', @storage_access_token = '$storage_access_token'"
                $cetas_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery

                $extract_errors = @()
                foreach($row in $cetas_results)
                {
                    #Refresh Token if required
                    if((Get-Date).AddHours(.1) -gt $token_expiry_local_time)
                    {
                        $token_context = (Get-AzAccessToken -ResourceUrl https://database.windows.net/)
                        $token_expiry_local_time = $token_context.ExpiresOn.LocalDateTime
                        $token = $token_context.Token

                        Write-Host "Refreshing token...."
                    }

                    $tableName = $row.objName
                    $schemaName = $row.SchName
                    $cetas = $row.data_extract_statement
                    $dropStatement = $row.DropStatement
                    $filePath = $TargetFolderPath+$schemaName+'\External Tables\'+$tableName+'.sql'
                    Set-Content -Path $TargetFolderPath$schemaName'\External Tables\'$tableName'.sql' -Value $dropStatement"`r`nGO`r`n"$cetas

                    Write-Host "Extracting data - $schemaName.$tableName..."
                    try {                    
                    Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $filePath
                    } 
                    catch {
                        $string_err = $_ | Out-String
                        $extract_errors += "$schemaName.$tableName -> $string_err"
                    }
                }
                if($extract_errors.Length -gt 0){
                    Write-Host "Errors in extracting data to storage account for following tables: " -ForegroundColor Red -BackgroundColor Yellow
                    Write-Host $extract_errors -ForegroundColor Red -BackgroundColor Yellow
                }
            }

            if($exportDataToTarget -eq $true) {
            
                # Generating data extract script
                $inputQuery = "EXEC migration.generate_data_extract_and_data_load_statements @storage_access_token = '$storage_access_token', @external_data_source_base_location = '$adls_gen2_location'"
                $copyinto_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery

                $load_errors = @()               

                foreach($row in $copyinto_results)
                {
                    #Refresh Token if required
                    if((Get-Date).AddHours(.1) -gt $token_expiry_local_time)
                    {
                        $token_context = (Get-AzAccessToken -ResourceUrl https://database.windows.net/)
                        $token_expiry_local_time = $token_context.ExpiresOn.LocalDateTime
                        $token = $token_context.Token

                        Write-Host "Refreshing token...."
                    }

                    $tableName = $row.objName
                    $schemaName = $row.SchName
                    $copyinto = $row.data_load_statement
                    Set-Content -Path $TargetFolderPath$schemaName'\Copy INTO\'$tableName'.sql' -Value $copyinto
                    $filePath = $TargetFolderPath+$schemaName+'\Copy INTO\'+$tableName+'.sql'
                    
                    Write-Host "loading $schemaName.$tableName data..."
                    try {                    
                        Invoke-Sqlcmd -ServerInstance $targetServerName -Database $targetDatabase -AccessToken $token -InputFile $filePath
                    } 
                    catch {
                        $string_err1 = $_ | Out-String
                        $load_errors += "$schemaName.$tableName -> $string_err1"
                    }
                }
                if($load_errors.Length -gt 0){
                    Write-Host "Errors loading data from storage account to target Fabric DW: " -ForegroundColor Red -BackgroundColor Yellow
                    Write-Host $load_errors -ForegroundColor Red -BackgroundColor Yellow
                }
            }
        } else {
            Write-Error "SQL Scripts Folder does not exist: $SqlCmdScriptFolderPath";
            exit 1;
        }
    } catch {
        Write-Error $_;
    } finally {
        Clear-AzContext -Scope CurrentUser -Force
    }
    Stop-Transcript
