-- =============================================
-- Author: Shivshankar Patil	
-- Create date: <03/15/16>
-- Description:	<Get PO Inspection History(Inspection Completed records)> 
-- 06/12/2017 Shivshankar P :  Get Filter PART_NO,mfgr_pt_no,ponum,recPklNo and @startDate and @endDate
-- 16/09/2017 Shivshankar P :  Get Filter PART_NO,mfgr_pt_no,ponum,recPklNo with @startDate and @endDate OR @startDate and @endDate 
-- 27/09/2017 Shivshankar P :  Modified for improving the performance, and handled all the filters conditional,separate query for total Count and Removed unused variable
-- 10/23/2017 Shivshankar P :  Get the records including previous 1  from initial 
-- 10/26/2017 Shivshankar P :  Used dynamic sql for filtering and changed condtions
-- 05/20/2019 Nitesh B :  Change join table aspnet_Profile to aspnet_Users to get UserName
-- 02/17/2020 Rajendra K : Addded UNIQ_KEY and Partmfgr in selection list  
-- EXEC [GetInspectionHistory]   
-- =============================================
CREATE PROCEDURE [dbo].[GetInspectionHistory] 
	-- Add the parameters for the stored procedure here
    @supplierPlNo NVARCHAR(200)  = ' ',
  	@startRecord INT=1,
    @endRecord INT=10, 
    @sortExpression NVARCHAR(1000) = null,
    @filter NVARCHAR(1000) = null,
  	@startDate AS SMALLDATETIME= null,
	  @endDate AS SMALLDATETIME =  null,
    @partNumber NVARCHAR(200)  =' ',
	  @mfgrPartNo NVARCHAR(200) = ' ' ,
  	@supPartNo NVARCHAR(200) = ' ' 
