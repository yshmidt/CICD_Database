-- =========================================================================================================
-- Author:		Shivshankar P
-- Create date: 05/23/2017
-- Description:	 Get SID Lot detail.
--Shivshsnkar P :07/06/17 Get WareHouse ,Location and QTY_OH for manual part
--exec GetLotSIDDetails @RecordId=N'',@ReceiverNo=N'0000001163',@LocUniq=N'WZTD2UUJB2',@PONum=N'000000000001685'
--exec GetLotSIDDetails @RecordId=N'4QTSZPMDXN',@ReceiverNo=N'0000001213',@LocUniq=N'4VOE7FDPZO',@PONum=N'000000000001687'
--exec GetLotSIDDetails @RecordId=N'4QTSZPMDXN',@ReceiverNo=N'0000001213',@LocUniq=N'4VOE7FDPZO',@PONum=N'000000000001687'
--02/09/18 YS uniqwh is char(10) not char(15)
-- 08/06/2019 Rajendra : Changed location datatype from VARCHAR to NVARCHAR
-- 08/08/19 YS location is 200 characters in all the tables
-- =========================================================================================================
CREATE PROCEDURE [dbo].[GetLotSIDDetails]  
@RecordId char (10) ='',
@ReceiverNo Char(10) = '',
@LocUniq  char(10)='',
@PONum CHAR (15)='',
@UniqMfgrhd Char(10) = '',
@UniqKey  char(10)='',
--02/09/18 YS changed the size to 10 according to the BD
@UniqWh CHAR (10)='',
@Location NVARCHAR(200) ='',-- 08/06/2019 Rajendra : Changed location datatype from VARCHAR to NVARCHAR
@IsManualPart bit =0
AS 
BEGIN
 IF(@RecordId IS NOT NULL AND @RecordId <> '' AND  @IsManualPart =0)
 BEGIN
		select  ROW_NUMBER()  OVER (ORDER BY ipk.IPKEYUNIQUE)  AS RowNumber, ipk.IPKEYUNIQUE ,invt.LOTCODE,invt.REFERENCE,invt.EXPDATE,ipk.pkgBalance as ActualBal,  ipk.pkgBalance - ipk.qtyAllocatedTotal  as LOTQTY,ipk.qtyAllocatedTotal,
		cast( 0 as int) as LOTRESQTY  ,poit.SCHD_DATE, ipk.UNIQ_KEY,ipk.W_KEY ,PORECLOCIPKEY.IPKEYLOCUNIQUE  ,invt.UNIQ_LOT ,invtgr.LOCATION ,wah.WAREHOUSE AS UNIQWH
	     from IPKEY ipk LEFT join  PORECLOCIPKEY on ipk.IPKEYUNIQUE =   PORECLOCIPKEY.IPKEYUNIQUE Left JOIN INVTLOT invt on
		ipk.LOTCODE =invt.LOTCODE AND  ipk.PONUM =invt.PONUM AND ipk.REFERENCE =invt.REFERENCE  AND ipk.EXPDATE =invt.EXPDATE LEFt 
		JOIN PORECLOT porecl on porecl.LOTCODE =invt.LOTCODE AND porecl.REFERENCE =invt.REFERENCE  AND porecl.EXPDATE =invt.EXPDATE
		Left JOIN PORECLOC porec on porec.LOC_UNIQ = @LocUniq
		JOIN POITSCHD poit on poit.UNIQDETNO = porec.UNIQDETNO
		Left Join INVTMFGR invtgr on invtgr.W_key= ipk.W_key
		Left Join WAREHOUS wah on wah.UNIQWH= invtgr.UNIQWH
		where RecordId = @RecordId AND  ipk.pkgBalance - ipk.qtyAllocatedTotal  > 0
		
	END 
--Shivshsnkar P :07/06/17 Get WareHouse ,Location and QTY_OH for manual part
ELSE  IF(@IsManualPart =1)  
	Begin
     	select ROW_NUMBER()  OVER (ORDER BY W_KEY)  AS RowNumber,LOCATION,wah.WAREHOUSE AS UNIQWH,W_KEY,UNIQMFGRHD,UNIQ_KEY, QTY_OH -RESERVED AS  LOTQTY from INVTMFGR
		Left Join WAREHOUS wah on wah.UNIQWH= INVTMFGR.UNIQWH where UNIQMFGRHD =@UniqMfgrhd and UNIQ_KEY =@UniqKey and INVTMFGR.UNIQWH = @UniqWh and LOCATION =@Location AND  QTY_OH -RESERVED >0

	END
ELSE
	BEGIN
		select  ROW_NUMBER()  OVER (ORDER BY invt.UNIQ_LOT)  AS RowNumber, invt.UNIQ_LOT, invt.LOTCODE,invt.REFERENCE,invt.EXPDATE,invt.LOTQTY  as ActualBal,invt.LOTQTY - invt.LOTRESQTY as LOTQTY,
		cast( 0 as int) as LOTRESQTY ,poit.SCHD_DATE,invt.W_KEY ,wah.WAREHOUSE AS UNIQWH,invtgr.LOCATION from PORECLOT pore join INVTLOT invt on pore.LOTCODE =invt.LOTCODE AND pore.REFERENCE =invt.REFERENCE  AND pore.EXPDATE = invt.EXPDATE
		Left JOIN PORECLOC porec on porec.LOC_UNIQ = pore.LOC_UNIQ JOIN POITSCHD poit on poit.UNIQDETNO = porec.UNIQDETNO
		Left Join INVTMFGR  invtgr on invtgr.W_KEY = invt.W_KEY
		Left Join WAREHOUS wah on wah.UNIQWH= invtgr.UNIQWH 
		WHERE (porec.RECEIVERNO = @ReceiverNo AND pore.LOC_UNIQ= @LocUniq AND invt.PONUM = @PONum) AND  invt.LOTQTY - invt.LOTRESQTY  > 0

	END

END
