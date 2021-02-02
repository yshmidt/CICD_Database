
-- =============================================
-- Author: Shivshankar Patil	
-- Create date: <11/30/17>
-- Description:	<Get PO Inspection History(Inspection Completed records)> 
-- 06/12/2017 Shivshankar P :  Get Filter PART_NO,mfgr_pt_no,ponum,recPklNo and @startDate and @endDate
-- 16/09/2017 Shivshankar P :  Get Filter PART_NO,mfgr_pt_no,ponum,recPklNo with @startDate and @endDate OR @startDate and @endDate 
-- 27/09/2017 Shivshankar P :  Modified for improving the performance, and handled all the filters conditional,separate query for total Count and Removed unused variable
-- 10/23/2017 Shivshankar P :  Get the records including previous 1  from initial 
-- 01/19/2018 Shivshankar P :  Added filter and sort functionality and Changed buyer 
-- 05/04/2018 Shivshankar P :  Changed the lenght of feilds
--[GetEditPOReceiptRecords] @isIsnpection=0
-- =============================================
CREATE PROCEDURE [dbo].[GetEditPOReceiptRecords] 
	-- Add the parameters for the stored procedure here
	@uniqSupNo nvarchar(10)  =' ',
	@poNum CHAR(15) = ' ' ,
	@reckPklNo nvarchar(50) =  ' ' ,
	@mfgrPtNo CHAR (30) =' ',
	@uniqKey CHAR(10) =' ',
	@StartRecord int =1,
    @EndRecord int =1000, 
	@isIsnpection bit=0,
    @SortExpression nvarchar(1000) = null,----asc/desc
    @Filter nvarchar(1000) = null--Order by Columns 
AS
 BEGIN
     SET NOCOUNT ON;
	 DECLARE @SQLQuery NVARCHAR(2000);
     DECLARE @qryMain  NVARCHAR(2000); 

	
	 SET @SQLQuery = 'SELECT SUPINFO.SUPNAME AS SupName, receiverHeader.PONum,recPklNo,ReceiverNo, Waybill,dockDate AS ReceiveDate,UserName AS Initials,CONUM,SUPINFO.UNIQSUPNO
	                 ,recPklNo AS SupplierPackListNo,UserName AS BuyerStr,receiverDetail.receiverHdrId 
                     FROM  receiverHeader 
						  JOIN POMAIN ON POMAIN.PONUM =  receiverHeader.ponum
						  JOIN receiverDetail ON receiverDetail.receiverHdrId =  receiverHeader.receiverHdrId
						  LEFT JOIN SUPINFO ON SUPINFO.UNIQSUPNO =  receiverHeader.senderId
						   LEFT JOIN aspnet_Users 
						        ON POMAIN.aspnetbuyer = aspnet_Users.UserId WHERE  
						    
						                ((''' + CONVERT(VARCHAR(10),@isIsnpection, 101) + '''=1 AND receiverDetail.isinspCompleted=1 and receiverDetail.isCompleted = 0) 
										 OR  (''' + CONVERT(VARCHAR(10),@isIsnpection, 101) + '''=0 AND receiverDetail.isinspCompleted=receiverDetail.isinspCompleted))
										AND ((''' + CONVERT(VARCHAR(10),@uniqSupNo, 101) + '''='' '' AND senderId=senderId) 
										OR (''' + CONVERT(VARCHAR(10),@uniqSupNo, 101) + ''' <> '' '' AND senderId = ''' + CONVERT(VARCHAR(10),@uniqSupNo, 101) + '''))
										AND ((''' + CONVERT(VARCHAR(15),@poNum, 101) + '''='' '' AND receiverHeader.PONUM=receiverHeader.PONUM) 
										OR (''' + CONVERT(VARCHAR(15),@poNum, 101) + ''' <> '' '' AND receiverHeader.PONUM = ''' + CONVERT(VARCHAR(15),@poNum, 101) + '''))
									    AND ((''' + CONVERT(VARCHAR(50),@reckPklNo, 101) + '''='' '' AND receiverHeader.recPklNo = receiverHeader.recPklNo) 
										OR (''' + CONVERT(VARCHAR(50),@reckPklNo, 101) + ''' <> '' '' AND receiverHeader.recPklNo = ''' + CONVERT(VARCHAR(50),@reckPklNo, 101) + '''))

										AND ((''' + CONVERT(VARCHAR(10),@uniqKey, 101) + '''='' '' AND receiverDetail.Uniq_key = receiverDetail.Uniq_key) 
										OR (''' + CONVERT(VARCHAR(10),@uniqKey, 101) + ''' <> '' '' AND receiverDetail.Uniq_key= ''' + CONVERT(VARCHAR(10),@uniqKey, 101) + '''))

										AND ((''' + CONVERT(VARCHAR(30),@mfgrPtNo, 101) + '''='' '' AND mfgr_pt_no=mfgr_pt_no) 
										OR (''' + CONVERT(VARCHAR(30),@mfgrPtNo, 101) + ''' <> '' '' AND mfgr_pt_no = ''' + CONVERT(VARCHAR(30),@mfgrPtNo, 101) + '''))'
									  


       	      -- Shivshankar P :  01/19/17 Added filter and sort functionality	  
			 DECLARE @rowCount NVARCHAR(MAX) = (SELECT dbo.fn_GetDataBySortAndFilters(@SQLQuery,@filter,@sortExpression,'',
			                                                        'receiverHdrId',@startRecord,@endRecord))
              EXEC sp_executesql @rowCount


	         SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters(@SQLQuery,@filter,@sortExpression,'PONUM','',@startRecord,@endRecord))
			 EXEC sp_executesql @sqlQuery

END

