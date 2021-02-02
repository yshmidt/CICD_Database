-- =============================================
-- Author:		Sachin B
-- Create date: 09/09/2016
-- Create date: 10/27/2016
-- Description:	this procedure will be called from the SF module and get part detail by ipkey
-- [dbo].[GetPartDetailByIpKey] '03HQR6OMFT','0000000516','STAG'  -- reserve SID [GetPartDetailByIpKey] '76DWS9NKKO' '759H3PO59U'
-- Sachin B: 10/12/2016: Remove And Condition because it can't get data fro the reserve parts
-- Sachin B :01/12/2016 Removed unused joins because ipkey table contains all information as per discussion
-- Sachin B :09/12/2017 Getting pkgbalance of SID 
-- Sachin B :09/21/2017 Add logic for the get Resevred SID info if same part is present as line shoratge in Same WC and parameter @wono and @deptId
-- =============================================

CREATE PROCEDURE [dbo].[GetPartDetailByIpKey] 
	-- Add the parameters for the stored procedure here
	@ipkey char(10) ='',
	@wono char(10) ='',
	@deptId char(4)
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
    
	-- Sachin B :09/21/2017 Add logic for the get Resevred SID info if same part is present as line shoratge in Same WC and parameter @wono and @deptId
	Declare @IsReserve bit
	SET @IsReserve =(select count(*) from IPKEY where IPKEYUNIQUE =@ipkey and qtyAllocatedTotal>0)

    IF(@IsReserve =0)
		BEGIN
			-- Sachin B :01/12/2016 Removed unused joins because ipkey table contains all information as per discussion
			SELECT DISTINCT ip.UNIQ_KEY,ip.W_KEY,ISNULL(lot.UNIQ_LOT,'') AS UNIQ_LOT,lot.LOTCODE,lot.EXPDATE,lot.REFERENCE,ip.IPKEYUNIQUE,ip.PONUM,(ip.pkgBalance) as PkgBalance,k.KASEQNUM
			FROM IPKEY ip
			Inner Join KAMAIN k on ip.UNIQ_KEY =k.UNIQ_KEY and k.WONO =@wono --and k.allocatedQty =0
			LEFT OUTER JOIN INVTLOT lot ON lot.W_KEY =ip.W_KEY and ISNULL(lot.EXPDATE,1) = ISNULL(ip.EXPDATE,1) and lot.LOTCODE = ip.LOTCODE and lot.REFERENCE = ip.REFERENCE and lot.PONUM = ip.PONUM
			WHERE ip.IPKEYUNIQUE = @ipkey AND (@deptId IS NULL OR @deptId='' OR k.DEPT_ID=@deptId) and ip.qtyAllocatedTotal =0
		END
    ELSE
	    BEGIN
		    SELECT DISTINCT ip.UNIQ_KEY,ip.W_KEY,ISNULL(lot.UNIQ_LOT,'') AS UNIQ_LOT,lot.LOTCODE,lot.EXPDATE,lot.REFERENCE,ip.IPKEYUNIQUE,ip.PONUM,(ip.pkgBalance) as PkgBalance,res.KaSeqnum
			FROM IPKEY ip
			Inner Join iReserveIpKey resIp on ip.IPKEYUNIQUE =resIp.ipkeyunique
			Inner join INVT_RES res on resIp.invtres_no =res.INVTRES_NO and res.WONO =@wono
			LEFT OUTER JOIN INVTLOT lot ON lot.W_KEY =ip.W_KEY and ISNULL(lot.EXPDATE,1) = ISNULL(ip.EXPDATE,1) and lot.LOTCODE = ip.LOTCODE and lot.REFERENCE = ip.REFERENCE and lot.PONUM = ip.PONUM
			WHERE ip.IPKEYUNIQUE = @ipkey
		END
END
