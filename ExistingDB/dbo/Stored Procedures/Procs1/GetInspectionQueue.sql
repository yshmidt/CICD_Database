-- =============================================
-- Author: Shivshankar Patil	
-- Create date: <03/15/16>
-- Description:	<Get PO Inspection Queue(Inspection In Queue records)>
--09/08/16 Shiv Shanker Add column receiverDetId,Partmfgr,inspHeaderId in SELECT 
--06/12/2017   Shivshankar P :  Get receiver Header and SupIfo for redirecting to the PO receiving
-- 10/23/2017 Shivshankar P :  Get the records FROM initial
-- 10/26/2017 Shivshankar P :  For filtering used dynamic sql and changed condtions
-- 05/23/2018 Shivshankar P :  Displaye on Qty_rec by failed Qty
-- 03/23/2018 Nilesh Sa :  Added uniqKey in selection
-- 10/11/2018 Rajendra K :  Added Inspection in selection
-- 4/4/2019 Nitesh B :  Added dbo.fRemoveLeadingZeros function for PONUM   
-- 05/20/2019 Nitesh B :  Change join table aspnet_Profile to aspnet_Users to get UserName
-- =============================================
CREATE PROCEDURE [dbo].[GetInspectionQueue]
	-- Add the parameters for the stored procedure here
	@partNumber nvarchar(200)  =' ',
	@mfgrPartNo nvarchar(200) = ' ' ,
	@supPartNo nvarchar(200) = ' ',
	@startRecord int =1,
    @endRecord int =10, 
    @sortExpression nvarchar(1000) = null,----asc/desc
    @filter nvarchar(1000) = null--Order by Columns 
