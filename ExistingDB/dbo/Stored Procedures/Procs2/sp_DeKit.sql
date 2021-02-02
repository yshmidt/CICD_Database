-- =============================================
-- Author:		Vicky Lu
-- Create date: 2011/05/04
-- Description:	Dekit for @gWono
--10/31/14 YS removed fk_ipkeyunique from kalocate
---- Modified: 09/19/17 YS this script is obsolete
-- =============================================
-- 10/12/12 VL added WHERE Wono = @gWono when updating woentry table
CREATE PROCEDURE [dbo].[sp_DeKit] @gWono AS char(10) = ' ', @lcUserID AS char(8)
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
select 'this script is absolete'
----10/31/14 YS removed fk_ipkeyunique from kalocate
--DECLARE @ZKalocate TABLE (nrecno int identity, UniqKalocate char(10), Kaseqnum char(10), W_key char(10), Pick_qty numeric(12,2), 
--						OverIssQty numeric(12,2), OverW_key char(10), LotCode char(15), Expdate smalldatetime, Reference char(12), 
--						Ponum char(15), Uniqmfgrhd char(10), Wono char(10))
						
--DECLARE @ZKalocser TABLE (nrecno int, Serialno char(30), SerialUniq char(10), Is_OverIssued bit)
						
--DECLARE @lnTotalNo int, @lnCount int, @lcUseW_key char(10), @lcUniq_key char(10), @lcU_of_meas char(4),
--		@lcWipGlNbr char(13), @llSerialYes bit, @llInStore bit, @lcNewUniqNbr char(10), @lnStdCost numeric(13,5),
--		@KalocUniqKalocate char(10), @KalocKaseqnum char(10), @KalocW_key char(10), @KalocPick_qty numeric(12,2), @KalocOverIssQty numeric(12,2), 
--		@KalocOverW_key char(10), @KalocLotCode char(15), @KalocExpdate smalldatetime, @KalocReference char(12), @KalocPonum char(15), 
--		@KalocUniqmfgrhd char(10), @lnTableVarCnt int, @lnTotalNo2 int, @lnCount2 int, @KalocserSerialno char(30), 
--		@KalocserSerialUniq char(10), @KalocserIs_OverIssued bit ;

--INSERT @ZKalocate 
--	SELECT UniqKalocate, Kaseqnum, W_key, Pick_qty, OverIssQty, OverW_key, LotCode, Expdate, Reference, Ponum,
--		Uniqmfgrhd, Wono
--		FROM KALOCATE WHERE Wono = @gWono
		
--SET @lnTotalNo = @@ROWCOUNT;		
--SELECT @lcWipGlNbr = dbo.fn_GetWIPGl()

--BEGIN TRANSACTION

--	SET @lnCount=0;
--	WHILE @lnTotalNo>@lnCount
--	BEGIN	
--		SET @lnCount=@lnCount+1;
--		SELECT @KalocUniqKalocate = UniqKalocate, @KalocKaseqnum = Kaseqnum, @KalocOverW_key = OverW_key,
--				@KalocW_key = W_key, @KalocPick_qty = Pick_qty, 
--				@KalocOverIssQty = OverIssQty, @KalocLotCode = LotCode, @KalocExpdate = Expdate, @KalocReference = Reference, 
--				@KalocPonum =Ponum, @KalocUniqmfgrhd = Uniqmfgrhd
--			FROM @ZKalocate WHERE nrecno = @lnCount
--		BEGIN
--		IF (@@ROWCOUNT<>0)
--			BEGIN
--			-- Get all information like instore, w_key, stdcost..... informatio to insert later
--			SELECT @llSerialYes = SerialYes, @lcUniq_key = INVENTOR.Uniq_key, @lcU_of_meas = U_OF_MEAS, @llInStore = Instore, @lnStdCost = StdCost 
--				FROM Inventor, Invtmfgr 
--				WHERE Inventor.UNIQ_KEY = Invtmfgr.UNIQ_KEY
--				AND Invtmfgr.W_KEY = @KalocW_key
				
--			SET @lcUseW_key = @KalocW_key
--			-- If it's a instore location and need to return back to inventory, need to find a not instore location to return
--			IF @llInStore = 1 AND @KalocPick_qty - @KalocOverIssQty > 0
--			BEGIN
--				EXEC dbo.sp_GetNotInstoreLocation4Mfgrhd @KalocUniqmfgrhd, @lcUseW_key OUTPUT
--			END
			
			
--			IF @lcUseW_key = ''
--				BEGIN
--				RAISERROR('Programming error, can not find associated KIT location record. This operation will be cancelled. Please try again',1,1)
--				ROLLBACK TRANSACTION
--				RETURN
--			END
			
--			-- Start to insert, will work differently for serialized or not
--			IF @llSerialYes = 0
--				BEGIN
--				-- Return for issued part
--				-- 07/05/11 VL added next line to make sure QtyIsu <> 0
--				IF @KalocPick_qty-@KalocOverIssQty <> 0
--					BEGIN
--					EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT							
--					INSERT INTO Invt_isu (W_key,Uniq_key,IssuedTo,QtyIsu,U_of_meas,Wono,
--							Gl_nbr,LotCode,Expdate,Reference, Saveinit,Ponum,UniqMfgrHD, Date, Invtisu_no, StdCost, cModid) 
--						VALUES (@lcUseW_key, @lcUniq_key, '(WO:'+ @gWono, -(@KalocPick_qty-@KalocOverIssQty), @lcU_of_meas, @gWono, 
--							@lcWipGlNbr, @KalocLotCode, @KalocExpdate, @KalocReference, @lcUserID, @KalocPonum,	@KalocUniqmfgrhd, 
--							GETDATE(), @lcNewUniqNbr, @lnStdCost, 'K')
--				END	
--				-- Transfer WO-WIP back to regular location
--				IF @KalocOverIssQty<>0
--				BEGIN
--					EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT	
--					INSERT INTO INVTTRNS (Uniq_key,QTYXFER,REASON,FromWkey,ToWkey,LotCode,ExpDate,Reference,Ponum, 
--							UniqMfgrHd, Invtxfer_n, Date, StdCost, cModId, Wono, Kaseqnum) 
--						VALUES (@lcUniq_key,@KalocOverIssQty,'Clear KIT Over Issue', @KalocOverW_key, @KalocW_key, @KalocLotCode, 
--							@KalocExpDate, @KalocReference, @KalocPonum, @KalocUniqMfgrHd, @lcNewUniqNbr, GETDATE(), @lnStdCost, 'K',
--							@gWono, @KalocKaseqnum)					
					
