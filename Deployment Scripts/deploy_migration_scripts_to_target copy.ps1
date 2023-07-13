
$Server='x6eps4xrq2xudenlfv6naeo3i4-bmmuvve2hnru3anhfqidprgjai.msit-datawarehouse.pbidedicated.windows.net'
$Database='testsqlpool'

#Connect-AzAccount
$token = (Get-AzAccessToken -ResourceUrl https://database.windows.net/).Token


$query = 
@"

BEGIN TRY
    SET PARSEONLY ON;    
    EXEC(' <<REPLACE>>')
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

Invoke-Sqlcmd -ServerInstance $Server -Database $Database -AccessToken $token -Query $query

function validate-query
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $queryText
    )
    
    $queryText = $queryText.Replace("'","''")
    Write-Host $queryText

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

$value = validate-query $queryText

$queryText = "CREATE PROC [dbo].[create_master_key_and_scoped_credential] AS

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
        BEGIN
            print('##MS_DatabaseMasterKey## does not exist. creating one.....');
           
        END
        ELSE
        BEGIN
            print('##MS_DatabaseMasterKey## master encryption key exists already.');
        END
    
        -- Create Database Scoped Credential
        IF EXISTS (SELECT 1 FROM sys.database_scoped_credentials WHERE name = 'fabric_migration_credential')
        BEGIN
            print('fabric_migration_credential data scoped credential exists already.');
        END
        ELSE 
        BEGIN
            CREATE DATABASE SCOPED CREDENTIAL fabric_migration_credential WITH IDENTITY ='Managed Service Identity'
            print('created database scoped credential - fabric_migration_credential.');
        END
    END TRY
    
    BEGIN CATCH
        SELECT
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_STATE() AS ErrorState,
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_MESSAGE() AS ErrorMessage;
    
        THROW;
    END CATCH;"
        