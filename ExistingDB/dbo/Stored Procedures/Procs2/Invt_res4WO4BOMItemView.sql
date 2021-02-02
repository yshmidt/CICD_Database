CREATE PROC [dbo].[Invt_res4WO4BOMItemView] @lcBomparent AS char(10) = '', @lcUniq_key AS char(10) = ''
AS
SELECT Wono,Uniq_key,Invtres_no
 	FROM Invt_res
 	WHERE Wono IN 
 		(SELECT WONO 
 			FROM WOENTRY
 			WHERE UNIQ_KEY = @lcBomparent
 			AND LEFT(OPENCLOS,1) <> 'C')
 	AND Refinvtres =''
 	AND Uniq_key = @lcUniq_key
 	AND Invtres_no NOT IN 
 		(SELECT Refinvtres 
 			FROM Invt_res 
 			WHERE Refinvtres<>'')
 		





