-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- Modified: 10/10/14 YS replaced invtmfhd with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetWOWIPLocation4WonoKit] @lcWono char(10) = ' ', @lcPickW_key char(10) = ' ',
	@lcW_key char(10) = ' ' OUTPUT
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @lcReturnW_key char(10), @lcUniq_key char(10), @lcWhNo char(3), @lcUniqWh char(10),
		@lcNewUniqNbr char(10), @lcChkW_key char(10), @lcUniqMfgrHd char(10), @llInstore bit, 
		@lcUniqSupno char(10);

SELECT @lcUniqMfgrHd = UniqMfgrHd, @llInstore = Instore, @lcUniqSupno = UniqSupno 
	FROM INVTMFGR
	WHERE W_KEY = @lcPickW_key
		
SELECT @lcReturnW_key = W_key
	FROM Invtmfgr, WAREHOUS	
	WHERE INVTMFGR.UniqWh = WAREHOUS.UniqWh
	AND Warehouse = 'WO-WIP'
	AND LOCATION = 'WO'+@lcWono+SPACE(5)
	AND INVTMFGR.UNIQMFGRHD = @lcUniqMfgrHd
	AND INVTMFGR.INSTORE = @llInstore
	AND INVTMFGR.uniqsupno = @lcUniqSupno
	AND INVTMFGR.IS_DELETED = 0

IF @@ROWCOUNT > 0
	-- Find one not instore location (not deleted)
	SELECT @lcW_key = @lcReturnW_key;
ELSE
	BEGIN
	-- Try to find if not instore but deleted one
	SELECT @lcReturnW_key = W_key
		FROM Invtmfgr, WAREHOUS	
		WHERE INVTMFGR.UniqWh = WAREHOUS.UniqWh
		AND Warehouse = 'WO-WIP'
		AND LOCATION = 'WO'+@lcWono+SPACE(5)
		AND INVTMFGR.UNIQMFGRHD = @lcUniqMfgrHd
		AND INVTMFGR.INSTORE = @llInstore
		AND INVTMFGR.uniqsupno = @lcUniqSupno
		AND INVTMFGR.IS_DELETED = 1
		
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
			--10/10/14 replaced invtmfhd table
			--SELECT @lcUniq_key = Uniq_key	
			--	FROM INVTMFHD 
			--	WHERE UNIQMFGRHD = @lcUniqMfgrHd
			
			SELECT @lcUniq_key = Uniq_key	
				FROM InvtMPNLink 
				WHERE UNIQMFGRHD = @lcUniqMfgrHd

			SELECT @lcWhNo = Whno, @lcUniqWh =UniqWh
				FROM WAREHOUS	
				WHERE WAREHOUSE = 'WO-WIP'
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
				INSERT INTO INVTMFGR (UniqMfgrHd,W_key,Uniq_key,Netable,Location, InStore, UniqSupNo, UniqWh) 
					VALUES (@lcUniqMfgrHd,@lcNewUniqNbr,@lcUniq_key,1,'WO'+@lcWono,@llInstore,@lcUniqSupno, @lcUniqWh)
			END
			SELECT @lcW_key = @lcNewUniqNbr;
			END
		END
	END
END