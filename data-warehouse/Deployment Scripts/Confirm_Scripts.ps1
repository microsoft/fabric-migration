function Confirm_Script
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
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