-- =============================================    
-- Author:  Yelena Shmidt    
-- Create date: <10/14/10>    
-- Description: <This procedure will gather all the records that are ready for the instore po>    
-- id @pcUniq_key parameter is sent it will use it to find records for the particular uniq_key otherwise it will    
-- return all the records which have astablished contract information    
-- this procedure will return multiple data set SqlResult1 - POSTORE information and SqlResult2 contract price information       
-- 04/14/15 YS change "location" column length to 256    
-- 01/28/15 VL Added to save taxable default from inventor.taxable, CostEachFC, ExtamtFC, Fcused_uniq, and Fchist_key    
-- 02/02/17 YS contract tables are changed    
-- 03/28/17 YS changed length of the part_no column from 25 to 35    
-- 03/31/17 VL Added functional currency code    
-- 02/09/18 YS changed size of the lotcode column to 25 char    
-- 07/11/18 YS supname increased from 30 to 50   
-- 09/06/2019 Nitesh B : Add Parameter @uniqSupno to result against supplier search
-- 09/27/2019 Nitesh B : Added filter, sortExpression operation 
-- 10/21/2020 Shivshankar P : Added outer apply to get the nearest Price of Qty_isu from CONTPRIC table as CostEach in In-plant Po
-- 11/22/2020 Shivshankar P : Added condition to get the nearest Price of Qty_isu
-- =============================================    
CREATE PROCEDURE GetInStoreReadyData    
 -- Add the parameters for the stored procedure here    
 @pcUniq_key char(10)=' ', 
 @uniqSupno NVARCHAR(MAX)  =' ',   -- 09/06/2019 Nitesh B : Add Parameter @uniqSupno to result against supplier search
 @startRecord INT = 1,  
 @endRecord INT = 150,
 @sortExpression NVARCHAR(1000) = NULL, -- 09/27/2019 Nitesh B : Added filter, sortExpression operation
 @filter NVARCHAR(1000) = NULL
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON; 
 DECLARE @SQL nvarchar(MAX),@rowCount NVARCHAR(MAX);   -- 09/27/2019 Nitesh B : Added filter, sortExpression operation

 	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'supname asc'
	END

 --- 04/14/15 YS change "location" column length to 256    
 --- 07/11/18 YS supname increased from 30 to 50    
    DECLARE @Zpostoreview Table (SupName char(50),Qty_isu numeric(12,2),    
 partmfgr char(8),mfgr_pt_no char(30),UniqWh char(10),    
 CostEach numeric(13,5), ExtAmt numeric(11,2),    
 --- 03/28/17 YS changed length of the part_no column from 25 to 35    
 date_isu smalldatetime,part_no char(35),    
 revision char(8),part_class char(8),part_type char(8),    
 descript char(45), u_of_meas char(4),pur_uofm char(4),    
 package char(15),buyer_type char(3),stdcost numeric(13,5),    
 uniq_key char(10),UniqSupno char(10),ponum char(15),    
 UniqMfgrHd char(10),r_link char(10),c_link char(10),    
 uniqrecord char(10) ,Terms char(15),    
 --02/09/18 YS changed size of the lotcode column to 25 char    
 LotCode nvarchar(25),ExpDate smalldatetime,Reference char(12),    
 UsedBy char(20),whno char(10),location varchar(256),    
 contr_uniq char(10),contr_no char(20),quote_no char(20),Mfgr_uniq char(10),Serialno char(30), SerialUniq char(10),UniqLnno char(10),RecVer binary(8),    
 --01/28/15 VL Added to save taxable default from inventor.taxable, CostEachFC, ExtamtFC, Fcused_uniq, and Fchist_key    
 Taxable bit, CostEachFC numeric(13,5), ExtAmtFC numeric(11,2), Fcused_uniq char(10), Fchist_key char(10),    
 -- 03/31/17 VL added functional currency code    
 CostEachPR numeric(13,5), ExtAmtPR numeric(11,2),stdcostPR numeric(13,5),wh_gl_nbr varchar(13)    
 )    
   
   -- 10/21/2020 Shivshankar P : Added outer apply to get the nearest Price of Qty_isu from CONTPRIC table as CostEach in In-plant Po  
