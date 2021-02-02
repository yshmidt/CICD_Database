-- =============================================
-- Author:		Satish Bhosle	
-- Create date: <03/22/16>
-- Description:	<Get part number details> 
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- =============================================
CREATE PROCEDURE [dbo].[GetPartNumberDetails] --'0003201','0000000254'
	-- Add the parameters for the stored procedure here
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
       @partNumber AS char(35),
	   @woNumber as char(10)
AS
BEGIN
	SELECT i.PART_NO, i.REVISION,i.PART_CLASS,i.PART_TYPE,i.DESCRIPT,(k.SHORTQTY+(k.ACT_QTY+k.allocatedQty)) AS Required,
	r.QTYALLOC AS Allocated,
	k.SHORTQTY,k.act_qty 
	FROM INVENTOR i
	INNER JOIN KAMAIN k ON k.UNIQ_KEY=i.UNIQ_KEY
	INNER JOIN WOENTRY w ON w.WONO=k.WONO
	--INNER JOIN BOM_DET b ON b.UNIQ_KEY=k.UNIQ_KEY and b.BOMPARENT=k.BOMPARENT
	Left JOIN INVT_RES r ON r.WONO=k.WONO 
	--and r.UNIQ_KEY=k.UNIQ_KEY
	WHERE LTRIM(RTRIM(i.PART_NO))= LTRIM(RTRIM(@partNumber)) and LTRIM(RTRIM(k.WONO))=@woNumber
END

--select * from INVT_RES where PART_NO='416-0003807'
--select * from KAMAIN where UNIQ_KEY = '_3230QZMOS'
--select * from KAMAIN where WONO = '0000000247'

--select * from KAMAIN k inner join INVENTOR i on k.UNIQ_KEY = i.UNIQ_KEY where k.WONO = '0000000247' and i.PART_NO = '416-0003807'