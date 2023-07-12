param(

    # If windows, use C:\Data\sqlfiles. if Linux use /home/pvenkat/data/
    [parameter(Mandatory=$false)]
    [string]$SourceFolderPath="C:\Users\pvenkat\test_db_scripts\",

    [parameter(Mandatory=$false)]
    [string]$Server='x6eps4xrq2xudenlfv6naeo3i4-bmmuvve2hnru3anhfqidprgjai.msit-datawarehouse.pbidedicated.windows.net',

    [parameter(Mandatory=$false)]
    [string]$Database='migrationdb',

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

    try {
        
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

           
            
            #Write-Host "Creating Schemas in the target database"
            
            # foreach ($Schema in (Get-ChildItem -Path $SourceFolderPath"Schemas\")) {
            #     Write-Host "Creating Schema: "$SourceFolderPath"Schemas\"$Schema
            #     Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $SourceFolderPath"Schemas\"$Schema
            # }
            
            Write-Host "`nExecuting DDL statements on target database"
            foreach($schema in (Get-ChildItem -Path $SourceFolderPath -Exclude "Schemas" -Directory)) {
                
                foreach($Table in (Get-ChildItem -Path $Schema"\Tables\")) {
                    Write-Host "Creating Table: "$Table " in " $(Split-Path -Leaf $Schema)
                    $path = "$($SourceFolderPath)$($Schema.Name)\Tables\$($Table)"
                    Write-Host $path
                    Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $path
                }

                # foreach($View in (Get-ChildItem -Path $Schema"\Views\")) {
                #     Write-Host "Creating View: "$View " in " $(Split-Path -Leaf $Schema)
                #     # Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $View
                # }

                # foreach($Sp in (Get-ChildItem -Path $Schema"\Stored Procedures\")) {
                #     Write-Host "Creating Stored Procedure: "$Sp " in " $(Split-Path -Leaf $Schema)
                #     # Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $Sp
                # }

                # foreach($Fnc in (Get-ChildItem -Path $Schema"\Functions\")) {
                #     Write-Host "Creating Function: "$Fnc " in " $(Split-Path -Leaf $Schema)
                #     # Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $Fnc
                # }
            }

            # Write-Host "`nCopying data to target database"
            # foreach($Schema in (Get-ChildItem -Path $SourceFolderPath -Exclude "Schemas" -Directory)) {
                
            #     foreach($Table in (Get-ChildItem -Path $Schema"\Copy INTO\")) {
            #         Write-Host "COPY INTO: "$Table " in " $(Split-Path -Leaf $Schema)
            #         # Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -InputFile $Table
            #     }
            # }

            Write-Host "==============================================================================";
        } else {
            Write-Error "SQL Scripts Folder does not exist: $SourceFolderPath";
            exit 1;
        }
    } catch {
        Write-Error $_;
    }
    Stop-Transcript
