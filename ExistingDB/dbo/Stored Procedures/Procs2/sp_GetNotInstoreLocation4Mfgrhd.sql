-- =============================================
-- Author:		Vicky	
-- Create date: 08/06/2010
-- Description:	Invtmfgr view for selected uniqmfgrhd
--Modified : 10/10/14 YS replace invtmfhd table with Invtmpnlink
-- 03/21/18 VL:	use allow to kit from not netable setting
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetNotInstoreLocation4Mfgrhd] @lcUniqMfgrHd AS char(10) = '', @lcW_key char(10) = '' OUTPUT
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;


DECLARE @lcReturnW_key char(10), @lcUniq_key char(10), @lcWhNo char(3), @lcUniqWh char(10),
		@lcNewUniqNbr char(10), @lcChkW_key char(10), @llKitAllowNonNettable bit;

-- 03/21/18 use allow to kit from not netable setting
SELECT @llKitAllowNonNettable = lKitAllowNonNettable FROM KitDef

-- 12/02/10 VL added AND Invtmfgr.CountFlag = ''
SELECT @lcReturnW_key = W_key
	FROM Invtmfgr, WAREHOUS	
	WHERE INVTMFGR.UniqWh = WAREHOUS.UniqWh
	AND Warehouse <> 'WO-WIP'
	AND Warehouse <> 'WIP'
	AND Warehouse <> 'MRB'	
	AND INVTMFGR.INSTORE = 0
	AND INVTMFGR.UNIQMFGRHD = @lcUniqMfgrHd
	AND Invtmfgr.CountFlag = ''
	AND INVTMFGR.IS_DELETED = 0
	-- 03/21/18 use allow to kit from not netable setting
	AND ((@llKitAllowNonNettable = 1)  
	OR (@llKitAllowNonNettable <> 1 AND Invtmfgr.NetAble = 1))

IF @@ROWCOUNT > 0
	-- Find one not instore location (not deleted)
	SELECT @lcW_key = @lcReturnW_key;
ELSE
	BEGIN
	-- Try to find if not instore but deleted one
	SELECT @lcReturnW_key = W_key
		FROM Invtmfgr, WAREHOUS	
		WHERE INVTMFGR.UniqWh = WAREHOUS.UniqWh
		AND Warehouse <> 'WO-WIP'
		AND Warehouse <> 'WIP'
		AND Warehouse <> 'MRB'	
		AND INVTMFGR.INSTORE = 0
		AND INVTMFGR.UNIQMFGRHD = @lcUniqMfgrHd
		AND Invtmfgr.CountFlag = ''
		AND INVTMFGR.IS_DELETED = 1
		-- 03/21/18 use allow to kit from not netable setting
		AND ((@llKitAllowNonNettable = 1)  
		OR (@llKitAllowNonNettable <> 1 AND Invtmfgr.NetAble = 1))
		
		BEGIN
		IF @@ROWCOUNT > 0
			BEGIN
			-- Find a deleted invtmfgr record, need to un-delete it and get w_key
			UPDATE INVTMFGR 
				SET IS_DELETED = 0
				WHERE W_KEY = @lcReturnW_key;
				
			SELECT @lcW_key = @lcReturnW_key;
			END
		ELSE
			BEGIN
			BEGIN
			-- Can not find any not instore location, has to create one
			--  Get uniq_key
			--10/10/14 YS replace invtmfhd table with Invtmpnlink
			--SELECT @lcUniq_key = Uniq_key	
			--	FROM INVTMFHD 
			--	WHERE UNIQMFGRHD = @lcUniqMfgrHd
			SELECT @lcUniq_key = Uniq_key	
				FROM InvtMPNLink 
				WHERE UNIQMFGRHD = @lcUniqMfgrHd

			-- 10/14/13 VL fix the error that those 2 veriables didn't get assign values
			--SELECT @lcWhNo, @lcUniqWh 
			SELECT @lcWhNo = Whno, @lcUniqWh = UniqWh
				FROM WAREHOUS	
				WHERE [DEFAULT] = 1
			END
			BEGIN
				WHILE (1=1)
				BEGIN
					EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
					SELECT @lcChkW_key = W_key FROM Invtmfgr WHERE W_key = @lcNewUniqNbr
					IF (@@ROWCOUNT<>0)
						CONTINUE
					ELSE
						BREAK
				END
				INSERT INTO INVTMFGR (UniqMfgrHd,W_key,Uniq_key,Netable,InStore, UniqWh) 
					VALUES (@lcUniqMfgrHd,@lcNewUniqNbr,@lcUniq_key,1,0,@lcUniqWh)
			END
			SELECT @lcW_key = @lcNewUniqNbr;
			END
		END
	END
END