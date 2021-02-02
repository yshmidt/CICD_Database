-- =============================================
-- Author:		Rajendra K	
-- Create date: <29/07/2019>
-- Description:Get AntiAvls Manufacturers Data
-- EXEC [GetWoNoAntiAvlData] '0000000320'
-- =============================================
CREATE PROCEDURE [dbo].[GetWoNoAntiAvlData]  
(
	@WoNo CHAR(10) = ''
)
AS
BEGIN
	SET NOCOUNT ON;	
	 IF OBJECT_ID(N'tempdb..#temp') IS NOT NULL
     DROP TABLE #temp ; 

	SELECT BOMPARENT
		  ,UNIQ_KEY 
	INTO #temp 
	FROM KAMAIN 
	WHERE WONO = @WoNo;

	SELECT DISTINCT t.Uniq_key
				    ,t.Bomparent
				    ,Partmfgr
				    ,Mfgr_pt_no 
    FROM Antiavl Al JOIN #temp t ON al.BOMPARENT = t.BOMPARENT AND al.UNIQ_KEY = t.UNIQ_KEY
END