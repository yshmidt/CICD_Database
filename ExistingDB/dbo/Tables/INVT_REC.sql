CREATE TABLE [dbo].[INVT_REC] (
    [W_KEY]           CHAR (10)        CONSTRAINT [DF__INVT_REC__W_KEY__72A6DC10] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]        CHAR (10)        CONSTRAINT [DF__INVT_REC__UNIQ_K__739B0049] DEFAULT ('') NOT NULL,
    [DATE]            SMALLDATETIME    CONSTRAINT [DF_INVT_REC_DATE] DEFAULT (getdate()) NULL,
    [QTYREC]          NUMERIC (12, 2)  CONSTRAINT [DF__INVT_REC__QTYREC__748F2482] DEFAULT ((0)) NOT NULL,
    [COMMREC]         CHAR (50)        CONSTRAINT [DF__INVT_REC__COMMRE__776B912D] DEFAULT ('') NOT NULL,
    [GL_NBR]          CHAR (13)        CONSTRAINT [DF__INVT_REC__GL_NBR__785FB566] DEFAULT ('') NOT NULL,
    [IS_REL_GL]       BIT              CONSTRAINT [DF__INVT_REC__IS_REL__7953D99F] DEFAULT ((0)) NOT NULL,
    [STDCOST]         NUMERIC (13, 5)  CONSTRAINT [DF__INVT_REC__STDCOS__7A47FDD8] DEFAULT ((0)) NOT NULL,
    [GL_NBR_INV]      CHAR (13)        CONSTRAINT [DF__INVT_REC__GL_NBR__7B3C2211] DEFAULT ('') NOT NULL,
    [INVTREC_NO]      CHAR (10)        CONSTRAINT [DF__INVT_REC__INVTRE__7C30464A] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [U_OF_MEAS]       CHAR (4)         CONSTRAINT [DF__INVT_REC__U_OF_M__7E188EBC] DEFAULT ('') NOT NULL,
    [LOTCODE]         NVARCHAR (25)    CONSTRAINT [DF__INVT_REC__LOTCOD__02DD43D9] DEFAULT ('') NOT NULL,
    [EXPDATE]         SMALLDATETIME    NULL,
    [REFERENCE]       CHAR (12)        CONSTRAINT [DF__INVT_REC__REFERE__03D16812] DEFAULT ('') NOT NULL,
    [SAVEINIT]        CHAR (8)         CONSTRAINT [DF__INVT_REC__SAVEIN__04C58C4B] DEFAULT ('') NULL,
    [TRANSREF]        CHAR (30)        CONSTRAINT [DF__INVT_REC__TRANSR__08961D2F] DEFAULT ('') NOT NULL,
    [UNIQ_LOT]        CHAR (10)        CONSTRAINT [DF__INVT_REC__UNIQ_L__098A4168] DEFAULT ('') NOT NULL,
    [UNIQMFGRHD]      CHAR (10)        CONSTRAINT [DF__INVT_REC__UNIQMF__0A7E65A1] DEFAULT ('') NOT NULL,
    [fk_userid]       UNIQUEIDENTIFIER NULL,
    [qtyPerPackage]   NUMERIC (12, 2)  CONSTRAINT [DF_INVT_REC_qtyPerPackage] DEFAULT ((0)) NOT NULL,
    [sourceDev]       CHAR (1)         CONSTRAINT [DF_INVT_REC_sourceDev] DEFAULT ('D') NOT NULL,
    [receiverdetId]   CHAR (10)        CONSTRAINT [DF_INVT_REC_receiverdetId] DEFAULT ('') NOT NULL,
    [inspectedQty]    NUMERIC (12, 2)  CONSTRAINT [DF_INVT_REC_inspectedQty] DEFAULT ((0.0)) NOT NULL,
    [acceptedQty]     NUMERIC (12, 2)  CONSTRAINT [DF_INVT_REC_acceptedQty] DEFAULT ((0.00)) NOT NULL,
    [failedQty]       NUMERIC (12, 2)  CONSTRAINT [DF_INVT_REC_failedQty] DEFAULT ((0.00)) NOT NULL,
    [ret_qty]         NUMERIC (12, 2)  CONSTRAINT [DF_INVT_REC_ret_qty] DEFAULT ((0.00)) NOT NULL,
    [STDCOSTPR]       NUMERIC (13, 5)  CONSTRAINT [DF__INVT_REC__STDCOS__2D16A223] DEFAULT ((0)) NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)        CONSTRAINT [DF__INVT_REC__FUNCFC__19CEC385] DEFAULT ('') NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)        CONSTRAINT [DF__INVT_REC__PRFCUS__1AC2E7BE] DEFAULT ('') NOT NULL,
    [XFER_UNIQ]       CHAR (10)        CONSTRAINT [DF__INVT_REC__XFER_U__72F4ED86] DEFAULT ('') NOT NULL,
    CONSTRAINT [INVT_REC_PK] PRIMARY KEY CLUSTERED ([INVTREC_NO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IS_REL_GL]
    ON [dbo].[INVT_REC]([IS_REL_GL] ASC);


GO
CREATE NONCLUSTERED INDEX [IS_REL_GL_NBR]
    ON [dbo].[INVT_REC]([IS_REL_GL] ASC, [GL_NBR] ASC)
    INCLUDE([W_KEY], [UNIQ_KEY], [DATE], [QTYREC], [STDCOST], [GL_NBR_INV], [INVTREC_NO]);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[INVT_REC]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQMFGRHD]
    ON [dbo].[INVT_REC]([UNIQMFGRHD] ASC);


