IF object_id('dbo.create_master_key_and_scoped_credential') IS NOT NULL
    DROP PROCEDURE dbo.create_master_key_and_scoped_credential
GO

CREATE PROCEDURE dbo.create_master_key_and_scoped_credential
/*

    Name: dbo.create_master_key_and_scoped_credential
    Description: This stored procedure creates master encryption key & database scoped credential
    
    Sample Execution: 
        EXEC dbo.create_master_key_and_scoped_credential

*/
AS

BEGIN TRY
    -- Create Master Key
    IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    BEGIN
        print('##MS_DatabaseMasterKey## does not exist. creating one.....');
        CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Microsoft@1234' ;
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
END CATCH;