INSERT INTO @Zpostoreview      
 SELECT DISTINCT Supinfo.supname, Postore.qty_isu,Postore.partmfgr,Postore.mfgr_pt_no,Postore.UniqWh,    
 CAST(ISNULL(contprice.PRICE, Inventor.stdcost) as numeric(13,5)),CAST((ISNULL(contprice.PRICE, Inventor.stdcost) * Postore.qty_isu) AS numeric(11,2)),Postore.date_isu,    
 Inventor.part_no,Inventor.revision,Inventor.part_class,Inventor.part_type,    
 Inventor.descript, Inventor.u_of_meas, Inventor.pur_uofm,    
 Inventor.package, Inventor.buyer_type, Inventor.stdcost,    
 Postore.uniq_key, Postore.UniqSupno,Postore.ponum,    
 Postore.UniqMfgrHd,    
 Supinfo.r_link, Supinfo.c_link,    
 Postore.uniqrecord,Supinfo.Terms,    
 PoStore.LotCode,PoStore.ExpDate,PoStore.Reference,    
 Postore.UsedBy,Warehous.whno, Postore.location,    
 C.contr_uniq,H.contr_no, H.quote_no,Contmfgr.Mfgr_uniq,    
 POSTORE.serialno ,POSTORE.serialuniq,PoStore.UNIQLNNO,POSTORE.RecVer ,    
 --01/28/15 VL Added to save taxable default from inventor.taxable, CostEachFC, ExtamtFC, Fcused_uniq, and Fchist_key    
 Inventor.Taxable, CAST(0.0 as numeric(13,5)),CAST(0.0 AS numeric(11,2)),H.Fcused_uniq, H.Fchist_key,    
 -- 03/31/17 VL added functional currency code    
 CAST(0.0 as numeric(13,5)),CAST(0.0 AS numeric(11,2)), Inventor.stdcostPR     
 ,Warehous.wh_gl_nbr    
 --- 02/02/17 YS rewrite FROM... contract tables are changed    
 FROM POSTORE INNER JOIN [Contract] C ON postore.UNIQ_KEY=C.UNIQ_KEY    
 inner join supinfo  on postore.uniqsupno= supinfo.uniqsupno    
 inner join ContractHeader H on h.contractH_unique=c.contractH_unique    
 and h.uniqSupno=Supinfo.uniqsupno    
 inner join Contmfgr on Contmfgr.Contr_uniq=C.Contr_uniq    
 AND Contmfgr.Partmfgr=Postore.PartMfgr    
 AND Contmfgr.Mfgr_pt_no=Postore.Mfgr_pt_no    
 INNER JOIN Inventor ON Inventor.Uniq_key=Postore.Uniq_key    
 inner join warehous on  Warehous.UniqWh=Postore.UniqWh
 -- 10/21/2020 Shivshankar P : Added outer apply to get the nearest Price of Qty_isu from CONTPRIC table as CostEach in In-plant Po
 -- 11/22/2020 Shivshankar P : Added condition to get the nearest Price of Qty_isu
 OUTER APPLY (Select top 1 PRICE FROM CONTPRIC WHERE Contmfgr.MFGR_UNIQ = CONTPRIC.MFGR_UNIQ AND Postore.qty_isu <= QUANTITY ORDER BY ABS(QUANTITY - Postore.qty_isu)) contprice    
 WHERE     
 Postore.ponum = SPACE(15)     
 AND Postore.uniq_key = CASE WHEN @pcUniq_key<>' 'THEN @pcUniq_key ELSE  Postore.uniq_key END 
 AND ((ISNULL(@uniqSupno,'') <> '' AND POSTORE.UNIQSUPNO IN (SELECT id FROM dbo.[fn_simpleVarcharlistToTable](@uniqSupno,',')))
 OR   (ISNULL(@uniqSupno,'') = '' AND 1=1)) -- 09/06/2019 Nitesh B : Add Parameter @uniqSupno to result against supplier search

-- this will create the first sql SqlResult    
--select * from @Zpostoreview   
-- 09/27/2019 Nitesh B : Added filter, sortExpression operation
SELECT IDENTITY(INT,1,1) AS RowNumber, CAST(0 AS BIT ) AS IsChecked, (RTRIM(part_class) +' /'+ RTRIM(part_type) + ' /' + RTRIM(descript)) AS class_type_Desc,
						 (RTRIM(part_no) + '/' + RTRIM(revision)) AS PARTNOREV, * INTO #TEMP FROM @Zpostoreview

SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #TEMP',@filter,@sortExpression,'','supname',@startRecord,@endRecord))         
      EXEC sp_executesql @rowCount      

SET @SQL =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #TEMP',@filter,@sortExpression,N'supname','',@startRecord,@endRecord))    
   EXEC sp_executesql @SQL
    
-- this will be the second sql SqlResult1    
 select * from CONTPRIC     
 where MFGR_UNIQ IN (SELECT MFGR_UNIQ FROM @Zpostoreview) order by MFGR_UNIQ     
    
END