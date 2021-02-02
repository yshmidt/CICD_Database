-- =============================================
-- Author:		Rajendra K	
-- Create date: <11/05/2018>
-- Description:Get simulation WONO Data
-- EXEC [GetPartNumberRevByWONO] '0000000111',1,1,1000,'',10000
-- =============================================
CREATE PROCEDURE [dbo].[GetPartNumberRevByWONO]
(
@wono CHAR(10)
)
AS
BEGIN
SET NOCOUNT ON
		SELECT W.UNIQ_KEY
		      ,I.PART_NO
		      ,PART_CLASS 
		      ,PART_TYPE
		      ,DESCRIPT
		      ,W.BLDQTY AS Quantity
		      ,W.DUE_DATE AS DueDate
		FROM WOENTRY W 
		INNER JOIN INVENTOR I ON W.UNIQ_KEY = I.UNIQ_KEY
		WHERE (@wono IS NULL OR @wono ='' OR W.WONO = @wono)
		AND W.WONO NOT IN (SELECT WONO FROM KAMAIN)
END