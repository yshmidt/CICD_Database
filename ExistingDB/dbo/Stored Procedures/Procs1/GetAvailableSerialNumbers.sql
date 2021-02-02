-- =============================================
-- Author:Rajendra K
-- Create date: 03/07/2017
-- Description:	Get SerialNumber details
CREATE PROCEDURE [dbo].[GetAvailableSerialNumbers]
(
	@uniqKey AS CHAR(10) = '',
	@wKey AS CHAR(10) = '',
	@uniqLot AS CHAR(10) = '',
	@sid AS CHAR(10) = '',
	@rowNumber AS VARCHAR(10)
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT DISTINCT	ISer.SerialUniq
				   ,CAST(dbo.fremoveLeadingZeros(ISer.SerialNo) AS VARCHAR(MAX)) AS SerialNo
				   ,ISer.SerialNo AS Serial 
				   ,ISer.UNIQ_KEY
				   ,ISer.UNIQ_LOT
				   ,ISer.IpKeyUnique
				   ,IMF.W_KEY
				   ,@rowNumber AS RowNumber
	FROM InvtSer ISer INNER JOIN InvtMfgr IMF ON ISer.ID_VALUE = IMF.W_KEY AND ID_KEY ='W_KEY'
					  LEFT OUTER JOIN IPKEY IP ON ISer.ipkeyunique = IP.IPKEYUNIQUE 
							   OR(ISer.LOTCODE = IP.LOTCODE 
							   AND ISer.EXPDATE = IP.EXPDATE
							   AND ISer.PONUM = IP.PONUM
							   AND ISer.REFERENCE = IP.REFERENCE)
					  LEFT JOIN INVTLOT IL ON ISer.UNIQ_LOT = IL.UNIQ_LOT
	WHERE Iser.IsReserved = 0 AND (@uniqKey IS NULL OR @uniqKey = '' OR ISer.UNIQ_KEY = @uniqKey )	 
		  AND (@wKey IS NULL OR @wKey = '' OR IMF.W_KEY = @wKey )	 
		  AND (@sid IS NULL OR @sid = '' OR ISer.IPKEYUNIQUE= @sid)
		  AND (@sid IS NULL OR @sid = '' OR IP.IPKEYUNIQUE= @sid)
		  AND (@uniqLot IS NULL OR @uniqLot = '' OR ISer.UNIQ_LOT = @uniqLot)	 
	ORDER BY Serial
END