--				END	
						
											
--				END
--			ELSE
--			-- Serialized, will get Kalocser for each Kalocate record
--				BEGIN
				
--				DELETE FROM @ZKalocser WHERE 1=1	-- Delete all old records
--				SET @lnTableVarCnt = 0
--				INSERT @ZKalocser 
--					SELECT 0, Serialno, SerialUniq, Is_OverIssued
--					FROM Kalocser 
--					WHERE UniqKalocate = @KalocUniqKalocate
--				-- to make nrecno re-order from 1
--				UPDATE @ZKalocser SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
				
--				-- now the @lnTableVarCnt should be the record count
--				SET @lnTotalNo2 = @lnTableVarCnt
--				SET @lnCount2=0;
--					WHILE @lnTotalNo2>@lnCount2
--					BEGIN	
--						SET @lnCount2=@lnCount2+1;
--						SELECT @KalocserSerialno = Serialno, @KalocserSerialUniq = SerialUniq, @KalocserIs_OverIssued = Is_OverIssued
--							FROM @ZKalocser WHERE nrecno = @lnCount2
--						BEGIN
--						IF (@@ROWCOUNT<>0)
--							IF @KalocserIs_OverIssued = 1
--								BEGIN
--								EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT	
--								INSERT INTO INVTTRNS (Uniq_key,QTYXFER,REASON,FromWkey,ToWkey,LotCode,ExpDate,Reference,Ponum, 
--										Serialno, SerialUniq, UniqMfgrHd, Invtxfer_n, Date, StdCost, cModId, Wono, Kaseqnum) 
--									VALUES (@lcUniq_key,1,'Clear KIT Over Issue', @KalocOverW_key, @KalocW_key, @KalocLotCode, 
--										@KalocExpDate, @KalocReference, @KalocPonum, @KalocSerSerialno, @KalocserSerialUniq,
--										@KalocUniqMfgrHd, @lcNewUniqNbr, GETDATE(), @lnStdCost, 'K',
--										@gWono, @KalocKaseqnum)					
			
--								END
--							ELSE
--								-- not overissue, just return back to inventory
--								BEGIN
--								EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT		
--								---09/19/17 YS remove serialno and serialuniq					
--								INSERT INTO Invt_isu (W_key,Uniq_key,IssuedTo,QtyIsu,U_of_meas,Wono,
--										Gl_nbr,LotCode,Expdate,Reference, Saveinit,Ponum, Serialno, 
--										SerialUniq, UniqMfgrHD, Date, Invtisu_no, StdCost, cModid) 
--									VALUES (@lcUseW_key, @lcUniq_key, '(WO:'+ @gWono, -1, @lcU_of_meas, @gWono, 
--										@lcWipGlNbr, @KalocLotCode, @KalocExpdate, @KalocReference, @lcUserID, @KalocPonum,	@KalocserSerialno, 
--										@KalocserSerialUniq, @KalocUniqmfgrhd, GETDATE(), @lcNewUniqNbr, @lnStdCost, 'K')
				
--								END

--						-- Code 
--						END
--					END
--				END
	
--			-- End of insert
--			END
--		ELSE
--			BEGIN
--				RAISERROR('Programming error, can not find associated KIT location record. This operation will be cancelled. Please try again',1,1)
--				ROLLBACK TRANSACTION
--				RETURN
--			END
--		END
--	END
--	-- End of return and transfer back to inventory
	
--	-- Delete all records in all Kit tables
--	DELETE FROM KAMAIN WHERE Wono = @gWono
--	DELETE FROM Kalocate WHERE Wono = @gWono
--	DELETE FROM Kadetail WHERE Wono = @gWono
--	DELETE FROM Kalocser WHERE Wono = @gWono
	
--	-- Update Woentry
--	-- 10/12/12 VL added WHERE Wono = @gWono, I am glad we found it
--	UPDATE WOENTRY
--	-- Modified: 09/18/17 YS added JobType to Woentry table to separate Status (OpenClos) from Type
--		--SET KitStatus = CASE WHEN Woentry.OPENCLOS = 'Rework' OR Woentry.OPENCLOS = 'ReworkFirm' THEN 'REWORK' ELSE SPACE(LEN(Woentry.KitStatus)) END,
--		set KitStatus = CASE WHEN Woentry.JobType = 'Rework' OR Woentry.JobType = 'ReworkFirm' THEN 'REWORK' ELSE SPACE(LEN(Woentry.KitStatus)) END,
--			KitCloseDt = NULL, 
--			KITCLOSEINIT = '',
--			Start_date = NULL,
--			KitStartInit = '',
--			KitLstChDT = GETDATE(),
--			KitLstChInit = @lcUserID
--		WHERE WONO = @gWono

--COMMIT
END