AS
BEGIN
SET NoCount ON;
	 DECLARE @SQLQuery NVARCHAR(2000);
     DECLARE @qryMain  NVARCHAR(2000); 

                 SELECT COUNT(rh.receiverHdrId)
				 FROM receiverHeader rh  inner join receiverDetail rd ON rh.receiverHdrId = rd.receiverHdrId AND rd.isinspReq = 1 AND rd.isinspCompleted = 0 
				 INNER JOIN INVENTOR ir ON rd.Uniq_key = ir.UNIQ_KEY				
				 Left JOIN aspnet_Users asp ON rh.recvBy = asp.UserId 
				 LEFT JOIN POITEMS pt ON rd.uniqlnno = pt.UNIQLNNO
				 Left  JOIN inspectionHeader ih ON ih.receiverDetId = rd.receiverDetId and ih.RejectedAt='Inspection'
				 OUTER APPLY (SELECT pn.UNIQSUPNO,sup.SUPNAME FROM POMAIN pn left join SUPINFO sup ON  sup.UNIQSUPNO = pn.UNIQSUPNO where pn.ponum  = rh.ponum) supInfo  --06/12/2017   Shivshankar P :  Get receiver Header and SupIfo for redirecting to the PO receiving

    
				 WHERE ((@partNumber <> ' ' AND ir.PART_NO like '%' + @partNumber +'%' OR @partNumber = ' ' AND ir.PART_NO=ir.PART_NO) AND 
				       (@mfgrPartNo <> ' ' AND rd.mfgr_pt_no  LIKE  '%' + @mfgrPartNo +'%' OR  @mfgrPartNo = '' AND rd.mfgr_pt_no=rd.mfgr_pt_no) 
					    AND  (@supPartNo <> ' ' AND  rh.ponum  like  '%' + @supPartNo  +'%' OR   @supPartNo  = '' AND rh.ponum=rh.ponum))
				  -- 05/23/2018 Shivshankar P :  Displaye on Qty_rec by failed Qty
                                  -- 10/11/2018 Rajendra K :  Added Inspection in selection
					    -- 4/4/2019 Nitesh B :  Added dbo.fRemoveLeadingZeros function for PONUM
				  SET @SQLQuery = 'SELECT  rh.receiverHdrId, rh.dockDate,ir.PART_NO,
									ir.INSP_REQ,ir.CERT_REQ,pt.FIRSTARTICLE,rd.isinspCompleted,ih.RejectedAt,ih.FailedQty,ih.inspHeaderId,
									ir.REVISION,rd.mfgr_pt_no, ir.PART_CLASS + '' / ''  + ir.PART_TYPE  +'' / '' + ir.DESCRIPT AS DESCRIPT,rd.Qty_rec - ISNULL(inspe_Qt.Failed_Qty,0) AS Qty_rec, dbo.fRemoveLeadingZeros(rh.ponum) AS ponum,asp.UserName AS Initials ,rh.recPklNo ,ir.Itar ,    
									CAST(0 AS bit) AS DFAR       
									,(SELECT aspbyer.UserName FROM POMAIN pn left join aspnet_Users aspbyer ON  pn.aspnetBuyer = aspbyer.UserId where pn.ponum  = rh.ponum)As BUYER  ,
										rd.receiverDetId,rd.Partmfgr,rh.receiverno, rh.carrier ,rh.waybill ,supInfo.UNIQSUPNO,supInfo.SUPNAME   
                                                                        	,ir.UNIQ_KEY AS UniqKey -- 03/23/2018 Nilesh Sa :  Added uniqKey in selection
										,rh.inspectionSource
									FROM receiverHeader rh  inner join receiverDetail rd ON rh.receiverHdrId = rd.receiverHdrId AND rd.isinspReq = 1 AND rd.isinspCompleted = 0 
									INNER JOIN INVENTOR ir ON rd.Uniq_key = ir.UNIQ_KEY				
									Left JOIN aspnet_Users asp ON rh.recvBy = asp.UserId  -- 05/20/2019 Nitesh B :  Change join table aspnet_Profile to aspnet_Users to get UserName
									LEFT JOIN POITEMS pt ON rd.uniqlnno = pt.UNIQLNNO
									Left  JOIN inspectionHeader ih ON ih.receiverDetId = rd.receiverDetId and ih.RejectedAt=''Inspection''
									OUTER APPLY (SELECT sum (FailedQty) AS Failed_Qty FROM inspectionHeader inspe   where inspe.receiverDetId = rd.receiverDetId  AND  inspe.RejectedAt=''Receiving'') inspe_Qt 
									OUTER APPLY (SELECT pn.UNIQSUPNO,sup.SUPNAME FROM POMAIN pn left join SUPINFO sup ON  sup.UNIQSUPNO = pn.UNIQSUPNO where pn.ponum  = rh.ponum) supInfo '


           IF ((@partNumber = '' OR @partNumber IS NULL) AND (@mfgrPartNo ='' OR @mfgrPartNo IS NULL) AND  (@supPartNo = '' OR @supPartNo IS NULL))
			BEGIN
			 SET @SQLQuery = 'SELECT * FROM('+@SQLQuery+')a'
			END
			--Get Filter by Part Number
			ELSE IF ((@partNumber <> '' OR @partNumber IS NOT NULL)  AND (@mfgrPartNo ='' OR @mfgrPartNo IS NULL) AND  (@supPartNo = '' OR @supPartNo IS NULL))
			BEGIN
			SET @SQLQuery = 'SELECT * FROM('+@SQLQuery+')a Where PART_NO LIKE ''%' + @partNumber + '%'''
			END
			--Get Filter by mfgr part Number
			ELSE IF ((@partNumber = '' OR  @partNumber IS  NULL) AND  (@mfgrPartNo <> '' OR @mfgrPartNo IS NOT NULL) AND  (@supPartNo = '' OR @supPartNo IS NULL))
			BEGIN
			SET @SQLQuery = 'SELECT * FROM('+@SQLQuery+')a Where mfgr_pt_no  LIKE ''%' + @mfgrPartNo + '%'''
			END
			--Get Filter by mfgr part Number
			ELSE IF ((@partNumber = '' OR  @partNumber IS  NULL) AND  (@mfgrPartNo ='' OR @mfgrPartNo IS NULL) AND  (@supPartNo <> '' OR @supPartNo IS NOT NULL))
			   
			BEGIN
			SET @SQLQuery = 'SELECT * FROM('+@SQLQuery+')a where ponum LIKE ''%' + @supPartNo + '%'''
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