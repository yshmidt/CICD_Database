-- =============================================
-- Author: Rajendra K
-- Create date: <11/27/2017>
-- Description:	Get Qty_Oh for CC
-- Modification 
   -- Rajendra K : replaced @useIPKey =I.UseIPKey with hardcoded value
   -- 04/06/2018 Rajendra K : Added condition I.UNIQ_KEY = @uniqKey
   -- 05/09/2019 Rajendra K : Removed join with CcRecord table and C.CCRECNCL = 1 condition for QtyOh
-- SELECT dbo.fn_GetCCQtyOH('_01F15T0KC','01LGXJE8N2','','_1EI0NKCUE')
CREATE FUNCTION [dbo].[fn_GetCCQtyOh]
(
@uniqKey CHAR(10)='',
@wKey CHAR(10)='',
@uniqLot CHAR(10)='',
@sid CHAR(10)=''
)
RETURNS DECIMAL(13,5)
AS 
BEGIN
DECLARE @qtyOh DECIMAL(13,5) = 0

DECLARE @randomPart TABLE (Uniq_key CHAR(10))	-- Insert only the number of daily count

DECLARE @lNotInstore BIT

DECLARE @lcAbc_Type AS CHAR(1),@lnCc_Days NUMERIC(7,0) = 1

DECLARE @isLotted BIT,@useIPKey BIT

SELECT @lcAbc_Type = ABC ,@lnCc_Days = CC_DAYS FROM INVENTOR I INNER JOIN INVTABC IA ON I.ABC = IA.ABC_TYPE AND I.UNIQ_KEY = @uniqKey -- 04/06/2018 Rajendra K : Added condition I.UNIQ_KEY = @uniqKey

SELECT @isLotted = P.LOTDETAIL,@useIPKey = I.UseIPKey  FROM INVENTOR I INNER JOIN Parttype P ON I.PART_CLASS = P.PART_CLASS AND I.PART_TYPE =  P.PART_TYPE AND I.UNIQ_KEY = @uniqKey  -- Rajendra K : replaced @useIPKey =I.UseIPKey with hardcoded value

SELECT @lNotInstore = NotInstore FROM Abcsetup

-- All records that are type @lcAbc_Type
  -- 05/09/2019 Rajendra K : Removed join with CcRecord table and C.CCRECNCL = 1 condition for QtyOh
IF EXISTS(SELECT DISTINCT(I.UNIQ_KEY) FROM Inventor I, InvtMfgr IM, Warehous W WHERE I.Abc = @lcAbc_Type AND I.Uniq_Key = IM.Uniq_Key AND I.Uniq_Key = @uniqKey --, CcRecord C
		AND IM.COUNTFLAG = ''
		AND W.UniqWh = IM.UniqWh 
		AND W.Warehouse <> 'MRB'
		AND W.Warehouse <> 'WO-WIP'
		AND Part_Sourc <> 'CONSG'
		AND Part_Sourc <> 'PHANTOM'
		AND 1 = CASE WHEN COUNT_DT IS NULL THEN 1 ELSE CASE WHEN COUNT_DT + @lnCc_Days <= GETDATE() THEN 1 ELSE 0 END END
        AND I.Status = 'ACTIVE'
		--AND C.CCRECNCL = 1    -- 05/09/2019 Rajendra K : Removed join with CcRecord table and C.CCRECNCL = 1 condition for QtyOh
		AND IM.Is_Deleted = 0
		AND 0 = (CASE WHEN @lNotInstore = 1 THEN IM.INSTORE ELSE 0 END)
		AND (@wKey IS NULL OR @wKey = '' OR IM.W_KEY = @wKey)		
		)
 BEGIN
	IF (@isLotted = 0 AND @useIPKey=0)
	BEGIN
	-- Non Lot code and Non SID parts
		SET @qtyOh = (SELECT SUM(IM.Qty_OH) 
		FROM Inventor I INNER JOIN InvtMPNLink L ON I.Uniq_key = L.UNIQ_KEY AND I.UNIQ_KEY = @uniqKey
			 INNER JOIN Invtmfgr IM ON L.uniqmfgrhd=IM.UNIQMFGRHD
			 INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId 
			 INNER JOIN Warehous W ON IM.UniqWh = W.UniqWh	
			 AND L.Is_Deleted = 0
			 AND M.IS_Deleted = 0
			 AND IM.Is_Deleted = 0
			 AND Warehouse <> 'MRB'
			 AND Warehouse <> 'WO-WIP'
			 AND (@wKey IS NULL OR @wKey = '' OR IM.W_KEY = @wKey)
			 AND ((@lNotInstore=1 and IM.INSTORE=0) OR (@lNotInstore=0))
			 AND IM.Uniq_key = @uniqKey
			 )
	END 

	ELSE IF(@useIPKey=0 AND @isLotted = 1)
	BEGIN
	-- Lot code parts
	SET @qtyOh = (SELECT SUM(Invtlot.LOTQTY) AS Qty_oh 
	FROM Inventor INNER JOIN InvtMPNLink L ON Inventor.Uniq_key = L.UNIQ_KEY AND Inventor.UNIQ_KEY = @uniqKey
			INNER JOIN Invtmfgr IM ON L.uniqmfgrhd=IM.UNIQMFGRHD
			INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId 
			INNER JOIN Warehous ON IM.UniqWh = Warehous.UniqWh	
			INNER JOIN Invtlot ON IM.w_key = Invtlot.W_key AND Invtlot.UNIQ_LOT = @uniqLot 
			AND L.Is_Deleted = 0
			AND M.Is_Deleted = 0
			AND IM.Is_Deleted = 0
			AND Warehouse <> 'MRB'
			AND Warehouse <> 'WO-WIP'
			AND ((@lNotInstore=1 and IM.INSTORE=0) OR (@lNotInstore=0))
			AND (@wKey IS NULL OR @wKey = '' OR IM.W_KEY = @wKey) 
			AND IM.Uniq_key  = @uniqKey
			)
END

	ELSE IF(@useIPKey=1)
	-- SID parts
	BEGIN
		SET @qtyOh = (SELECT SUM(IP.pkgBalance) AS Qty_oh
		FROM Inventor I INNER JOIN InvtMPNLink L ON I.Uniq_key = L.UNIQ_KEY AND I.UNIQ_KEY = @uniqKey
			 INNER JOIN Invtmfgr IM ON L.uniqmfgrhd=IM.UNIQMFGRHD
			 INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId 
			 INNER JOIN Warehous W ON IM.UniqWh = W.UniqWh	
			 INNER JOIN IPKEY IP ON I.UNIQ_KEY = IP.UNIQ_KEY AND IM.W_KEY = IP.W_KEY AND IP.IPKEYUNIQUE = @sid
			 AND L.Is_Deleted = 0
			 AND M.IS_Deleted = 0
			 AND IM.Is_Deleted = 0
			 AND Warehouse <> 'MRB'
			 AND Warehouse <> 'WO-WIP'
			 AND (@wKey IS NULL OR @wKey = '' OR IM.W_KEY = @wKey)
			 AND ((@lNotInstore=1 and IM.INSTORE=0) OR (@lNotInstore=0))
			 AND IM.Uniq_key = @uniqKey
			 )
	END 
 END
	RETURN ISNULL(@qtyOh,0)
END

