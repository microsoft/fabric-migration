IF (SCHEMA_ID('migration') IS NULL) 
BEGIN
    EXEC ('CREATE SCHEMA [migration]')
END