GO
CREATE NONCLUSTERED INDEX [W_KEY]
    ON [dbo].[INVT_REC]([W_KEY] ASC);


GO
-- =============================================
-- Author:		Yelena/Vicky
-- Create date: 
-- Description:	inserrt trigger for Invt_rec
-- Modified: 
-- 07/16/14 YS added the header to save modification history
-- 07/16/14 YS remove old code for ipkey table, structure changes
-- 07/29/14 YS removed nQpp, IpkeyUnique, cPkgId from the invt_rec table
-- 08/01/14 YS update trigger to check for new sourcedev if 'D' or empty will use old code
-- if 'I' serial numbersa are not saved here. Move the code to ReceiveSerial Trigger
-- 08/04/14 YS add new IPkey
-- 08/19/14 VL Added code to prevent lot-coded part without lot code info or non lot-coded part with lot code info (it created invtlot record)
-- 08/19/14 YS wrong message need to say Uniqmfgrhd is missing not uniq_lot
-- 08/19/14 YS update Invt_rec with uniq_lot value if was not populated
-- 11/07/14 VL Update Invt_rec.Stdcost with Inventor.Stdcost to make sure always get latest correct stdcost
-- 12/04/14 YS If Stdcost updated by this procedure and not provided by "inserted" command, IS_REL_GL will be always= becuase  I.QtyRec*I.StdCost=0.00 will be 0
-- 06/28/16 YS remove code for serial number and ip key. Will use new irecSerial and iRecIpkey tables
-- 06/30/16 Sachin B Comment while condition becaus it put multiple entry to lot
-- 07/28/16 YS if parttype table has no records @lotdetail will keep prior value. Will reset to 0 prio to running 
-- 01/12/17 VL added to update StdCostPR, PRFcused_uniq and FuncFcused_uniq 
-- 03/01/2018 Nilesh Sa Added return after rollback
-- 03/20/2018 Nilesh Sa Modified lot code db & length of lotcode
-- 04/30/2018 Sachin B Add try/catch block and rollback transaction in case of any error
-- =============================================
CREATE TRIGGER [dbo].[Invt_Rec_Insert] ON [dbo].[INVT_REC] 
	AFTER INSERT
AS

BEGIN

-- 04/18/14 VL added ISNULL() to expdate, otherwise it won't find in SQL criteria, if transfer several SN to FGI with lot code and null expdate, empty reference will insert as many as SN count
SET NOCOUNT ON;

