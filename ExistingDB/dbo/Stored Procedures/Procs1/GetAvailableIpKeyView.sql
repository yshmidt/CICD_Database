-- =============================================
-- Author:	Sachin b
-- Create date: 06/07/2016
-- Description:	this procedure will be called from the SF module while manual transfer return from FGI if part is side trackable get all the ipkey
-- 10/30/2017 Sachin B Change the logic for getting recived SID pkgBalance,Remove join with iRecIpKey table and change join with IPKEY by INVTREC_NO and Apply Code review Comments
-- =============================================
CREATE PROCEDURE [dbo].[GetAvailableIpKeyView] --[GetAvailableIpKeyView] '0000000607','_1EP0LML8M',''
	-- Add the parameters for the stored procedure here
	@woNo char(10)=' ',
	@wKey char(10) = '',
	@UniqLot char(10) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
SET NOCOUNT ON;

-- 10/30/2017 Sachin B Change the logic for getting recived SID pkgBalance,Remove join with iRecIpKey table and change join with IPKEY by INVTREC_NO and Apply Code review Comments
SELECT  (ip.pkgBalance-ip.qtyAllocatedTotal) AS pkgBalance,ip.IPKEYUNIQUE,0.0 AS QtyUsed 
FROM WOENTRY wo 
INNER JOIN INVENTOR i ON wo.uniq_key =i.UNIQ_KEY
INNER JOIN invt_rec rec ON rec.UNIQ_KEY =i.UNIQ_KEY
--inner join iRecIpKey recip on recip.invtrec_no = rec.INVTREC_NO
INNER JOIN IPKEY ip ON rec.INVTREC_NO = ip.RecordId
WHERE wo.wono =@woNo AND ip.W_KEY = @wKey AND rec.W_KEY =@wKey AND COMMREC LIKE '%WIP-FGI:'+@Wono AND rec.UNIQ_LOT =@UniqLot AND (ip.pkgBalance-ip.qtyAllocatedTotal)>0
END