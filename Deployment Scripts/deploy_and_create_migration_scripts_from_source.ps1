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
        
        Remove-Item $TargetFolderPath -Recurse -Force -Confirm:$false
        #User Authentication
        $user = whoami /upn
        $token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token

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


            Write-Host "SQLCMD folder:         $SqlCmdSciptFolderPath";
            if ($Recursive -eq 'true') {
                $SqlCmdFiles = Get-ChildItem -Path $SqlCmdSciptFolderPath -Recurse -Include *.sql;
            } else {
                $SqlCmdFiles = Get-ChildItem -Path "$SqlCmdSciptFolderPath\*" -Include *.sql;
            }

            # Deploying Migration scripts
            foreach ($SqlCmdFile in $SqlCmdFiles) {
                Write-Host "Running SQLCMD file:   $(Split-Path -Leaf $SqlCmdFile)";

                Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $SqlCmdFile
            }

            # Extracting DDL
            $inputQuery = "EXEC dbo.SynapseMigration_ExtractAllDDL"
            Write-Host "Running stored procedure: '$inputQuery'"
            $ddl_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery           

            # Create schema folder
            foreach($name in $ddl_results | Select-Object  SchName -Unique)
            {
                $schemaName =  $name.SchName
                if (Test-Path $TargetFolderPath$schemaName) {
                    Remove-Item $TargetFolderPath$schemaName -Recurse
                }
                New-Item -Path $TargetFolderPath$schemaName -ItemType Directory
                New-Item -Path $TargetFolderPath$schemaName'\Tables' -ItemType Directory
                New-Item -Path $TargetFolderPath$schemaName'\Views' -ItemType Directory
                New-Item -Path $TargetFolderPath$schemaName'\Functions' -ItemType Directory   
                New-Item -Path $TargetFolderPath$schemaName'\Stored Procedures' -ItemType Directory
                New-Item -Path $TargetFolderPath$schemaName'\External Tables' -ItemType Directory           
                New-Item -Path $TargetFolderPath$schemaName'\Copy INTO' -ItemType Directory           
            }
            
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
            $inputQuery = "EXEC dbo.SynapseMigration_ExtractAllViews"
            Write-Host "Running stored procedure: '$inputQuery'"
            $view_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery

            # Create schema folder if it does not exist
            foreach($name in $view_results | Select-Object  SchName -Unique)
            {
                $schemaName =  $name.SchName
                if (!(Test-Path $TargetFolderPath$schemaName)) {
                    New-Item -Path $TargetFolderPath$schemaName -ItemType Directory
                    New-Item -Path $TargetFolderPath$schemaName'\Views' -ItemType Directory
                }
                             
            }

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
             $inputQuery = "EXEC dbo.SynapseMigration_ExtractAllSP"
             Write-Host "Running stored procedure: '$inputQuery'"
             $sp_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
 
             # Create schema folder if it does not exist
             foreach($name in $sp_results | Select-Object  SchName -Unique)
             {
                 $schemaName =  $name.SchName
                 if (!(Test-Path $TargetFolderPath$schemaName)) {
                     New-Item -Path $TargetFolderPath$schemaName -ItemType Directory
                     New-Item -Path $TargetFolderPath$schemaName'\Stored Procedures' -ItemType Directory 
                 }
                              
             }
 
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
             $inputQuery = "EXEC dbo.SynapseMigration_ExtractAllFunctions"
             Write-Host "Running stored procedure: '$inputQuery'"
             $fn_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
 
             # Create schema folder if it does not exist
             foreach($name in $fn_results | Select-Object  SchName -Unique)
             {
                 $schemaName =  $name.SchName
                 if (!(Test-Path $TargetFolderPath$schemaName)) {
                     New-Item -Path $TargetFolderPath$schemaName -ItemType Directory
                     New-Item -Path $TargetFolderPath$schemaName'\Functions' -ItemType Directory
                 }
                              
             }
 
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
            $inputQuery = "EXEC dbo.sp_cetas_extract_script @adls_gen2_location='$adls_gen2_location', @storage_access_token = '$storage_access_token'"
            Write-Host "Running stored procedure: '$inputQuery'"
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
            
            # Generating data extract script
            $inputQuery = "EXEC dbo.generate_data_extract_and_data_load_statements @storage_access_token = '$storage_access_token', @external_data_source_base_location = '$adls_gen2_location'"
            Write-Host "Running stored procedure: '$inputQuery'"
            $cetas_copyinto_results = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $inputQuery
            
            # Create schema folder if it does not exist
            foreach($name in $fn_results | Select-Object  SchName -Unique)
            {
                $schemaName =  $name.SchName
                if (!(Test-Path $TargetFolderPath$schemaName)) {
                    New-Item -Path $TargetFolderPath$schemaName -ItemType Directory
                    New-Item -Path $TargetFolderPath$schemaName'\External Tables' -ItemType Directory
                    New-Item -Path $TargetFolderPath$schemaName'\Copy INTO' -ItemType Directory
                }
                            
            }

            foreach($row in $cetas_copyinto_results)
            {
                $tableName = $row.objName
                $schemaName = $row.SchName
                $cetas = $row.data_extract_statement
                $copyinto = $row.data_load_statement
                $dropStatement = $row.DropStatement
                Set-Content -Path $TargetFolderPath$schemaName'\External Tables\'$tableName'.sql' -Value $dropStatement"`r`nGO`r`n"$cetas
                Set-Content -Path $TargetFolderPath$schemaName'\Copy INTO\'$tableName'.sql' -Value $dropStatement"`r`nGO`r`n"$copyinto
            }


            Write-Host "==============================================================================";
        } else {
            Write-Error "SQL Scripts Folder does not exist: $SqlCmdSciptFolderPath";
            exit 1;
        }
    } catch {
        Write-Error $_;
    }