BEGIN TRY
BEGIN TRANSACTION
    DECLARE @errorMessage NVARCHAR(4000),@errorSeverity INT,@errorState INT; -- declare variable to catch an error	  

	-- 11/07/14 VL added to update invt_rec.stdcost with inventor.stdcost
	-- 01/12/17 VL added to update StdCostPR, PRFcused_uniq and FuncFcused_uniq 
	UPDATE INVT_REC SET STDCOST = Inventor.STDCOST,
						STDCOSTPR = Inventor.STDCOSTPR,
						PRFcused_uniq = CASE WHEN dbo.fn_IsFCInstalled() = 0 THEN SPACE(10) ELSE dbo.fn_GetPresentationCurrency() END,
						FuncFcused_uniq = CASE WHEN dbo.fn_IsFCInstalled() = 0 THEN SPACE(10) ELSE dbo.fn_GetFunctionalCurrency() END
				FROM inserted I, Inventor WHERE I.Uniq_key=Inventor.UNIQ_KEY AND Invt_rec.INVTREC_NO = I.INVTREC_NO
	--06/29/12 YS update is_rel_gl if QtyRec * Invt_rec.StdCost=0.00
	-- 12/04/14 YS If Stdcost updated by this procedure and not provided by "inserted" command, IS_REL_GL will be always= becuase  I.QtyRec*I.StdCost=0.00 will be 0
	-- change to use invt_rec.stdcost
	UPDATE INVT_REC SET Invt_rec.IS_REL_GL=CASE WHEN I.QtyRec*INVT_REC.StdCost=0.00 THEN 1 ELSE INVT_rec.IS_REL_GL END FROM inserted I where I.INVTREC_NO =Invt_rec.INVTREC_NO 

-- 04/06/12 VL	Added more variables to take the value returned from SQL, found a situation that cycle count issue around 5000 records
--				and it hang.  Found if let the variable took the return value from a SQL solve the issue, also fixed in invt_isu_insert, invtmfgr_upate triggers
--08/01/14 YS added new variable @sourceDev
--08/04/14 YS added @useIPkey and removed @lUseIpKey
-- 08/04/14 YS added @fk_userid and QtyPerPackage, remove @nQpp numeric(12,2),added @qtyRec variable to store QtyRec
-- 08/04/14 YS added @IpKeyCount to save number of ipkey created,@nIpKey - use for while
-- 08/19/14 VL added part_class and part_type
DECLARE @lAcceptQty Numeric(12,2), @lcUniq_lot char(10), @lcw_key char(10), @lclotcode nvarchar(25) , -- 03/20/2018 Nilesh Sa Modified lot code db & length of lotcode
        @ldexpdate smalldatetime,@lcreference char(12), @lcSerialNo char(30), @lcUniqMfgrHd char(15), @lcSerialUniq char(10), @lcSaveInit char(3), 
		@lcUniq_key char(10), @lcIpKeyUnique char(10), @lcPkgId char(10), @lcInvtRec_no char(10), @lSerialYes bit, 
		@lcUniq_lotInvtLot char(10)=space(10), @lcId_key char(10),  @lcNewUniqNbr char(10),@lcGl_nbr_inv char(13),
		@lnTotalCount int, @lnCnt int, @lcTestUniq_key char(10),@sourceDev char(1),@useIpkey char(1),@qtyPerPackage numeric(12,2),
		@qtyRec numeric(12,2),@IpKeyCount Integer, @LotDetail bit, @Part_class char(8), @Part_type char(8);
		
--check if IPKEY required
-- 08/04/14 ys new setup for ipkey. The ipkey traceability is on part by part bases

--SELECT @lUseIpKey = lUseIPKey from InvtSetup

