
-- =============================================
-- Author:		Mahesh B.	
-- Create date: 03/15/2019 
-- Description:	Get the Kain information 
-- Exec GetKmainInfo '0000000142'
-- =============================================

Create PROCEDURE [dbo].[GetKmainInfo]
(
@woNo AS CHAR(10) = ' '
)
AS
BEGIN

SET NOCOUNT ON;	

SELECT CASE COALESCE(NULLIF(iv.REVISION,''), '')
						WHEN '' THEN  LTRIM(RTRIM(iv.PART_NO)) 
						ELSE LTRIM(RTRIM(iv.PART_NO)) + '/' + iv.REVISION 
						END AS PartNoWithRev,
						CASE 
							WHEN iv.PART_CLASS IS NOT NULL AND iv.PART_TYPE IS NOT NULL  THEN  LTRIM(RTRIM(iv.PART_CLASS)) + '/' + LTRIM(RTRIM(iv.PART_TYPE)) + '/' +iv.DESCRIPT
							WHEN iv.PART_CLASS IS NULL AND iv.PART_TYPE IS NOT NULL  THEN  LTRIM(RTRIM(iv.PART_TYPE)) + iv.DESCRIPT
							WHEN iv.PART_CLASS IS NOT NULL AND iv.PART_TYPE IS NULL  THEN  LTRIM(RTRIM(iv.PART_CLASS)) + iv.DESCRIPT
						ELSE LTRIM(RTRIM(iv.DESCRIPT)) 
					    END AS DESCRIPTION,
			            km.WONO,
			            km.DEPT_ID,
			            km.UNIQ_KEY,
			            km.BOMPARENT,
			            km.SHORTQTY,
			            km.QTY
			 	        FROM KAMAIN km INNER JOIN INVENTOR iv ON km.UNIQ_KEY= iv.UNIQ_KEY  WHERE km.WONO= @woNo and km.SHORTQTY > 0
END