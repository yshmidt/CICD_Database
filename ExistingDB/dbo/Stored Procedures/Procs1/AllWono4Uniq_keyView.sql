
-- =============================================
-- Author:		Vicky Lu	
-- Create date: <08/24/12>
-- Description:	<Get all wonos that belong to selected uniq_key
-- =============================================
CREATE PROCEDURE [dbo].[AllWono4Uniq_keyView] 
	-- Add the parameters for the stored procedure here
	@ltPartList AS tUniq_key READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
-- 08/24/12 VL changed to pass table variable as paramter, not pass a custo each time
--ALTER PROC [dbo].[AllWono4Uniq_keyView] @lcUniq_key AS char(10) = ' '
--AS
-- SELECT Wono, Custno
--	FROM Woentry
--	WHERE Uniq_key = @lcUniq_key
-- 	ORDER BY 1

SELECT Wono, Custno
	FROM Woentry
	WHERE Uniq_key IN (SELECT Uniq_key FROM @ltPartList)
 	ORDER BY 1

END