-- check if serial number required
-- 03/03/12 VL found next SQL will not work if multiple records are inserted, will create a temp table to store those variables
--SELECT @lAcceptQty =  Inserted.QtyRec,@lcUniq_key=Inserted.Uniq_key,@lcw_key = Inserted.w_key,
--		@lclotcode = LotCode,@ldexpdate = Expdate, @lcreference = Reference, @lcUniq_lot = Uniq_lot,
--		@lcUniqMfgrhd = UniqMfgrhd,@lSerialYes = Inventor.SerialYes,
--		@lcSaveInit = SaveInit ,@lcInvtRec_no=InvtRec_no, @lcSerialNo = Serialno, @lcSerialUniq = SerialUniq,
--		@lcIpKeyUnique = IpkeyUnique, @lcPkgId = cPkgId, @nQpp = nQpp
--		FROM Inserted,Inventor WHERE Inserted.Uniq_key=Inventor.Uniq_key
-- 07/29/14 YS removed nQpp, IpkeyUnique, cPkgId from the invt_rec table
-- 08/01/14 YS add sourcedev column to check if record inserted from new IPkey development, then sourcedev='I'
-- 08/04/14 YS added UseIpKey, and qtyPerPackage
-- 08/19/14 VL added part_class and part_type
DECLARE @tInserted TABLE (AcceptQty numeric(12,2), Uniq_key char(10), W_key char(10), LotCode nvarchar(25),-- 03/20/2018 Nilesh Sa Modified lot code db & length of lotcode
					Expdate smalldatetime, Reference char(12), 
					Uniq_lot char(10), UniqMfgrHd char(10), SerialYes bit, SaveInit char(8), InvtRec_no char(10), Serialno char(30),
					SerialUniq char(30), nId Int IDENTITY(1,1),sourceDev char(1),useIpkey bit,qtyPerPackage numeric(12,2),qtyRec numeric(12,2),
					Part_class char(8), Part_type char(8))

-- 07/29/14 YS removed nQpp, IpkeyUnique, cPkgId from the invt_rec table. list column names
-- 08/01/14 YS add sourcedev column to check if record inserted from new IPkey development, then sourcedev='I'
-- 08/04/14 YS add useipkey from inventor table
-- 08/04/14 YS added QtyPerPackage, if 0 in the "inserterd" table and useipkey=1  try using ordMult from inventor table
-- 08/19/14 VL added part_class and part_type
-- 06/28/16  YS remove serialno, serialuniq
INSERT @tInserted
	(AcceptQty , Uniq_key,W_key,LotCode , Expdate , Reference ,	Uniq_lot, UniqMfgrHd , SerialYes , SaveInit , InvtRec_no , 
					sourceDev,useIpkey,qtyPerPackage ,QtyRec, Part_class, Part_type)
	SELECT QtyRec AS AcceptQty, Inserted.Uniq_key, W_key, LotCode, Expdate, Reference, Uniq_lot, UniqMfgrHd, SerialYes, SaveInit, InvtRec_no,
		SourceDev,Inventor.useipkey,
		CASE when Inserted.QtyPerPackage<>0 then Inserted.QtyPerPackage
			 WHEN Inserted.QtyPerPackage=0 and Inventor.useipkey=1 and Inventor.ORDMULT <> 0 THEN Inventor.ORDMULT 
			 ELSE 1 END as QtyPerPackage,Inserted.Qtyrec, PART_CLASS, Part_type
		FROM Inserted, INVENTOR
		WHERE Inserted.UNIQ_KEY = Inventor.Uniq_key

