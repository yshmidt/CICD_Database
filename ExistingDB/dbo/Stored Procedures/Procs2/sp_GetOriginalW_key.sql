-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/02/11
-- Description:	This procedure will get original w_key that has same uniqmfgrhd, instore, Uniqsupno as the passed in @lcPickW_key
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetOriginalW_key] @lcPickW_key char(10) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @lcReturnW_key char(10), @lcUniq_key char(10), @lcWhNo char(3), @lcUniqWh char(10),
		@lcNewUniqNbr char(10), @lcChkW_key char(10), @lcUniqMfgrHd char(10), @llInstore bit, 
		@lcUniqSupno char(10);

SELECT @lcUniq_key = Uniq_key, @lcUniqMfgrHd = UniqMfgrHd, @llInstore = Instore, @lcUniqSupno = UniqSupno 
	FROM INVTMFGR
	WHERE W_KEY = @lcPickW_key
		
-- if the passed in w_key is WO-WIP location		
SELECT @lcReturnW_key = W_key
	FROM Invtmfgr, WAREHOUS	
	WHERE INVTMFGR.UniqWh = WAREHOUS.UniqWh
	AND Warehouse = 'WO-WIP'
	AND INVTMFGR.W_KEY = @lcPickW_key
	
IF @@ROWCOUNT > 0
	-- The @lcPickW_key is a WO-WIP location record, need to find one which is not WO-WIP
	BEGIN
	-- Try to find all invttrns that ToWkey is the passed in w_key and the FromWkey is not WO-WIP
		SELECT @lcReturnW_key = InvtTrns.FROMWKEY
			FROM Invttrns,Invtmfgr,Warehous
			WHERE Invttrns.FromWKey=Invtmfgr.W_key
			AND INVTMFGR.UNIQWH = WAREHOUS.UniqWh
			AND INVTMFGR.UNIQMFGRHD = @lcUniqMfgrHd
			AND InvtMfgr.InStore=@llInstore
			AND Invtmfgr.UniqSupno=@lcUniqSupno
			AND Invttrns.ToWkey=@lcPickW_key
			AND WAREHOUS.WAREHOUSE <> 'WO-WIP'
			
		IF @@ROWCOUNT > 0
			BEGIN		
			SELECT @lcReturnW_key AS W_key, 1 AS lFromWoWip
			END
		ELSE
			BEGIN
			-- Now will try to find all FromWkey from invttrns where ToWkey is the FromKey of previous SQL
			WITH ZFrom AS
			(	SELECT InvtTrns.FROMWKEY
				FROM Invttrns,Invtmfgr,Warehous
				WHERE Invttrns.FromWKey=Invtmfgr.W_key
				AND INVTMFGR.UNIQWH = WAREHOUS.UniqWh
				AND INVTMFGR.UNIQMFGRHD = @lcUniqMfgrHd
				AND InvtMfgr.InStore=@llInstore
				AND Invtmfgr.UniqSupno=@lcUniqSupno
				AND Invttrns.ToWkey=@lcPickW_key
			)
			
				SELECT @lcReturnW_key = InvtTrns.FROMWKEY
					FROM InvtTrns,Invtmfgr,Warehous,ZFrom F
					WHERE Invttrns.FromWKey=Invtmfgr.W_key 
					AND Warehous.UniqWh=Invtmfgr.UniqWh
					AND INVTMFGR.UNIQMFGRHD = @lcUniqMfgrHd
					AND InvtMfgr.InStore=@llInstore
					AND Invtmfgr.Uniqsupno = @lcUniqSupno
					AND Invttrns.ToWkey=F.FromWkey
					AND WAREHOUS.WAREHOUSE <> 'WO-WIP'
			
			IF @@ROWCOUNT > 0
				BEGIN		
				SELECT @lcReturnW_key AS W_key, 1 AS lFromWoWip
				END
			ELSE
				-- Will create a new Invtmfgr record
				BEGIN
				
					SELECT @lcWhNo = Whno, @lcUniqWh = UniqWh
						FROM WAREHOUS	
						WHERE [DEFAULT] = 1			
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
						INSERT INTO INVTMFGR (UniqMfgrHd,W_key,Uniq_key,Netable,  InStore, UniqSupNo, UniqWh) 
							VALUES (@lcUniqMfgrHd,@lcNewUniqNbr,@lcUniq_key,1,@llInstore,@lcUniqSupno, @lcUniqWh)
					END
					
					SELECT @lcNewUniqNbr AS W_key, 1 AS lFromWoWip					
				
			END
		END				
	END
ELSE
	-- The @lcPickW_key is not a WO-WIP locatin, can just use this W_key
	SELECT @lcPickW_key AS W_key, 0 AS lFromWoWip
	
END



