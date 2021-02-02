-- Get latest stdcost for the cycle count
CREATE PROCEDURE [dbo].[InvtAbcView]
AS
BEGIN

SET NOCOUNT ON;

SELECT *
	FROM InvtAbc
	ORDER BY ABC_TYPE
END	





