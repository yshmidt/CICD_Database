-- ==========================================================================================    
-- Author:  <Shivshankar P>    
-- Create date: <07/22/2019>    
-- Description: Update MRPACTLog EmailStatus
-- exec [UpdateMRPACTLogEmailStatus] '2T06HF3J4N'
-- ==========================================================================================    
CREATE PROCEDURE [dbo].[UpdateMRPACTLogEmailStatus]
(  
--	@mRPActUniqKey AS CHAR(50)
     @linkAdd CHAR(10)
)  
AS  
BEGIN  

	SET NOCOUNT ON;  
	--UPDATE MRPACTLog SET EmailStatus=1 WHERE MRPActUniqKey=@mRPActUniqKey

		UPDATE MRPACTLog SET EmailStatus = 1 where MRPActUniqKey in (SELECT  t1.MRPActUniqKey
             FROM MRPACTLog t1 
			 JOIN POITEMS  on POITEMS.PONUM =  RTRIM(LTRIM(REPLACE(t1.REF,'PO',''))) AND t1.UNIQ_KEY = POITEMS.UNIQ_KEY
			 INNER JOIN POMAIN ON POITEMS.PONUM = POMAIN.PONUM 
			 INNER JOIN SUPINFO on POMAIN.UNIQSUPNO =   SUPINFO.UNIQSUPNO 
			 --LEFT JOIN CCONTACT ON SUPINFO.SUPID = CCONTACT.CUSTNO and CCONTACT.TYPE = 'S'
			 INNER join SHIPBILL ON SUPINFO.supid=SHIPBILL.CUSTNO and Pomain.C_LINK =ShipBill.LINKADD and Shipbill.recordtype ='C'
			 LEFT OUTER JOIN CCONTACT on (Shipbill.custno+'S'+RTRIM(Shipbill.attention)) = ( Ccontact.custno+Ccontact.type+Ccontact.cid )
			 OUTER APPLY (SELECT aspnet_Profile.FirstName + ' ' + aspnet_Profile.LastName AS  BuyerName FROM aspnet_Profile LEFT JOIN POMAIN ON aspnet_Profile.UserId = POMAIN.aspnetBuyer 
			               WHERE  POMAIN.PONUM=replace(t1.REF,'PO ','')) PoBuyer
			 OUTER APPLY (SELECT  MRPACTUNIQKEY FROM  MRPACTLOG 
				               OUTER APPLY (SELECT REF FROM  MRPACTLOG T WHERE ACTION ='RELEASE PO' GROUP BY REF) TT 
							                       WHERE ACTION ='RELEASE PO' AND  MRPACTLOG.REF = TT.REF) T 
			 WHERE ((t1.ACTION ='RELEASE PO' AND  T.MRPACTUNIQKEY =T1.MRPACTUNIQKEY) OR  (t1.ACTION <> 'RELEASE PO' AND 1=1))
			       AND SHIPBILL.LINKADD = @linkAdd
			 )


END	
