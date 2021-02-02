-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/09/2013
-- Description:	A function to return a tables with records for passed in string. Eg. '1-5,200,209' will have 7 records with 1,2,3,4,5,200,209
-- =============================================
CREATE FUNCTION [dbo].[fn_ParseSerialNumberString] (@inputString varchar(MAX))
RETURNS TABLE 
AS
RETURN
(
		
	WITH tbl AS(
		SELECT * 
			FROM dbo.fn_orderedVarcharlistToTable(@inputString,',')
	)
	
	-- 05/09/13 VL added NOT LIKE '%[a-zA-Z]%', so if a record has alpha character with '-' won't be inserted
	, tblRange AS(
		SELECT colOrder, ID, CAST(SUBSTRING(id,1,CHARINDEX('-',Id,1)-1) AS INT) AS StartNumber, CAST(SUBSTRING(Id,CHARINDEX('-',Id,1)+1, LEN(id)-CHARINDEX('-',id,1)) AS INT) AS EndNumber 
			FROM tbl 
			WHERE Id LIKE '%-%' 
			AND Id NOT LIKE '%[a-zA-Z]%'
	)
	
	, Range AS(
		SELECT colorder, StartNumber AS Serialno
			FROM tblRange t
		UNION ALL
		SELECT R.colorder, R.Serialno+1
			FROM [Range] R INNER JOIN tblRange t1 ON r.colOrder = t1.colOrder
			WHERE r.Serialno < t1.EndNumber
	)
	
	SELECT colorder, CAST(Serialno AS varchar(40)) AS Id, dbo.PADL(LTRIM(RTRIM(CAST(Serialno AS varchar(40)))),30,'0') AS SN
		FROM [Range]
	UNION ALL
	SELECT colOrder, Id, dbo.PADL(LTRIM(RTRIM(CAST(ID AS varchar(40)))),30,'0') AS SN 
		FROM tbl 
		WHERE Id NOT LIKE '%-%'
		--ORDER BY colOrder
	
)
