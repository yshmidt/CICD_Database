-- =============================================
-- Author:  Shivshankar P
-- Create date: 26/09/2017
-- Description:Material Check
-- EXEC MXWebMaterialCheck '10200'
-- Modified: 07/18/17 Shivshankar P: Modified to Merging the columns [PART_NO],[REVISION] and PART_CLASS,PART_TYPE
-- Modified: 02/19/20 Shivshankar P: Apply sorting on PO action by WO
-- =============================================
CREATE PROCEDURE [dbo].[MXWebMaterialCheck] 
       -- Add the parameters for the stored procedure here
	   @woNo CHAR (15) = ' ',
       @userID uniqueidentifier = NULL,
	   @StartRecord int = 1,
       @EndRecord int = 100,
	   @sortExpression VARCHAR(MAX) = ''  
AS
BEGIN
       -- SET NOCOUNT ON added to prevent extra result sets from
       -- interfering with SELECT statements.
       SET NOCOUNT ON;

	  DECLARE @sqlQuery NVARCHAR(MAX),@rowCount NVARCHAR(MAX) 

	--select @woNo
	IF OBJECT_ID('tempdb..#tMatCheck') is not null
		DROP table #tMatCheck;  

	SELECT [WONO]
			,CASE
				WHEN DUE_DATE IS NULL THEN 'CLEARED'							-- If the material Due Date is NULL (this indicates the parts are in stock now), it is marked as 'cleared'
				WHEN MAT_DATE >= DUE_DATE AND MAT_DATE > GETDATE() THEN 'OK'	-- If the Mat_date is after the due date, and mat_date is greater than today, it is marked as 'OK'
				ELSE [ACTION]													-- Otherwise, show the MRP actions message
				END [STATUS]
			,ASSY_NO
			,ASSY_REV
			,ASSY_DESC
			,WO_DUE
			,ASSY_BAL
			,MAT_DATE
			--,ASSY_NO + '/' + ASSY_REV AS AssyRev
			,[PART_NO]
			,[REVISION]
			,[PART_NO] + '/' +[REVISION] AS PartNoRev   --- Modified: 07/18/17 Shivshankar P Modified to Merging the columns [PART_NO],[REVISION] and PART_CLASS,PART_TYPE
            ,[DESCRIPT]
			,[PartTypeDes]  
			,[DUE_DATE]
			,[STARTDATE]
			,[BALANCE]
			,[REQQTY]
			,[REF]
			,[ACTION]
			,[REQDATE]
			,[MFGRS]
			,[PREFAVL]
			,[QTY_PER_ASSY]
		    ,[UNIQ_KEY]
		 	,[PART_SOURC]
		INTO #tMatCheck
		FROM (  

		SELECT wo.[WONO]
			,bi.[PART_NO] ASSY_NO
			,bi.[REVISION] ASSY_REV
			--,bi.[PART_NO] + '/' + bi.[REVISION] AS AssyRev
			,bi.[DESCRIPT] ASSY_DESC
			,bi.PART_CLASS + '/' + bi.PART_TYPE + '/'+ bi.Descript AS [PartTypeDes]  --- Modified: 07/18/17 Shivshankar P Modified to Merging the columns [PART_NO],[REVISION] and PART_CLASS,PART_TYPE
			,wo.[DUE_DATE] WO_DUE
			,wo.[BALANCE] ASSY_BAL
			,bi.[PROD_LTIME]
			,bi.[PROD_LUNIT]
			,bi.[KIT_LTIME]
			,bi.[KIT_LUNIT]
			--,bi.UNIQ_KEY
			,bi.PART_SOURC
			-- Convert all lead times to days, then subtract the days from the WO due date to calculate the Mat_date
			,DATEADD(
				DAY
				,-ROUND(CASE bi.[PROD_LUNIT]
						WHEN '' THEN 0
						WHEN 'DY' THEN bi.[PROD_LTIME]
						WHEN 'WK' THEN bi.[PROD_LTIME]*7
						END,0)
					-ROUND(CASE bi.[KIT_LUNIT]
						WHEN '' THEN 0
						WHEN 'DY' THEN bi.[KIT_LTIME]
						WHEN 'WK' THEN bi.[KIT_LTIME]*7
						END,0)
				,wo.[DUE_DATE]) AS MAT_DATE
			,p.[PART_NO]
			,p.[UNIQ_KEY]
			,p.[REVISION]
			,p.[DESCRIPT]
			,p.[DUE_DATE]
			,[STARTDATE]
			,p.[BALANCE]
			,[REQQTY]
			,[REF]
			,p.[ACTION]
			,[REQDATE]
			,[MFGRS]
			,[PREFAVL]
			,p.[QTY_PER_ASSY]
		FROM (
			-- Get a list of open WO
            SELECT [WONO]
				  ,[UNIQ_KEY]
				  ,[DUE_DATE]
				  ,[BALANCE]
				  ,[ACTION]
				FROM [dbo].[MRPACT]
				WHERE ((@woNo <> ' ' AND WONO=@woNo) OR (@woNo IS NULL OR @woNo =' ' AND WONO <> ' '))
            )wo
            INNER JOIN [dbo].INVENTOR bi ON wo.UNIQ_KEY = bi.UNIQ_KEY
            LEFT OUTER JOIN (

				-- Get a list of MRP actions that may be included in the desired results, and the related Item Master part number info
				SELECT i.[UNIQ_KEY]
                        ,i.[PART_NO]
                        ,i.[REVISION]
                        ,i.[DESCRIPT],
						 i.PART_CLASS + '/' + i.PART_TYPE + '/'+ i.Descript AS [PartTypeDes]  --- Modified: 07/18/17 Shivshankar P Modified to Merging the columns [PART_NO],[REVISION] and PART_CLASS,PART_TYPE
                        ,[DUE_DATE]
                        ,[STARTDATE]
                        ,[BALANCE]
                        ,[REQQTY]
                        ,[REF]
                        ,[ACTION]
                        ,[REQDATE]
                        ,[MFGRS]
                        ,[WONO]
                        ,[PREFAVL]
                        ,bd.[BOMPARENT]
                        ,bd.[QTY] QTY_PER_ASSY
						,i.PART_SOURC
                    FROM [dbo].[MRPACT] ma
                     INNER JOIN [dbo].[INVENTOR] i ON ma.UNIQ_KEY = i.UNIQ_KEY
                        LEFT OUTER JOIN (
							-- Include items only if they are on an assembly and used in the kit
							SELECT [UNIQ_KEY],[BOMPARENT],[QTY]
								FROM [dbo].[BOM_DET]
                                WHERE [USED_INKIT] != 'N'   
								)bd ON ma.UNIQ_KEY = bd.UNIQ_KEY
                    WHERE [ACTION] NOT IN ('No PO Action','Order Kitted','ReworkFirm')
						AND [WONO] = ''

                    )p ON p.[BOMPARENT] = wo.UNIQ_KEY) wolist
					WHERE REQDATE<MAT_DATE 
					

					IF(@woNo = '')
					BEGIN 
						SELECT 
								dbo.fRemoveLeadingZeros(WONO) AS WONO,ASSY_NO
								,ASSY_NO + '/' + ASSY_REV AS AssyRev
								,ASSY_REV
								,ASSY_DESC
								,[PartTypeDes]  
								,WO_DUE
								,MAT_DATE
								,ASSY_BAL
								,CASE WHEN
								PATINDEX('%PO%',
								STUFF((SELECT DISTINCT '/'+ t2.status FROM #tMatCheck t2 WHERE t2.wono=#tMatCheck.wono FOR XML PATH('')),1,1,'') )<>0 
								THEN 'PO Action'
								ELSE 'OK/Clear' END	AS Statuses
						INTO #temp
						FROM #tMatCheck 
						GROUP BY WONO,ASSY_NO,ASSY_REV,ASSY_DESC,WO_DUE,ASSY_BAL,MAT_DATE,[PartTypeDes]
						ORDER BY wono

						SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #temp','',@sortExpression,'','AssyRev',@startRecord,@endRecord))         
						EXEC sp_executesql @rowCount      
  
						SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #temp','',@sortExpression,N'AssyRev','',@startRecord,@endRecord))    
						EXEC sp_executesql @sqlQuery 
					END
  
				 IF(@woNo <> '')
				 BEGIN   
					 select * ,totalCount = COUNT(wono) OVER()  
					 INTO #tempt
					 from #tMatCheck  
					 order by wono  
					 SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempt','',@sortExpression,'','PartNoRev',@startRecord,@endRecord))         
						   EXEC sp_executesql @rowCount      
  
					 SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #tempt','',@sortExpression,N'PartNoRev','',@startRecord,@endRecord))    
						EXEC sp_executesql @sqlQuery
			     END 

END