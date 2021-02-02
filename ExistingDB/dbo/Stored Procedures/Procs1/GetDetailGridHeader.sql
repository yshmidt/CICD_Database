-- ==============================================================================
-- Author	   : Satyawan H 
-- Date		   : 07/17/2019 	 
-- Description : Get Header Detail Grid
-- ==============================================================================
-- EXEC GetDetailGridHeader @ImportId = '92D9528E-EEA2-4C65-A920-DE4092673E10'

CREATE PROC GetDetailGridHeader
	@ImportId UNIQUEIDENTIFIER
AS
BEGIN
	SELECT h.*,u.Username, cu.CompleteByName FROM ImportInventorUdfHeader h
		JOIN aspnet_Users u ON h.UserId = u.UserId 
		OUTER APPLY (
			SELECT UserName CompleteByName FROM aspnet_Users WHERE UserId = h.CompleteBy
		) cu
	WHERE ImportId = @ImportId
END