AS
 BEGIN
     SET NOCOUNT ON;
   	 DECLARE @SQLQuery NVARCHAR(2000);
     DECLARE @qryMain  NVARCHAR(2000); 
	            -- 27/09/2017 Shivshankar P :  Modified for improving the performance, and handled all the filters conditional,separate query for total Count  and Removed unused variable
                SELECT COUNT(rh.receiverHdrId)
				FROM receiverHeader rh  inner join receiverDetail rd ON rh.receiverHdrId = rd.receiverHdrId   AND  rd.isinspReq = 1 and rd.isinspCompleted = 1 
					LEFT JOIN inspectionHeader id ON  rd.receiverDetId  = id.receiverDetId AND id.RejectedAt = 'Inspection'
					Left JOIN aspnet_Profile asp ON rh.recvBy = asp.UserId 
					Left JOIN POMAIN pn ON rh.ponum = pn.PONUM
					LEFT JOIN aspnet_Users aspuser ON  pn.aspnetBuyer = aspuser.UserId
					INNER JOIN INVENTOR ir ON rd.Uniq_key = ir.UNIQ_KEY 
	            WHERE ((@partNumber <> ' ' AND ir.PART_NO like '%' + @partNumber +'%' OR @partNumber = ' ' AND ir.PART_NO=ir.PART_NO)  
				        AND (@mfgrPartNo <> ' ' AND rd.mfgr_pt_no  LIKE  '%' + @mfgrPartNo +'%' OR  @mfgrPartNo = ' ' AND rd.mfgr_pt_no=rd.mfgr_pt_no) 
					    AND  (@supPartNo <> ' ' AND  rh.ponum  like  '%' + @supPartNo  +'%' OR   @supPartNo  = ' ' AND rh.ponum=rh.ponum)
						AND (@supplierPlNo <> ' ' AND  rh.recPklNo  like  '%' + @supplierPlNo  +'%' OR   @supplierPlNo  = '' AND rh.recPklNo=rh.recPklNo))
						AND ((@startDate IS NOT NULL AND @endDate IS NOT NULL AND  rh.dockDate  >=  @startDate  AND   rh.dockDate <= @endDate)  OR (@startDate IS NULL AND  @endDate IS  NULL AND  rh.dockDate=rh.dockDate))

  -- 02/17/2020 Rajendra K : Addded UNIQ_KEY and Partmfgr in selection list  
    SET @SQLQuery = 'SELECT  rh.receiverHdrId, rh.dockDate,ir.PART_NO ,ir.REVISION,ir.UNIQ_KEY,rd.Partmfgr, rd.mfgr_pt_no, ir.PART_CLASS  + '' / '' +  ir.PART_TYPE + '' / '' + ir.DESCRIPT AS DESCRIPT,    
								rd.Qty_rec,id.FailedQty, rh.ponum,aspuser.UserName AS Initials ,rh.recPklNo ,aspuser.UserName AS BUYER, id.inspectedQty -id.FailedQty AS AcceptedQty,id.RejectedAt
								from receiverHeader rh  inner join receiverDetail rd ON rh.receiverHdrId = rd.receiverHdrId   AND  rd.isinspReq = 1 and rd.isinspCompleted = 1 
								LEFT JOIN inspectionHeader id ON  rd.receiverDetId  = id.receiverDetId AND id.RejectedAt = ''Inspection''
								Left JOIN aspnet_Profile asp ON rh.recvBy = asp.UserId 
								Left Join POMAIN pn ON rh.ponum = pn.PONUM
								LEFT JOIN aspnet_Users aspuser ON  (pn.aspnetBuyer = aspuser.UserId OR rh.recvBy = aspuser.UserId)
								INNER JOIN INVENTOR ir ON rd.Uniq_key = ir.UNIQ_KEY  '
              
			
		  IF ((@partNumber = '' OR @partNumber IS NULL) AND (@mfgrPartNo ='' OR @mfgrPartNo IS NULL) AND  (@supPartNo = '' OR @supPartNo IS NULL)  
		     AND (@supplierPlNo = '' OR @supplierPlNo IS  NULL))
			BEGIN
			    SET @SQLQuery = 'SELECT * FROM('+@SQLQuery+')a'
			END
			--Get Filter by Part Number
			ELSE IF ((@partNumber <> '' OR @partNumber IS NOT NULL)  AND (@mfgrPartNo ='' OR @mfgrPartNo IS NULL) AND  (@supPartNo = '' OR @supPartNo IS NULL)  
		             AND (@supplierPlNo = '' OR @supplierPlNo IS  NULL))
			BEGIN
			     SET @SQLQuery = 'SELECT * FROM('+@SQLQuery+')a Where PART_NO LIKE ''%' + @partNumber + '%'''
			END
			--Get Filter by mfgr part Number
			ELSE IF ((@partNumber = '' OR  @partNumber IS  NULL) AND  (@mfgrPartNo <> '' OR @mfgrPartNo IS NOT NULL) AND  (@supPartNo = '' OR @supPartNo IS NULL)  
		             AND (@supplierPlNo = '' OR @supplierPlNo IS  NULL))
			BEGIN
			     SET @SQLQuery = 'SELECT * FROM('+@SQLQuery+')a Where mfgr_pt_no  LIKE ''%' + @mfgrPartNo + '%'''
			END
			--Get Filter by mfgr part Number
			ELSE IF ((@partNumber = '' OR  @partNumber IS  NULL) AND  (@mfgrPartNo ='' OR @mfgrPartNo IS NULL) AND  (@supPartNo <> '' OR @supPartNo IS NOT NULL)
			       AND (@supplierPlNo = '' OR @supplierPlNo IS  NULL))
			   
			BEGIN
			     SET @SQLQuery = 'SELECT * FROM('+@SQLQuery+')a where ponum LIKE ''%' + @supPartNo + '%'''
			END

			--Get Filter by supplier Number
			ELSE IF ((@partNumber = '' OR  @partNumber IS  NULL) AND  (@mfgrPartNo ='' OR @mfgrPartNo IS NULL) AND  (@supPartNo = '' OR @supPartNo IS NULL)
			       AND (@supplierPlNo <> '' OR @supplierPlNo IS NOT NULL))
			BEGIN
			     SET @SQLQuery = 'SELECT * FROM('+@SQLQuery+')a  Where recPklNo LIKE ''%' + @supplierPlNo + '%''' 
			END

			--Get Filter by supplier Number
			ELSE IF ((@partNumber = '' OR  @partNumber IS  NULL) AND  (@mfgrPartNo ='' OR @mfgrPartNo IS NULL) AND  (@supPartNo <> '' OR @supPartNo IS NOT NULL)
			       AND (@supplierPlNo = '' OR @supplierPlNo IS  NULL))
			BEGIN
			     SET @SQLQuery = 'SELECT * FROM('+@SQLQuery+')a WHERE dockDate  >=''' + CONVERT(VARCHAR(10),@startDate, 101) + '''  AND dockDate <''' + CONVERT(VARCHAR(10),@endDate + 1, 101) + ''''
			END

			IF (@startDate <> '' OR @endDate IS NOT NULL) 
			BEGIN
			     SET @SQLQuery = 'SELECT * FROM('+@SQLQuery+')a WHERE dockDate  >=''' + CONVERT(VARCHAR(10),@startDate, 101) + '''  AND dockDate <''' + CONVERT(VARCHAR(10),@endDate + 1, 101) + ''''
			END
		
			IF @filter <> '' AND @sortExpression <> ''
				BEGIN
					SET @qryMain='SELECT * FROM('+@SQLQuery+')a  ' +@filter+ ' ORDER BY '+ @sortExpression+''
				END

			ELSE IF @filter = '' AND @sortExpression <> ''
				BEGIN
				    SET @qryMain='SELECT * FROM('+@SQLQuery+')a  ORDER BY '+ @sortExpression+''
				END
			ELSE IF @filter <> '' AND @sortExpression = ''
				BEGIN
				     SET @qryMain='SELECT * FROM('+@SQLQuery+')a ' +@filter+ ''
				END
			ELSE
				BEGIN
				     SET @qryMain='SELECT * FROM('+@SQLQuery+')a  ORDER BY RejectedAt  
					        OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS  
							FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'
				END
			  EXEC sp_executesql @qryMain    
			END

