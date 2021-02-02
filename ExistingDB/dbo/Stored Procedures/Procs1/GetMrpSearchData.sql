--================================================================================
-- Author:  Shivshankar P
-- Create date: <06/28/2018>
-- Description: Used to get MRP Filter
-- Satyawan H 06/05/2020 : Added filters the SO & WO 
--================================================================================
CREATE PROCEDURE dbo.[GetMrpSearchData]  
(
	@pageNumber int = 0,
	@pageSize int=10,
	@filterValue nvarchar(100) = ' ',
	@filterType int=1 ,
	@actionType VARCHAR(10)= 'po'
)
AS
BEGIN
	SET NOCOUNT ON;
	     
	--For SO
	IF(@filterType = 1)
	BEGIN
		SELECT DISTINCT REF AS  ID, dbo.fRemoveLeadingZeros(RTRIM(LTRIM(REPLACE(REPLACE(REF,  'DEM SO', ''), 'SO', '')))) AS Value 
		FROM MRPSCH2 WHERE REF LIKE '%SO%'
		-- Satyawan H 06/05/2020 : Added filters the SO & WO 
		AND (TRIM(@filterValue)!='' AND REF LIKE '%'+@filterValue+'%') OR (TRIM(@filterValue)='' AND 1=1) 
		ORDER BY  Value OFFSET  @pageNumber ROWS FETCH NEXT  @pageSize ROWS ONLY
	END

	--For WO
	IF(@filterType = 2)
	BEGIN
		SELECT DISTINCT REF AS ID, 
		dbo.fRemoveLeadingZeros(RTRIM(LTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REF,  'Delv. PWO-', ''),'Dem PWO-', ''),'WO',''),'Delv. ',''))))  AS Value 
		FROM MRPSCH2 WHERE REF LIKE '%WO%'
		-- Satyawan H 06/05/2020 : Added filters the SO & WO 
		AND (TRIM(@filterValue) != '' AND REF LIKE '%'+@filterValue+'%') OR (TRIM(@filterValue)= '' AND 1=1)
		ORDER BY  Value OFFSET  @pageNumber ROWS FETCH NEXT  @pageSize ROWS ONLY
	END

END