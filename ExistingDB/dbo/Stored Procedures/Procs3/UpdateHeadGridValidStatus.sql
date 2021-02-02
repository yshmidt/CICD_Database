-- =================================================================================================================================
-- AUTHOR	   : Satyawan H.
-- Date		   : 07/16/2019	 
-- Description : Update header grid status and IsValidate on import and delete operation on detail grid
-- =================================================================================================================================
-- EXEC UpdateHeadGridValidStatus @ImportID='6BA70E10-2976-45A6-9CF8-B1DACA25046A',@UserId='49F80792-E15E-4B62-B720-21B360E3108A'

CREATE PROC UpdateHeadGridValidStatus
	@ImportID UNIQUEIDENTIFIER,
	@UserId UNIQUEIDENTIFIER = null
AS
BEGIN
	DECLARE @TotalItems int
	DECLARE @AllRows TABLE(Id int,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(50),invalidUDFs bit,IsImported bit)
	INSERT INTO @AllRows EXEC sp_getImportedInventorUDFs @ImportID=@ImportID,@GetImportRows = 1
	
    UPDATE h
	   SET h.[Status]=CASE WHEN (a.Invalid > 0) THEN 'Error' ELSE 'No Error' END,
		   h.[Validated]=CASE WHEN (a.Invalid > 0) THEN 0 ELSE 1 END,
		   h.[CompleteBy]=CASE WHEN (a.Invalid <= 0 AND c.InComplete=0) OR ISNULL(ar.RowId,null) = null THEN @UserId ELSE NULL END,
		   h.[CompleteDt]=CASE WHEN (a.Invalid <= 0 AND c.InComplete=0) OR ISNULL(ar.RowId,null) = null THEN GETDATE() ELSE NULL END
	FROM ImportInventorUdfHeader h 
		OUTER APPLY (SELECT RowId FROM @AllRows) ar
		OUTER APPLY (SELECT count(1) Invalid FROM @AllRows WHERE CssClass = 'i05red' OR invalidUDFs > 0) a
		OUTER APPLY (SELECT count(1) InComplete FROM @AllRows WHERE CssClass = 'i05red' OR invalidUDFs > 0 OR IsImported=0) c
	WHERE h.ImportId = @ImportID
END