SET @lnTotalCount = @@ROWCOUNT;
SET @lnCnt = 0

	
IF @lnTotalCount <> 0		
BEGIN
	WHILE @lnTotalCount> @lnCnt
	BEGIN
		SET @lnCnt = @lnCnt + 1
		-- 07/29/14 YS removed nQpp, IpkeyUnique, cPkgId from the invt_rec table. list column names
		-- 08/01/14 YS added new variable @sourceDev
		--08/01/04 YS added new variable @useIpkey and @qtyPerPackage
		-- 08/19/14 VL added part_class and part_type
		SELECT @lAcceptQty = AcceptQty, @lcUniq_key = Uniq_key, @lcw_key = W_key, @lclotcode = LotCode, @ldExpdate = Expdate, 
				@lcreference = Reference, @lcUniq_lot = Uniq_lot, @lcUniqMfgrhd = UniqMfgrhd, @lSerialYes = SerialYes, 
				@lcSaveInit = SaveInit, @lcInvtRec_no = InvtRec_no, @lcSerialNo = Serialno, @lcSerialUniq = SerialUniq,
				@sourceDev =sourceDev,@useIpkey=useIpKey,@qtyPerPackage=qtyPerPackage,@qtyrec=QtyRec, @Part_class = Part_class, 
				@Part_type = Part_type
				FROM @tInserted WHERE nId = @lnCnt;
				
		-- 08/19/14 VL added code to check if lot-coded part has no lot code, or non lot-coded part has lot code, will rollback
		-- 07/28/16 YS if parttype table has no records @lotdetail will keep prior value. Will reset to 0 prio to running 
		set @LotDetail=0
		SELECT @LotDetail = ISNULL(LOTDETAIL,0) 
		FROM PARTTYPE 
		WHERE PART_CLASS=@part_class
		and PART_TYPE =@part_type 
		-- 08/13/14 YS remove lot detail information is required but not provided create an error and if not required but provide create an error
		IF (@LotDetail = 0 and @lcLotCode is not null and @lcLotCode<>' ')
		BEGIN
			RAISERROR('Lot Code was provided for the part that has no lot code traceability. This operation will be cancelled.',1,1)
			ROLLBACK TRANSACTION
			RETURN	
		END -- if (@llLotDetail = 0 and @lcLotCode is not null and @lcLotCode<>' ')
		IF (@LotDetail = 1 and (@lcLotCode is null or @lcLotCode=' '))
		BEGIN
			RAISERROR('Lot Code is required and was not provided. This operation will be cancelled.',1,1)
			ROLLBACK TRANSACTION
			RETURN	
		END -- if (@llLotDetail = 1 and (@lcLotCode is null or @lcLotCode=' ')) 
		-- 08/13/14 YS}
		-- 08/19/14 VL End}
		
		-- check if uniq_key are OK
		-- 03/03/12 VL changed to compare only one record from tInserted
		--IF (SELECT Uniq_key FROM @zIntMfgr)=(SELECT Uniq_key FROM Inserted)
		-- 04/06/12 VL changed
		--IF (SELECT Uniq_key FROM INVTMFGR WHERE W_KEY = @lcW_key) = @lcUniq_key
		SELECT @lcTestUniq_key = Uniq_key FROM INVTMFGR WHERE W_KEY = @lcW_key
		IF @lcTestUniq_key = @lcUniq_key
			BEGIN	
			
				/* No Uniqmfgrhd is inserted*/
				IF @lcUniqMfgrhd = ' '
					BEGIN
					--set @lRollBack=1
					--08/19/14 YS wrong message need to say Uniqmfgrhd is missing not uniq_lot
					RAISERROR('Programming error, the uniqmfgrhd has to be populated. This operation will be cancelled. Please try again',1,1)
					ROLLBACK TRANSACTION
				END --@lcUniqMfgrhd = ' '
				-- 03/03/12 VL changed to update one record here				
				--UPDATE InvtMfgr SET Qty_oh=Qty_oh+@lAcceptQty WHERE w_key IN (SELECT W_key FROM Inserted)
				UPDATE InvtMfgr SET Qty_oh=Qty_oh+@lAcceptQty WHERE w_key = @lcw_key
				
				-- 03/03/12 VL changed to update one record here	
				-- 07/06/10 YS added function get gl_nbr_inv
				--UPDATE Invt_rec SET Gl_nbr_inv=dbo.fn_GETINVGLNBR(@lcw_key,'R',0) WHERE Invt_rec.InvtRec_no IN (SELECT InvtRec_no FROm Inserted)
				UPDATE Invt_rec SET Gl_nbr_inv=dbo.fn_GETINVGLNBR(@lcw_key,'R',0) WHERE Invt_rec.InvtRec_no = @lcInvtRec_no
				
				/*----------------------*/
				/* code for the lot code*/
				/*----------------------*/
				
				IF (@lcLotCode <> SPACE(25)) -- 03/20/2018 Nilesh Sa Modified lot code db & length of lotcode
					-- check for the existing LotCode first
				BEGIN
					-- need to check if it will work when uniq_lot is empty
					IF (@lcUniq_lot<>SPACE(15))
						BEGIN
							SELECT @lcUniq_lotInvtLot = Uniq_lot
								FROM Invtlot
								WHERE Uniq_lot = @lcUniq_lot
								
							IF (@@ROWCOUNT=0)	
								BEGIN
									INSERT INTO InvtLot (W_key,LotCode,ExpDate,LotQty,Reference,Uniq_lot) VALUES 
									(@lcW_Key,@lcLotCode,@ldExpDate,@lAcceptQty,@lcReference,@lcUniq_lot);
								END
							ELSE -- @@ROWCOUNT=0)
								BEGIN
									--just update lot qty
									UPDATE InvtLot SET LotQty=LotQty+@lAcceptQty WHERE Uniq_lot	= @lcUniq_lot ;	
									
								END	
							SET @lcUniq_lotInvtLot = @lcUniq_lot
						END -- end block iside IF (@lcUniq_lot<>space(15))
					ELSE 
						/* Check all lot field rather than only Uniq_lot field*/
						BEGIN
							-- 03/03/12 VL changed to use one record from @tInserted
							-- 07/08/10 YS change SQL to use exists
							--SELECT @lcUniq_lotInvtLot = Uniq_lot FROM InvtLot 
							--	WHERE InvtLot.Ponum=space(15) and EXISTS 
							--	(SELECT 1 FROM Inserted WHERE Inserted.W_key=InvtLot.W_key and Inserted.LotCode=InvtLot.LotCode 
							--		AND Inserted.ExpDate=InvtLot.ExpDate and Inserted.Reference=InvtLot.Reference)
							-- 04/18/14 VL added ISNULL() to expdate, otherwise it won't find
							SELECT @lcUniq_lotInvtLot = Uniq_lot FROM InvtLot 
								WHERE Ponum = SPACE(15) 
								AND	W_key = @lcW_key
								AND LOTCODE = @lcLotcode
								--AND ExpDate = @ldexpdate
								AND ISNULL(ExpDate,1) = ISNULL(@ldExpDate,1)
								AND REFERENCE = @lcReference
																
							IF (@@ROWCOUNT=0)	
								BEGIN
									WHILE (1=1)
									BEGIN
										EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
										SELECT @lcUniq_lotInvtLot = Uniq_lot FROM InvtLot WHERE Uniq_lot = @lcNewUniqNbr
										IF (@@ROWCOUNT<>0)
											CONTINUE
										ELSE
											BREAK
									END 
									--06/30/16 Sachin B Comment while condition becaus it put multiple entry to lot
									--WHILE (1=1)			
									INSERT INTO InvtLot (W_key,LotCode,ExpDate,LotQty,Reference,Uniq_lot) VALUES 
									(@lcW_Key,@lcLotCode,@ldExpDate,@lAcceptQty,@lcReference,@lcNewUniqNbr);
									SET @lcUniq_lotInvtLot = @lcNewUniqNbr
									--08/19/14 YS update Invt_rec with uniq_lot value
									update invt_rec set uniq_lot=@lcUniq_lotInvtLot where invt_rec.INVTREC_NO = @lcInvtRec_no
								END ---(@@ROWCOUNT=0)
							ELSE -- @@ROWCOUNT=0)
								BEGIN
									--just update lot qty
									UPDATE InvtLot SET LotQty=LotQty+@lAcceptQty WHERE Uniq_lot	= @lcUniq_lotInvtLot ;	
									--08/19/14 YS update Invt_rec with uniq_lot value
									update invt_rec set uniq_lot=@lcUniq_lotInvtLot where invt_rec.INVTREC_NO = @lcInvtRec_no
							END	-- @@ROWCOUNT=0)
										
						END	-- (@lcUniq_lot<>space(15))						
				END -- end for IF (@lcLotCode <>SPACE(15)), no ELSE
				
				--- 06/28/16 YS the serial number code moved to the "child" irecSerial table
				/*----------------------*/
				/* code for the serialno*/
				/*----------------------*/
				-- 08/01/14 YS check if sourceDev='I' and skip this code, new development will save serial 
				-----numbers in ReceiveSerial Table and will use insert trigger in that table to update Invtser table 
				--IF (@lSerialYes=1 and @sourceDev<>'I')
				--BEGIN -- block inside if (@lSerialYes=1)
				--	--check if any of the received serial numbers are already in the InvtSer table and id_key='W_KEY' or 'WONO'
				--	-- 07/08/10 no need to assign @lcSerialUniqInvtSer. We do not use it 
				--	SELECT @lcId_key = Id_key
				--		FROM InvtSer
				--		WHERE InvtSer.SerialUniq = @lcSerialUniq
					
				--	IF (@@ROWCOUNT<>0)
				--	BEGIN
				--		IF @lcId_key = 'W_KEY' OR @lcId_key = 'WONO'
				--			BEGIN
				--			-- cannot receive
				--			--set @lRollBack=1;
				--			RAISERROR('Some of the Serial Numbers you are trying to receive is already in the system. Please check your inventory.',1,1);
				--			ROLLBACK TRANSACTION
				--			END	--@lcId_key = 'W_KEY' OR @lcId_key = 'WONO'			
				--		ELSE -- @lcId_key = 'W_KEY' OR @lcId_key = 'WONO'
				--			BEGIN
				--			-- check if exists but was shipped and now returned back
				--			UPDATE InvtSer SET Id_key='W_KEY', 
				--								Id_value=@lcW_key,
				--								UniqMfgrhd = @lcUniqMfgrhd,
				--								LotCode = @lcLotCode,
				--								Uniq_Lot = @lcUniq_lotInvtLot,
				--								ExpDate = @ldExpDate,
				--								Reference = @lcReference,
				--								Ponum = SPACE(15),
				--								ActvKey = SPACE(10)
				--				WHERE SerialUniq = @lcSerialUniq
				--			END -- else if @lcId_key = 'W_KEY' OR @lcId_key = 'WONO'
				--	END --  (@@ROWCOUNT<>0)
				--	ELSE --  (@@ROWCOUNT<>0)
				--	BEGIN
				--		--insert records into InvtSer for those that are not in the table yet
				--		INSERT INTO InvtSer (SerialUniq,SerialNo,Uniq_key,UniqMfgrHd,Uniq_lot,Id_key,Id_value,
				--			SaveInit,SaveDtTm,LotCode,ExpDate,Reference) 
				--		VALUES (@lcSerialUniq, @lcSerialNo, @lcUniq_key, @lcUniqMfgrHd,@lcUniq_lotInvtLot,'W_KEY',@lcW_key,
				--			@lcSaveInit,GETDATE(),@lcLotCode,@ldExpDate,@lcReference);
				--	END -- esle if (@@ROWCOUNT<>0)
				--	--07/16/14 YS remove the old code , structure changes, will have to update soon			
				--	--IF @lUseIpKey = 1
				--	--	-- IPKEY and Serial Number
				--	--	-- use iRecIpKey to insert information into IpKey
				--	--	INSERT INTO IpKey (ipkeyunique,uniq_key,uniqmfgrhd,serialuniq,cpkgid,norigpkgqty,npkgbalance,ccrtinit,LotCode,
				--	--			Reference,ExpDate,UniqRecDtl,W_Key,cTransType)
				--	--		VALUES (@lcIpKeyUnique,	@lcuniq_key,@lcuniqmfgrhd,@lcSerialuniq,@lcPkgId,@nQpp,@nQpp,@lcSaveInit,@lcLotCode,
				--	--			@lcReference,@ldExpDate,@lcInvtRec_no,@lcw_key,'R');
				--END	-- block inside if (@lSerialYes=1 and @sourceDev<>'I')
				--08/01/14 YS}
				--- 06/28/16 YS the ipkey (SID) moved to the "child" irecipkey table
				--08/04/14 YS New code for ipkey
				-- if @useIpkey=1 insert record in iRecIpkey. iRecIpkey should have a trigger to insert a new record into IpKey table
			--	IF (@useIpkey=1 and @lSerialYes=0 and @sourceDev='I')		--- part is not serialized and new ipkey. 
			--	BEGIN
			--		--If part is serialized ReceiveSerial table has to be created with ipkey attached and insert for this table will generate new [iRecIpKey]
			--		SET @IpKeyCount =CEILING(@QtyRec/@qtyPerPackage)

			--		;WITH MyIpkey as 
			--		(select 1 as myCounter
			--			UNION ALL
			--		select myCounter+1 as myCounter
			--		FROM MyIpkey where myCounter<@IpKeyCount)
			--		INSERT INTO  [dbo].[iRecIpKey]
			--				([iRecIpKeyUnique]
			--				,[invtrec_no]
			--				,[qtyPerPackage]
			--				,[qtyReceived]
			--				,[ipkeyunique]) 
			--		SELECT dbo.fn_GenerateUniqueNumber() as [iRecIpKeyUnique],
			--		@lcInvtRec_no as [invtrec_no],
			--		CASE WHEN myCounter=@IpKeyCount and @qtyrec%@qtyPerPackage <>0 THEN @qtyrec%@qtyPerPackage ELSE @qtyPerPackage end as [qtyPerPackage],
			--		case when myCounter=@IpKeyCount and @qtyrec%@qtyPerPackage <>0 THEN @qtyrec%@qtyPerPackage else  @qtyPerPackage end as [qtyReceived],
			--		dbo.fn_GenerateUniqueNumber() as [ipkeyunique]
			--		FROM myIpkey

					
			--	END --- IF (@useIpkey=1 and @lSerialYes=0 and @sourceDev='I')			
			--	--08/04/14 YS New code for ipkey}
				
			--	--07/16/14 YS remove the old code , structure changes, will have to update soon	
			--	--ELSE -- (@lSerialYes=1)
					
			--		--IF @lUseIpKey = 1
			--		--BEGIN 
			--		--	--IPKEY no Serial number



			--		--	INSERT INTO IpKey (ipkeyunique,uniq_key,uniqmfgrhd,cpkgid,norigpkgqty,npkgbalance,ccrtinit,LotCode,
			--		--			Reference,ExpDate,UniqRecDtl,W_Key,cTransType) 
			--		--		VALUES (@lcIpKeyUnique, @lcuniq_key,@lcuniqmfgrhd,@lcPkgId,@nQpp,@nQpp,@lcSaveInit,@lcLotCode,
			--		--			@lcReference,@ldExpDate,@lcInvtRec_no,@lcw_key,'R');
			--	--END 

			--END		-- the block (select Uniq_key from @zIntMfgr)=(SELECT Uniq_key from Inserted)
		END ---IF @lcTestUniq_key = @lcUniq_key	
		ELSE	-- IF @lcTestUniq_key = @lcUniq_key

			BEGIN
				--set @lRollBack=1		
				RAISERROR('Please record all the steps you have done and have your system administrator call MANEX with the following message; The link to the Inventor table is not related to the link in the InvtMfgr table. This operation will be cancelled. Please try again',1,1)
				ROLLBACK TRANSACTION
				RETURN -- 03/01/2018 Nilesh Sa Added return after rollback
		END -- else -- @lcTestUniq_key = @lcUniq_key
		

	END	-- WHILE @lnTotalCount> @lnCnt

END -- END OF IF @lnTotalCount<>0		

COMMIT TRANSACTION                            
END TRY      
      
BEGIN CATCH                          
	IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION;      
	    SELECT @errorMessage = ERROR_MESSAGE(),
        @errorSeverity = ERROR_SEVERITY(),
        @errorState = ERROR_STATE();
		RAISERROR 
		(	@ErrorMessage, -- Message text.
			 @ErrorSeverity, -- Severity.
			 @ErrorState -- State.
        );
                    
END CATCH    
END
