param(

    # If windows, use C:\Data\sqlfiles. if Linux use /home/pvenkat/data/
    [parameter(Mandatory=$false)]
    [string]$SqlCmdSciptFolderPath="C:\Users\pvenkat\source\repos\fabric-migration\Scripts\",

    [parameter(Mandatory=$false)]
    [string]$TargetFolderPath="C:\Users\pvenkat\test_db_scripts\",

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
        
        Remove-Item $TargetFolderPath -Recurse -Force -Confirm:$false
        
        #Setting up connection string
        Connect-AzAccount
        $token = (Get-AzAccessToken -ResourceUrl https://database.windows.net/).Token
        $connectionString = "Server=$Server;Initial Catalog=$Database;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"

        if (Test-Path -Path $SqlCmdSciptFolderPath)
        {
            Write-Host "==============================================================================";
            Write-Host "Calling Invoke-SqlCmd with the following parameters:";
            Write-Host "Server:                $Server";
            Write-Host "Database:              $Database";
            Write-Host "SqlCmdSciptFolderPath: $SqlCmdSciptFolderPath";
            Write-Host "Recursive:             $Recursive";
            Write-Host "AuthenticationUser:    $user";
            Write-Host "TargetFolderPath:      $TargetFolderPath";
            Write-Host "Adls_gen2_location:    $adls_gen2_location";
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


            Write-Host "SQLCMD folder:         $SqlCmdSciptFolderPath";
            if ($Recursive -eq 'true') {
                $SqlCmdFiles = Get-ChildItem -Path $SqlCmdSciptFolderPath -Recurse -Include *.sql;
            } else {
                $SqlCmdFiles = Get-ChildItem -Path "$SqlCmdSciptFolderPath\*" -Include *.sql;
            }

            Write-Host "Running SQLCMD file:   $(Split-Path -Leaf "$SqlCmdSciptFolderPath\Create_Schema.sql")";
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile "$SqlCmdSciptFolderPath\Create_Schema.sql"
            
            # Deploying Migration scripts
            foreach ($SqlCmdFile in $SqlCmdFiles) {
            
                Write-Host "Running SQLCMD file:   $(Split-Path -Leaf $SqlCmdFile)";
                Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $SqlCmdFile
            }

            # Extracting Schema
            $inputQuery = "EXEC migration.SynapseMigration_ExtractSchemas"
            Write-Host "Running stored procedure: '$inputQuery'"
            #$schema_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
            $schema_results = execute-query -connectionString $connectionString -query $inputQuery -accessToken $token
            
            # Create schema folder
            New-Item -Path $TargetFolderPath'Schemas' -ItemType Directory
            foreach($name in $schema_results)
            {
                $schemaName =  $name.SchName
                $createSchemaScript = $name.Script
                $dropStatement = $name.DropStatement

                print $dropStatement"`r`nGO`r`n"$createSchemaScript

                if (Test-Path $TargetFolderPath$schemaName) {
                    Remove-Item $TargetFolderPath$schemaName -Recurse
                }
                
                if($schemaName -ne 'dbo') {                    
                    Set-Content -Path $TargetFolderPath'Schemas\'$schemaName'.sql' -Value $dropStatement"`r`nGO`r`n"$createSchemaScript
                } else {
                    Set-Content -Path $TargetFolderPath'Schemas\'$schemaName'.sql' -Value "`r`nGO`r`n"
                }
                
                New-Item -Path $TargetFolderPath$schemaName -ItemType Directory
                New-Item -Path $TargetFolderPath$schemaName'\Tables' -ItemType Directory
                New-Item -Path $TargetFolderPath$schemaName'\Views' -ItemType Directory
                New-Item -Path $TargetFolderPath$schemaName'\Functions' -ItemType Directory   
                New-Item -Path $TargetFolderPath$schemaName'\Stored Procedures' -ItemType Directory
                New-Item -Path $TargetFolderPath$schemaName'\External Tables' -ItemType Directory           
                New-Item -Path $TargetFolderPath$schemaName'\Copy INTO' -ItemType Directory           
            }

            # Extracting DDL
            $inputQuery = "EXEC migration.SynapseMigration_ExtractAllDDL"
            Write-Host "Running stored procedure: '$inputQuery'"
            #$ddl_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
            #$ddl_results | Export-csv $TargetFolderPath/"ddl.csv" -NoTypeInformation
            $ddl_results = execute-query -connectionString $connectionString -query $inputQuery -accessToken $token       

            
            
            # Create table scripts
            foreach($row in $ddl_results)
            {
                $tableName = $row.objName
                $schemaName = $row.SchName
                $ddlScript = $row.Script
                $dropStatement = $row.DropStatement
                Set-Content -Path $TargetFolderPath$schemaName'\Tables\'$tableName'.sql' -Value $dropStatement"`r`nGO`r`n"$ddlScript
            }
            
            # Extracting Views
            $inputQuery = "EXEC migration.SynapseMigration_ExtractAllViews"
            Write-Host "Running stored procedure: '$inputQuery'"
            $view_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
            

            # Create view scripts
            foreach($row in $view_results)
            {
                $objName = $row.objName
                $schemaName = $row.SchName
                $viewScript = $row.Script
                $dropStatement = $row.DropStatement
                Set-Content -Path $TargetFolderPath$schemaName'\Views\'$objName'.sql' -Value $dropStatement"`r`nGO`r`n"$viewScript
            }

             # Extracting stored procedures
             $inputQuery = "EXEC migration.SynapseMigration_ExtractAllSP"
             Write-Host "Running stored procedure: '$inputQuery'"
             $sp_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
 
             # Create stored procedure scripts
             foreach($row in $sp_results)
             {
                 $objName = $row.objName
                 $schemaName = $row.SchName
                 $spScript = $row.Script
                 $dropStatement = $row.DropStatement
                 Set-Content -Path $TargetFolderPath$schemaName'\Stored Procedures\'$objName'.sql' -Value $dropStatement"`r`nGO`r`n"$spScript
             }

             # Extracting functions
             $inputQuery = "EXEC migration.SynapseMigration_ExtractAllFunctions"
             Write-Host "Running stored procedure: '$inputQuery'"
             $fn_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
 
             # Create function scripts
             foreach($row in $fn_results)
             {
                 $objName = $row.objName
                 $schemaName = $row.SchName
                 $fnScript = $row.Script
                 $dropStatement = $row.DropStatement
                 Set-Content -Path $TargetFolderPath$schemaName'\Functions\'$objName'.sql' -Value $dropStatement"`r`nGO`r`n"$fnScript
             }

            # Running data extract script
            $inputQuery = "EXEC migration.sp_cetas_extract_script @adls_gen2_location='$adls_gen2_location', @storage_access_token = '$storage_access_token'"
            Write-Host "Running stored procedure: '$inputQuery'"
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
            
            # Generating data extract script
            $inputQuery = "EXEC migration.generate_data_extract_and_data_load_statements @storage_access_token = '$storage_access_token', @external_data_source_base_location = '$adls_gen2_location'"
            Write-Host "Running stored procedure: '$inputQuery'"
            $cetas_copyinto_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery

            foreach($row in $cetas_copyinto_results)
            {
                $tableName = $row.objName
                $schemaName = $row.SchName
                $cetas = $row.data_extract_statement
                $copyinto = $row.data_load_statement
                $dropStatement = $row.DropStatement
                Set-Content -Path $TargetFolderPath$schemaName'\External Tables\'$tableName'.sql' -Value $dropStatement"`r`nGO`r`n"$cetas
                Set-Content -Path $TargetFolderPath$schemaName'\Copy INTO\'$tableName'.sql' -Value $copyinto
            }


            Write-Host "==============================================================================";
        } else {
            Write-Error "SQL Scripts Folder does not exist: $SqlCmdSciptFolderPath";
            exit 1;
        }
    } catch {
        Write-Error $_;
    }
    Stop-Transcript
