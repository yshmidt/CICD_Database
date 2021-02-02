CREATE PROC [dbo].[Kadetail4WonoView] @gWono AS char(10) ='' 
AS
SELECT *
	FROM Kadetail
	WHERE Wono = @gWono
	ORDER BY AuditDate


