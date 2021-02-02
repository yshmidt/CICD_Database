CREATE TABLE [dbo].[INVTTRNS] (
    [UNIQ_KEY]         CHAR (10)        CONSTRAINT [DF__INVTTRNS__UNIQ_K__247341CE] DEFAULT ('') NOT NULL,
    [DATE]             SMALLDATETIME    NULL,
    [QTYXFER]          NUMERIC (12, 2)  CONSTRAINT [DF__INVTTRNS__QTYXFE__25676607] DEFAULT ((0)) NOT NULL,
    [FROMWKEY]         CHAR (10)        CONSTRAINT [DF__INVTTRNS__FROMWK__274FAE79] DEFAULT ('') NOT NULL,
    [TOWKEY]           CHAR (10)        CONSTRAINT [DF__INVTTRNS__TOWKEY__2843D2B2] DEFAULT ('') NOT NULL,
    [GL_NBR]           CHAR (13)        CONSTRAINT [DF__INVTTRNS__GL_NBR__2937F6EB] DEFAULT ('') NOT NULL,
    [REASON]           CHAR (25)        CONSTRAINT [DF__INVTTRNS__REASON__2A2C1B24] DEFAULT ('') NOT NULL,
    [GL_NBR_INV]       CHAR (13)        CONSTRAINT [DF__INVTTRNS__GL_NBR__2B203F5D] DEFAULT ('') NOT NULL,
    [STDCOST]          NUMERIC (13, 5)  CONSTRAINT [DF__INVTTRNS__STDCOS__2C146396] DEFAULT ((0)) NOT NULL,
    [IS_REL_GL]        BIT              CONSTRAINT [DF__INVTTRNS__IS_REL__2D0887CF] DEFAULT ((0)) NOT NULL,
    [INVTXFER_N]       CHAR (10)        CONSTRAINT [DF__INVTTRNS__INVTXF__2DFCAC08] DEFAULT ('') NOT NULL,
    [U_OF_MEAS]        CHAR (4)         CONSTRAINT [DF__INVTTRNS__U_OF_M__2EF0D041] DEFAULT ('') NOT NULL,
    [LOTCODE]          NVARCHAR (25)    CONSTRAINT [DF__INVTTRNS__LOTCOD__2FE4F47A] DEFAULT ('') NOT NULL,
    [EXPDATE]          SMALLDATETIME    NULL,
    [REFERENCE]        CHAR (12)        CONSTRAINT [DF__INVTTRNS__REFERE__30D918B3] DEFAULT ('') NOT NULL,
    [SAVEINIT]         CHAR (8)         CONSTRAINT [DF__INVTTRNS__SAVEIN__31CD3CEC] DEFAULT ('') NULL,
    [PONUM]            CHAR (15)        CONSTRAINT [DF__INVTTRNS__PONUM__359DCDD0] DEFAULT ('') NOT NULL,
    [TRANSREF]         CHAR (30)        CONSTRAINT [DF__INVTTRNS__TRANSR__387A3A7B] DEFAULT ('') NOT NULL,
    [UNIQMFGRHD]       CHAR (10)        CONSTRAINT [DF__INVTTRNS__UNIQMF__396E5EB4] DEFAULT ('') NOT NULL,
    [UNIQ_LOT]         CHAR (10)        CONSTRAINT [DF_INVTTRNS_UNIQ_LOT] DEFAULT ('') NOT NULL,
    [LSKIPUNALLOCCODE] BIT              CONSTRAINT [DF_INVTTRNS_LSKIPUNALLOCCODE] DEFAULT ((0)) NOT NULL,
    [cModId]           CHAR (1)         CONSTRAINT [DF_INVTTRNS_cModId] DEFAULT ('') NOT NULL,
    [Wono]             CHAR (10)        CONSTRAINT [DF_INVTTRNS_Wono] DEFAULT ('') NOT NULL,
    [Kaseqnum]         CHAR (10)        CONSTRAINT [DF_INVTTRNS_Kaseqnum] DEFAULT ('') NOT NULL,
    [fk_userid]        UNIQUEIDENTIFIER NULL,
    [sourceDev]        CHAR (1)         CONSTRAINT [DF_INVTTRNS_sourceDev] DEFAULT ('D') NOT NULL,
    [STDCOSTPR]        NUMERIC (13, 5)  CONSTRAINT [DF__INVTTRNS__STDCOS__2EFEEA95] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]    CHAR (10)        CONSTRAINT [DF__INVTTRNS__PRFCUS__28DBFCEB] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ]  CHAR (10)        CONSTRAINT [DF__INVTTRNS__FUNCFC__29D02124] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_INVTTRNS] PRIMARY KEY CLUSTERED ([INVTXFER_N] ASC)
);


GO
CREATE NONCLUSTERED INDEX [FROMWKEY]
    ON [dbo].[INVTTRNS]([FROMWKEY] ASC);


GO
CREATE NONCLUSTERED INDEX [INVTXFER_N]
    ON [dbo].[INVTTRNS]([INVTXFER_N] ASC);


GO
CREATE NONCLUSTERED INDEX [IS_REL_GL]
    ON [dbo].[INVTTRNS]([IS_REL_GL] ASC);


GO
CREATE NONCLUSTERED INDEX [IS_REL_GL_NBR]
    ON [dbo].[INVTTRNS]([IS_REL_GL] ASC, [GL_NBR] ASC)
    INCLUDE([UNIQ_KEY], [DATE], [QTYXFER], [FROMWKEY], [TOWKEY], [GL_NBR_INV], [STDCOST], [INVTXFER_N]);


GO
CREATE NONCLUSTERED INDEX [TOWKEY]
    ON [dbo].[INVTTRNS]([TOWKEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[INVTTRNS]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQMFGRHD]
    ON [dbo].[INVTTRNS]([UNIQMFGRHD] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/12/2010
-- Description:	Inventory Transfer Insert Trigger
-- Modified : 
-- 02/14/12 VL changed to use @lcFromWKey in IF @lnQty_oh-@lnReserved<@lnQtyThisTime AND @lToWO_WIP=1 --- Avail qty less than transfer check if reserved for the WO	case
-- 02/15/12 VL Insert Invt_res for WO-WIP, from @ZWo_WipAlloc
-- 04/10/12 VL Added @lIsFromSo into @ZWo_WIPAlloc, so it won't say 'Column name or number of supplied values does not match table definition' when insert into invt_res
-- 04/26/12 VL fixed one line that should check reserved qty, not transfer 
-- 04/30/12 VL Found Invtmfgr.Reserved is not updated correctly
-- 11/30/12 VL Tried to prevent getting MANEX hang sitution that too many records saved in one time
-- 05/08/13 YS added lcFromuniq_key and lcToUniq_key to test if the parts fromwkey and towkey matching (problem found in Smart data after converting to sql
-- 08/27/13 VL found the CONTINUE might cause endless loop, need to add one more criteria in WHILE to make it out of the loop if all records are checked
-- 08/28/13 VL Changed @@ROWCOUT TO @lnTableVarCnt in several places because @@ROWCOUNT might not be right when used in IF...
-- 12/12/13 VL added one more criteria to prevent endless loop in several places
-- 02/07/14 YS if reference and ponum was empty when inserting  even if the lot code is entered we are loosing the information for the lot code
--- changed to check for null values
-- 02/12/14 VL Use @zKamain.Wono, not @lcWono when inserting Kadetail
-- 06/18/14 VL Found the cModid need to be changed
-- 08/07/14 YS Added sourceDev column to keep the old desktop modules working while working on the new (with IPKEY) development
-- 08/28/14 VL Found when checking if any reserved record is created for WO and PJ, it not always return NULL for no allocation record, sometimes it return 0
-- 09/11/14 YS added code to check if from location is not in-store, but to location is. Should not allow to proceed
-- 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- 03/09/15 YS added @mfgrmasterid variable
-- 04/14/15 YS Location length is changed to varchar(256)
-- 02/08/2017  Satish B : Serialno and lIsFromSo columns are not exist in INVT_RES table as per the new database structute
-- 02/08/2017  Satish B : Kalocate and KalocSer tables are not exist in new database structute
-- 02/09/2017  Satish B : Remove cloumns :Serialno,SerialUniq,lIsFromSO and Add Columns :KaSeqnum,fk_userid,FUNCFCUSED_UNIQ,PRFCUSED_UNIQ as per new database structure
-- 02/09/2017  Satish B : Remove cloumns :Serialno,SerialUniq,lIsFromSO as per new database structure
-- 04/05/2017  Satish B : We Insert Serial Numbers in iTransferSerial table (We are not inserting SerialUniq in INVTTRNS table)
-- 04/05/17		VL added to update StdCostPR, PRFcused_uniq and FuncFcused_uniq 
-- 09/01/2017 Satish B : Modify the IF condition for the scenario [ IF @lnQty_oh and @lnQtyThisTime=1 ]
							-- Because when the transfer quantity is 1, in this case Invtmfgr.qty_oh= Invtmfgr.qty_oh - @lnQtyThisTime and set @lnQty_oh = Invtmfgr.qty_oh as Invtmfgr updated above
							-- SO in this case @lnQty_oh is 0 and @lnQtyThisTime=1 then also it rais the error
-- 09/02/2017 Satish B : Revert back changes made on 09/01/2017
-- 09/19/2017 Satish B : Comment the validation of @lnQty_oh<@lnQtyThisTime as it raise error when @lnQty_oh =1 and @lnQtyThisTime=1(Beacause it first update the INVTMFGR and 
		--set @lnQty_oh =INVTMFGR.Qty_Oh - qty transfer and set to 0)
-- 10/09/2017 Sachin B :remove Serialno and SerialUniq from INVTTRNS table and update insert trigger
--03/02/18 YS changed lotcode size to 25
-- 05/07/19 Shrikant changed --@lcSerialno, @lcSerialUniq to blank value to fixed the issue of while saving packing list consg xfer chnage throws error Cannot insert the value NULL into column 'serialno', table 'Broadcom_3165.dbo.POSTORE
--05/16/17 YS populate u_of_meas at the time of the transaction
--08/07/2019 Rajendra K : Changed location datatype varchar to nvarchar
--02/24/2020 Nitesh B Modify trigger for sfbl warehouse 
-- =============================================
CREATE TRIGGER [dbo].[InvtTrns_Insert]
   ON [dbo].[INVTTRNS]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	
	

	-- 04/05/17 VL added to update stdcost and functional currency fields
	--05/16/17 YS populate u_of_meas at the time of the transaction
	UPDATE Invttrns SET STDCOST = Inventor.STDCOST,
					STDCOSTPR = Inventor.STDCOSTPR,
					PRFcused_uniq = CASE WHEN dbo.fn_IsFCInstalled() = 0 THEN SPACE(10) ELSE dbo.fn_GetPresentationCurrency() END,
					FuncFcused_uniq = CASE WHEN dbo.fn_IsFCInstalled() = 0 THEN SPACE(10) ELSE dbo.fn_GetFunctionalCurrency() END,
					U_OF_MEAS= INVENTOR.U_OF_MEAS		 
			FROM inserted I, Inventor WHERE I.Uniq_key=Inventor.UNIQ_KEY AND I.INVTXFER_N =Invttrns.INVTXFER_N  
	
	--06/29/12 YS update is_rel_gl if QtyRec * Invt_rec.StdCost=0.00
	UPDATE INVTTRNS  SET Invttrns.IS_REL_GL=CASE WHEN I.Qtyxfer*I.StdCost=0.00 THEN 1 ELSE INVTTRNS.IS_REL_GL END 
	FROM inserted I where I.INVTXFER_N =Invttrns.INVTXFER_N  

    -- Insert statements for trigger here
    DECLARE @UseIPKEY as bit=0,@lIsInStore bit = 0,@lSerialYes bit=0,@lnCount as int=0, @lnQtyAlloc as Numeric(12,2)=0.00, @lcInvtRes_no As char(10)=' ', @lnUnreserved as numeric(12,2)=0.00;
  --05/08/13 YS added lcFromuniq_key and lcToUniq_key to test if the parts fromwkey and towkey matching (problem found in Smart data after converting to sql
    --03/02/18 YS changed lotcode size to 25
	DECLARE @lcPart_sourc as char(10)=' ',@lnDelta as numeric(12,2)=0.00,@lcSaveInit char(8)=' ', @lnQtyThisTime as numeric(12,2)=0.00,@lcFk_PrjUnique as char(10)=' ',@lcModId char(1),
			@lcWono as char(10), @lcFromWKey as char(10),@lcToWKey as char(10),@lSkipUnallocCode as bit,@lcUniqMfgrhd char(10)=' ',@lcUniq_key char(10)=' ',@lcSerialUniq char(10)=' ',
			@lcKaseqnum AS char(10), @lcLotCode nvarchar(25),@lcFromuniq_key char(10),@lcToUniq_key char(10),@lcFrom_ipkey char(10);
    -- 04/14/15 YS Location length is changed to varchar(256)
 --08/07/2019 Rajendra K : Changed location datatype varchar to nvarchar
 DECLARE @lFromWO_WIP as bit,@lToWO_WIP as bit,@lFromInstore as bit, @lToInstore as bit,@lcFromLocation nvarchar(256),@lcToLocation nvarchar(256),@lReservedPrj as bit,@lReservedWo as bit;  
    DECLARE @lnQty_oh as numeric(12,2)=0.00,@lnReserved as numeric(12,2)=0.00,@lnReduceThisTime as numeric(12,2)=0.00,@lnQtyResWo numeric(12,2)=0.00,@lnQtyResPrj numeric(12,2)=0.00;
    --08/07/14 YS added sourceDev
	DECLARE @lnLotQty numeric(12,2)=0.00,@lnLotResQty numeric(12,2)=0.00,  @lcNewUniqNbr char(10)=' ',@lcToUniqLot char(10)=' ',
			@lcMatlType char(10), @lnChkQtyalloc numeric(12,2)=0.00, @ltExpdate smalldatetime,
			@lcReference char(12), @lcPonum char(15), @lcChkUniqKalocate char(10), @lcSerialno char(30), @lcInvtxfer_n char(10), 
			@lnTotalCount int, @lnCnt int, @lnTableVarCnt int, @lnDeltaOver Numeric(12,2)=0.00,@lnOverLeft Numeric(12,2)=0.00, @lnLocCount int=0,
			@llLotDetail bit, @lcPart_class char(8), @lcPart_type char(8), @lnFromWkeyQty_oh numeric(12,2), @lnFromWKeyReserved numeric(12,2),
			@lcFromWkeyUniqWh char(10), @lcFromWkeyUniqMfgrhd char(10), @lcPartmfgr char(8), @lcMfgr_pt_no char(30), @lcFromWkeyUniqSupno char(10),
			--03/09/15 YS added @mfgrmasterid variable
			@lIsFromSO bit, @lnTotalCnt bit, @lnTableVarcnt2 int,@sourceDev char(1),@mfgrMasterid bigint
    --10/14/13 YS added variable to store in-store gl
    declare @lcInStoreGlNbr char(13)=' '
    SELECT @lcInStoreGlNbr=ISNULL(Inst_Gl_No,SPACE(13)) from InvSetup
	-- 02/03/12 VL create a cursor to store what has to be insert into Invt_res for WO-WIP allocation, found the table ;
	-- Invtmfgr has not been udpated yet, has to update after the Invttnrs update is done(invtmfgr is updated)
	-- 04/15/12 VL added lIsFromSO

	-- 02/09/2017  Satish B : Remove cloumns :Serialno,SerialUniq,lIsFromSO and Add Columns :KaSeqnum,fk_userid,FUNCFCUSED_UNIQ,PRFCUSED_UNIQ as per new database structure
	--03/02/18 YS changed lotcode size to 25
	DECLARE @ZWO_WIPAlloc TABLE (W_key char(10), Uniq_key char(10), DateTime smalldatetime, QtyAlloc numeric(12,2), Wono char(10), Invtres_no char(10), Sono char(10), Uniqueln char(10), 
			LotCode nvarchar(25), Expdate smalldatetime, Reference char(12), PoNum char(15), SaveInit char(8), RefinvtRes char(10), Fk_PrjUnique char(10),KaSeqnum char(10)
			,fk_userid uniqueidentifier,FUNCFCUSED_UNIQ char(10),PRFCUSED_UNIQ char(10)	 
			--Serialno char(30) 
			--SerialUniq char(10),
			--lIsFromSO bit
			) 
	-- 02/03/12 VL End}

	-- 11/30/12 VL added a table to save all records from Inserted, it might have more than one record
	-- 12/03/12 VL added PrjUnique to save woentry.PrjUnique for later checking reserved qty
	-- 08/07/14 YS added useipkey column and sourceDev
	-- 10/09/2017 Sachin B :remove Serialno and SerialUniq from INVTTRNS table and update insert trigger
    DECLARE @tInserted TABLE (QtyXfer numeric(12,2), SaveInit char(8), cModid char(1), FromWKey char(10), ToWkey char(10), Wono char(10),
							UniqMfgrhd char(10), Uniq_key char(10), --SerialUniq char(10),
							 lSkipUnallocCode bit, Kaseqnum char(10),
							 --03/02/18 YS changed lotcode size to 25
							LotCode nvarchar(25), Expdate smalldatetime, Reference char(12), Ponum char(15), --Serialno char(30),
							 Invtxfer_n char(10),
							PrjUnique char(10),	nId Int IDENTITY(1,1),useIpkey bit,sourcedev char(1))

	-- 11/30/12 VL moved the code from bottom to here
	--03/02/18 YS changed lotcode size to 25
	DECLARE @tInvtAlloc TABLE (nrecno int, Invtres_no char(10),w_key char(10),wono char(10),LotCode nvarchar(25),ExpDate smalldatetime,Reference char(12),
								PoNum char(15),qtyalloc numeric(12,2),fk_prjunique char(10),UniqueLn char(10)
   -- 02/08/2017  Satish B : Serialno and lIsFromSo columns are not exist in INVT_RES table as per the new database structute
								--,Serialno char(30)
								--,lIsFromSo bit 
								) ;

	-- 11/30/12 VL move the code from bottom to here
	-- 02/12/14 VL found need to save wono that will be used when inserting Kadetail
	--03/02/18 YS changed lotcode size to 25
	DECLARE @zKamain Table (nRecno Int,KaSeqNum char(10),Act_qty numeric(12,2),ShortQty Numeric(12,2), Wono char(10))
	DECLARE @zKaLocate TABLE (nRecno Int,KaSeqNum char(10), OverW_key char(10),LotCode nvarchar(25),
			ExpDate SmallDatetime,Reference char(12),Ponum char(15),OverIssQty Numeric(12,2),UniqKalocate char(10))
	
    --08/07/14 Ys useIpkey stored in the inventor table on the part per part base
	--SELECT @lUseIPKEY=lUseIPKey FROM InvtSetup ;
    -- when issued from in-store location the records in the POSTORE table has to be entered
	SELECT @lIsInStore = Installed FROM Items WHERE ScreenName='INSTORE';

	--11/30/12 VL 
	--02/07/14 YS if reference and ponum was empty when inserting  even if the lot code is entered we are loosing the information for the lot code
	--- changed to check for null values
	-- 08/07/14 YS added new column, list all columns in the insert part
	-- 10/09/2017 Sachin B :remove Serialno and SerialUniq from INVTTRNS table and update insert trigger
	INSERT @tInserted
			(QtyXfer, SaveInit, cModid, FromWKey, ToWkey, Wono, UniqMfgrhd, Uniq_key, --SerialUniq,
			 lSkipUnallocCode, Kaseqnum,LotCode, Expdate, Reference, Ponum,
			   --Serialno,
			    Invtxfer_n, PrjUnique,useIpKey,sourcedev)
			SELECT QtyXfer, SaveInit, cModid, FromWKey, ToWkey, I.Wono, UniqMfgrhd, I.Uniq_key,-- SerialUniq,
			 lSkipUnallocCode, Kaseqnum,
					LotCode, Expdate, isnull(Reference,space(12)), isnull(Ponum,SPACE(15)), -- Serialno,
					 Invtxfer_n, W.PrjUnique,p.useipkey,
					i.sourceDev
				FROM Inserted I INNER JOIN Inventor P on I.UNIQ_KEY = P.UNIQ_KEY 
				LEFT OUTER JOIN WOENTRY W
				ON I.Wono = W.WONO 		
			
	--INSERT @tInserted
	--		SELECT QtyXfer, SaveInit, cModid, FromWKey, ToWkey, I.Wono, UniqMfgrhd, I.Uniq_key, SerialUniq, lSkipUnallocCode, Kaseqnum,
	--				LotCode, Expdate, Reference, Ponum, Serialno, Invtxfer_n, W.PrjUnique
	--			FROM Inserted I LEFT OUTER JOIN WOENTRY W
	--			ON I.Wono = W.WONO 
				
	SET @lnTotalCount = @@ROWCOUNT;
	SET @lnCnt = 0

		
	IF @lnTotalCount <> 0		
	BEGIN
		WHILE @lnTotalCount> @lnCnt
		BEGIN
		SET @lnCnt = @lnCnt + 1	
		--08/07/14 YS new @useIpKey and @sourcedev
		-- 10/09/2017 Sachin B :remove Serialno and SerialUniq from INVTTRNS table and update insert trigger
		SELECT @lnQtyThisTime = QtyXfer, @lcSaveInit = SaveInit, @lcModid = cModid, @lcFromWKey = FromWKey, @lcToWKey = ToWkey, 
				@lcWono = Wono, @lcUniqMfgrhd = UniqMfgrhd, @lcUniq_key = Uniq_key, --@lcSerialUniq = SerialUniq, 
				@lSkipUnallocCode = lSkipUnallocCode, @lcKaseqnum = Kaseqnum, @lcLotCode = LotCode, @ltExpdate = Expdate, 
				@lcReference = Reference, @lcPonum = Ponum, --@lcSerialno = Serialno,
				 @lcInvtxfer_n = Invtxfer_n, @lcFk_PrjUnique = PrjUnique,
				@UseIPKEY=useIpkey,@sourceDev=sourcedev
			FROM @tInserted WHERE nId = @lnCnt;

	

		-- 12/03/12 VL not delete, only insert at the end
		-- 12/02/12 VL delete all records from @ZWO_WIPAlloc after scan through inserted table
		--DELETE FROM @ZWO_WIPAlloc WHERE 1 = 1
		-- check if serialized
		-- 11/30/12 VL changed to use a variable
		--SELECT @lSerialYes=SerialYes,@lcPart_sourc=Part_sourc from Inventor where Uniq_key IN (SELECT Uniq_key from INSERTED);
		SELECT @lSerialYes=SerialYes,@lcPart_sourc=Part_sourc, @lcPart_class = PART_CLASS, @lcPart_type = PART_TYPE from Inventor where Uniq_key = @lcUniq_key;
		-- 11/28/12 VL get Parttype.LotDetail
		SELECT @llLotDetail = ISNULL(LOTDETAIL,0) 
			FROM PARTTYPE 
			WHERE PART_CLASS = @lcPart_class
			AND PART_TYPE =@lcPart_type

												
		-- check if moving from WO-WIP
		-- 11/30/12 VL changed to use a variable
		--SELECT @lFromWO_WIP=CASE WHEN (Warehous.Warehouse='WO-WIP') THEN 1 ELSE 0 END,
		--	 @lFromInstore=Invtmfgr.Instore,@lnQty_oh=Invtmfgr.Qty_oh, @lnReserved=Invtmfgr.Reserved,@lcFromLocation=Invtmfgr.Location
		--	 FROM Warehous,Invtmfgr WHERE Warehous.UniqWh=Invtmfgr.UniqWh and Invtmfgr.W_key IN (SELECT FromWKey FROM Inserted);
		--05/08/13 YS add @lcFromuniq_key to check if from and to uniq_key match
		SELECT @lFromWO_WIP=CASE WHEN (Warehous.Warehouse='WO-WIP') THEN 1 ELSE 0 END,
			 @lFromInstore=Invtmfgr.Instore,@lnQty_oh=Invtmfgr.Qty_oh, @lnReserved=Invtmfgr.Reserved,@lcFromLocation=Invtmfgr.Location,
			 @lcFromWkeyUniqWh = Invtmfgr.UNIQWH, @lcFromWkeyUniqMfgrhd = UniqMfgrhd, @lcFromWkeyUniqSupno = UniqSupno,
			 @lcFromuniq_key = Invtmfgr.Uniq_key
			 FROM Warehous,Invtmfgr WHERE Warehous.UniqWh=Invtmfgr.UniqWh and Invtmfgr.W_key = @lcFromWKey
		
		IF (@@ROWCOUNT=0)
			BEGIN
				RAISERROR('Cannot find a record in the Invtmfgr table. This operation will be cancelled.',1,1)
				ROLLBACK TRANSACTION
				RETURN	
		END -- if (@@ROWCOUNT=0) From Invtmfgr
		-- 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
		--SELECT @lcPartmfgr = Partmfgr, @lcMfgr_pt_no = Mfgr_pt_no FROM INVTMFHD WHERE UNIQMFGRHD = @lcFromWkeyUniqMfgrhd
		--03/09/15 YS added @mfgrmasterid variable
		SELECT @lcPartmfgr = m.Partmfgr, @lcMfgr_pt_no = m.Mfgr_pt_no ,
				@mfgrMasterid= m.mfgrmasterid,@lcMatlType=m.Matltype
			FROM MfgrMaster M INNER JOIN InvtMPNLink L ON M.MfgrMasterId=l.mfgrMasterId
			WHERE L.UNIQMFGRHD = @lcFromWkeyUniqMfgrhd
		IF (@@ROWCOUNT=0)
			BEGIN
				RAISERROR('Cannot find a record in the MfgrMaster table. This operation will be cancelled.',1,1)
				ROLLBACK TRANSACTION
				RETURN	
		END -- if (@@ROWCOUNT=0) From MfgrMaster
				
		-- check if movint to WO-WIP
		-- 11/30/12 VL changed to use a variable
		--SELECT @lToWO_WIP=CASE WHEN (Warehous.Warehouse='WO-WIP') THEN 1 ELSE 0 END,
		--	  @lToInstore=Invtmfgr.Instore ,@lcToLocation=Invtmfgr.Location
		--		FROM Warehous,Invtmfgr WHERE Warehous.UniqWh=Invtmfgr.UniqWh and Invtmfgr.W_key IN (SELECT ToWKey FROM Inserted);
		--05/08/13 YS add @lcTouniq_key to check if from and to uniq_key match
		SELECT @lToWO_WIP=CASE WHEN (Warehous.Warehouse='WO-WIP') THEN 1 ELSE 0 END,
			  @lToInstore=Instore ,@lcToLocation=Location,
			  @lcTouniq_key=Uniq_key
				FROM Warehous,Invtmfgr
				WHERE Warehous.UniqWh=Invtmfgr.UniqWh and Invtmfgr.W_key =@lcToWKey

		IF (@@ROWCOUNT=0)
			BEGIN
				RAISERROR('Cannot find a record in the Invtmfgr table. This operation will be cancelled.',1,1)
				ROLLBACK TRANSACTION
				RETURN	
		END -- if (@@ROWCOUNT=0) To invtmfgr
		
		/*05/08/13 YS check from and to uniq_key */
		
		IF @lcTouniq_key<>@lcFromuniq_key
		BEGIN
			
			RAISERROR('Please record all the steps you''ve done and have your system administrator call MANEX with the following message: The link to the Inventor table for ''To'' and ''From'' is not related to the link in the InvtMfgr table. This operation will be cancelled. ',1,1)
			ROLLBACK TRANSACTION
			RETURN
		END  -- IF @lcTouniq_key<>@lcFromuniq_key
		
		/*check available qty */
		-- 09/01/2017 Satish B : Modify the IF condition for the scenario [ IF @lnQty_oh and @lnQtyThisTime=1 ]
		-- Because when the transfer quantity is 1, in this case Invtmfgr.qty_oh= Invtmfgr.qty_oh - @lnQtyThisTime and set @lnQty_oh = Invtmfgr.qty_oh as Invtmfgr updated above
		-- SO in this case @lnQty_oh is 0 and @lnQtyThisTime=1 then also it rais the error
		-- 09/02/2017 Satish B : Revert back changes made on 09/01/2017
		-- 09/19/2017 Satish B : Comment the validation of @lnQty_oh<@lnQtyThisTime as it raise error when @lnQty_oh =1 and @lnQtyThisTime=1(Beacause it first update the INVTMFGR and 
		--set @lnQty_oh =INVTMFGR.Qty_Oh - qty transfer and set to 0)
		--IF @lnQty_oh<@lnQtyThisTime --) AND (@lnQtyThisTime=1 AND @lnQty_oh<>0)
		--BEGIN
		--	RAISERROR('No quantity available to transfer.',1,1)
		--	ROLLBACK TRANSACTION
		--	RETURN	
		--END
		-- 02/03/12 VL check VFP 01/19/06 code, comment out here, will move code to later
		--IF @lnQty_oh-@lnReserved<@lnQtyThisTime AND @lToWO_WIP=0
		--BEGIN	
		--	RAISERROR('No quantity available to transfer',1,1)
		--	ROLLBACK TRANSACTION
		--	RETURN
		--END	
		-- 02/03/12 VL End}
		
		-- 12/02/12 VL found the code was run several times below, tried to run only once
		-- 12/03/12 VL comment out, already get from the scan of @tInserted
		--SELECT @lcFk_PrjUnique=Woentry.PrjUnique FROM WOENTRY WHERE Wono=@lcWono
		SELECT @lnQtyResWo=SUM(QtyAlloc) 
			FROM Invt_res
			WHERE Wono=@lcWono
			AND W_key=@lcFromWKey
			GROUP BY Wono,W_key
		HAVING SUM(QtyAlloc)>0
		
		-- 08/28/14 VL found for some reasons it not always return NULL for no allocation record, sometimes it return 0
		-- 12/03/12 VL changed because @@ROWCOUNT>0 doesn't mean has allocation record
		--SET @lReservedWo=CASE WHEN @@ROWCOUNT>0 THEN 1 ELSE 0 END
		--SET @lReservedWo = CASE WHEN @lnQtyResWo IS NULL THEN 0 ELSE 1 END
		SET @lReservedWo = CASE WHEN (@lnQtyResWo IS NULL OR @lnQtyResWo = 0) THEN 0 ELSE 1 END
		
		SELECT @lnQtyResPrj=SUM(QtyAlloc) 
			FROM Invt_res
			WHERE Fk_PrjUnique=@lcFk_PrjUnique
			AND W_key=@lcFromWKey
			AND Fk_PrjUnique<>' '
			GROUP BY Fk_PrjUnique,W_key
		HAVING SUM(QtyAlloc)>0
		
		-- 08/28/14 VL found for some reasons it not always return NULL for no allocation record, sometimes it return 0
		-- 12/03/12 VL changed because @@ROWCOUNT>0 doesn't mean has allocation record
		--SET @lReservedPrj=CASE WHEN @@ROWCOUNT>0 THEN 1 ELSE 0 END
		--SET @lReservedPrj=CASE WHEN @lnQtyResPrj IS NULL THEN 0 ELSE 1 END
		SET @lReservedPrj=CASE WHEN (@lnQtyResPrj IS NULL OR @lnQtyResPrj = 0) THEN 0 ELSE 1 END

--------------		
		-- 06/18/14 VL changed to include all 3 modid 'C','K','U'
		--IF @lnQty_oh-@lnReserved<@lnQtyThisTime AND @lFromWO_WIP=1 AND @lcModId='K' -- Avail qty less than transfer check if reserved for a WO or a project
		IF @lnQty_oh-@lnReserved<@lnQtyThisTime AND @lFromWO_WIP=1 AND (@lcModId='U' OR @lcModId='K' OR @lcModId='C') -- Avail qty less than transfer check if reserved for a WO or a project
		BEGIN
			-- check if to wo-wip and has reserved to a Work order from which transfer is created (current work order in the KIT module)
			-- search for the project
			-- 12/02/12 VL move to upper place, so only need to run once
			--SELECT @lcFk_PrjUnique=Woentry.PrjUnique FROM WOENTRY WHERE Wono=@lcWono
			
			-- check if reserved to a wo
			-- 12/02/12 VL move to uppper place, so only run once
			--SELECT @lnQtyResWo=SUM(QtyAlloc) 
			--	FROM Invt_res
			--	WHERE Wono=@lcWono
			--	AND W_key=@lcFromWKey
			--	GROUP BY Wono,W_key
			--HAVING SUM(QtyAlloc)>0
				
			--SET @lReservedWo=CASE WHEN @@ROWCOUNT>0 THEN 1 ELSE 0 END
			
			--check if reserved to a project
			
			--SELECT @lnQtyResPrj=SUM(QtyAlloc) 
			--	FROM Invt_res
			--	WHERE Fk_PrjUnique=@lcFk_PrjUnique
			--	AND W_key=@lcFromWKey
			--	AND Fk_PrjUnique<>' '
			--	GROUP BY Fk_PrjUnique,W_key
			--HAVING SUM(QtyAlloc)>0
						
			--SET @lReservedPrj=CASE WHEN @@ROWCOUNT>0 THEN 1 ELSE 0 END
				
			IF @lReservedPrj=0 and @lReservedWo=0
			BEGIN
				RAISERROR('No quantity available to transfer. This operation will be cancelled.',1,1)
				ROLLBACK TRANSACTION
				RETURN	
			END	-- if @lReservedPrj=0 and @lReservedWo=0
			-- 04/26/12 VL added more @lReservedWo = 1 OR @lReservedPrj = 1 criteria
			--IF @lnQty_oh-@lnQtyThisTime+ISNULL(@lnQtyResWo,0.00)+ISNULL(@lnQtyResPrj,0.00)<@lnQtyThisTime
			IF (@lReservedWo = 1 OR @lReservedPrj = 1) AND @lnQty_oh-@lnReserved+ISNULL(@lnQtyResWo,0.00)+ISNULL(@lnQtyResPrj,0.00)<@lnQtyThisTime
			BEGIN		
				---Some one reduce the qty, cannot proceed 
				RAISERROR('No quantity available to transfer. This operation will be cancelled.',1,1)
				ROLLBACK TRANSACTION
				RETURN	
			END -- IF @lnQty_oh-@lnQtyThisTime+ISNULL(@lnQtyResWo,0.00)+ISNULL(@lnQtyResPrj,0.00)<@lnQtyThisTime
		END	-- @lnQty_oh-@lnQtyThisTime<@lnQtyThisTime AND @lFromWO_WIP=1 AND @lcModId="K"
		
		-- 06/21/11 VL fixed
		--IF @lnQty_oh-@lnQtyThisTime<@lnQtyThisTime AND @lToWO_WIP=1 --- Avail qty less than transfer check if reserved for the WO			
		IF @lnQty_oh-@lnReserved<@lnQtyThisTime AND @lToWO_WIP=1 --- Avail qty less than transfer check if reserved for the WO			
		BEGIN
			-- 02/14/12 VL changed to use @lcFromWKey
			-- check if to wo-wip and has reserved for the wo
			-- check project if assigned
			-- 12/02/12 VL moved to upper place, so only run once
			--SELECT @lcFk_PrjUnique=Woentry.PrjUnique FROM WOENTRY WHERE Wono=@lcWono
			
			-- check if reserved to a wo
			--SELECT @lnQtyResWo=SUM(QtyAlloc) 
			--	FROM Invt_res
			--	WHERE Wono=@lcWono
			--	AND W_key=@lcFromWKey
			--	GROUP BY Wono,W_key
			--HAVING SUM(QtyAlloc)>0
				
			--SET @lReservedWo=CASE WHEN @@ROWCOUNT>0 THEN 1 ELSE 0 END
		
			--check if reserved to a project
			--SELECT @lnQtyResPrj=SUM(QtyAlloc) 
			--	FROM Invt_res
			--	WHERE Fk_PrjUnique=@lcFk_PrjUnique
			--	AND W_key=@lcFromWKey
			--	AND Fk_PrjUnique<>' '
			--	GROUP BY Fk_PrjUnique,W_key
			--HAVING SUM(QtyAlloc)>0
						
			--SET @lReservedPrj=CASE WHEN @@ROWCOUNT>0 THEN 1 ELSE 0 END
			
			IF @lnQtyResWo = 0.00 AND @lnQtyResPrj = 0.00		-- No reservation for this WO or a project
			BEGIN
				RAISERROR('No quantity available to transfer. This operation will be cancelled.',1,1)
				ROLLBACK TRANSACTION
				RETURN	
			END	-- IF @lnQtyResWo = 0.00 AND @lnQtyResPrj = 0.00
			-- 04/26/12 VL fixed next line
			--IF (@lnQtyResWo>0 OR @lnQtyResPrj>0) AND @lnQty_oh-@lnQtyThisTime+ISNULL(@lnQtyResWo,0.00)+ISNULL(@lnQtyResPrj,0.00)<@lnQtyThisTime
			IF (@lnQtyResWo>0 OR @lnQtyResPrj>0) AND @lnQty_oh-@lnReserved+ISNULL(@lnQtyResWo,0.00)+ISNULL(@lnQtyResPrj,0.00)<@lnQtyThisTime
			BEGIN
				---Some one reduce the qty, cannot proceed 
				RAISERROR('No quantity available to transfer. This operation will be cancelled.',1,1)
				ROLLBACK TRANSACTION
				RETURN	
			END	-- IF (@lnQtyResWo>0 OR @lnQtyResPrj>0) AND @lnQty_oh-@lnQtyThisTime+ISNULL(@lnQtyResWo,0.00)+ISNULL(@lnQtyResPrj,0.00)<@lnQtyThisTime
		END	-- IF @lnQty_oh-@lnQtyThisTime<@lnQtyThisTime AND  @lToWO_WIP=1
		
		-- 06/18/14 VL added all 3 cmodid 'C','K','U'
		--IF @lToWO_WIP =1 OR (@lFromWO_WIP=1 AND @lcModId='K')
		IF @lToWO_WIP =1 OR (@lFromWO_WIP=1 AND (@lcModId='U' OR @lcModId='K' OR @lcModId='C'))
		--BEGIN
		IF @lnQty_oh-@lnLotResQty<@lnQtyThisTime AND @lToWO_WIP=0 -- Avail qty less than transfer and not to wo-wip
		BEGIN
			---Some one reduce the qty, cannot proceed 
			RAISERROR('No quantity available to transfer. This operation will be cancelled.',1,1)
			ROLLBACK TRANSACTION
			RETURN	
		END	-- -- IF @lToWO_WIP =1 OR (@lFromWO_WIP=1 AND @lcModId='K')	
		-- 06/18/14 VL added to check all 3 cmodid 'C','K','U'
		--IF (@lToWO_WIP=1 OR @lFromWO_WIP=1) AND (@lReservedWo=1 OR @lReservedPrj=1) AND (@lcModId<>'K') OR (@lcModId='K' AND @lSkipUnallocCode=0)
		IF (@lToWO_WIP=1 OR @lFromWO_WIP=1) AND (@lReservedWo=1 OR @lReservedPrj=1) AND ((@lcModId<>'U' AND @lcModId<>'K' AND @lcModId<>'C') OR ((@lcModId='U' OR @lcModId='K' OR @lcModId='C') AND @lSkipUnallocCode=0))
		BEGIN
			SET @lnDelta=@lnQtyThisTime;
			SET @lnUnreserved=0.00
			SET @lnCount=0;
			IF @lReservedWo=1
			BEGIN
				-- need to relese reserved qty
				-- 11/30/12 VL move this part to outside very top, only delete all records here
				--declare @tInvtAlloc table 
				--	(nrecno int identity, Invtres_no char(10),w_key char(10),wono char(10),LotCode char(15),ExpDate smalldatetime,Reference char(12),
				--	PoNum char(15),Serialno char(30), qtyalloc numeric(12,2),fk_prjunique char(10),UniqueLn char(10) ) ;
					-- fill up records with information form Invt_Res
					-- 11/30/12 VL changed to only get for one inserted record
					---- 06/28/11 VL added to consider expdate = null, if don't add ISNULL(), it won't find null record
					--INSERT INTO @tInvtAlloc SELECT Invtres_no,invt_res.W_key,invt_res.wono,invt_res.LotCode,invt_res.ExpDate,invt_res.Reference,
					--	invt_res.PoNum,invt_res.Serialno,invt_res.qtyalloc,Invt_res.Fk_PrjUnique,Invt_res.UniqueLn from invt_res,INSERTED I where 
					--	Invt_res.w_key=I.FromWkey and Invt_res.wono=@lcWono and Invt_res.qtyalloc>0 
					--	and invt_res.LotCode=I.LotCode AND ISNULL(invt_res.ExpDate,1)=ISNULL(I.ExpDate,1) and invt_res.Reference = I.Reference and invt_res.Ponum=I.Ponum 
					--	and invt_res.SerialNo=I.SerialNo and NOT EXISTS (SELECT 1 from invt_res R2 where r2.REFINVTRES=Invt_res.InvtRes_no) ORDER BY Invt_res.qtyalloc DESC
					-- 06/28/11 VL added to consider expdate = null, if don't add ISNULL(), it won't find null record
					
				DELETE FROM @tInvtAlloc WHERE 1 = 1
				SET @lnTableVarCnt = 0

				INSERT INTO @tInvtAlloc SELECT 0 AS nRecno, Invtres_no,invt_res.W_key,invt_res.wono,invt_res.LotCode,invt_res.ExpDate,
						invt_res.Reference, invt_res.PoNum,invt_res.qtyalloc,Invt_res.Fk_PrjUnique,Invt_res.UniqueLn 
				-- 02/08/2017  Satish B : Serialno and lIsFromSo columns are not exist in INVT_RES table as per the new database structute
						-- invt_res.Serialno,Invt_res.lIsFromSo 
					FROM invt_res 
					WHERE Invt_res.w_key = @lcFromWKey 
					AND Invt_res.wono = @lcWono 
					AND Invt_res.qtyalloc > 0 
					AND Invt_res.LotCode = @lcLotCode 
					AND ISNULL(Invt_res.ExpDate,1)=ISNULL(@ltExpDate,1) 
					AND Invt_res.Reference = @lcReference 
					AND Invt_res.Ponum = @lcPonum 
				-- 02/08/2017  Satish B : Serialno and lIsFromSo columns are not exist in INVT_RES table as per the new database structute
					-- AND Invt_res.SerialNo =  @lcSerialNo  
					
					AND NOT EXISTS (SELECT 1 FROM Invt_res R2 WHERE R2.REFINVTRES=Invt_res.InvtRes_no)
					ORDER BY Invt_res.Qtyalloc DESC

				UPDATE @tInvtAlloc SET @lnTableVarCnt = nRecno = @lnTableVarCnt + 1
				-- 11/30/12 VL End]
				
				-- 08/28/13 VL changed from checking @@ROWCOUNT>0 to @lnTableVarCnt > 0								
				IF @lnTableVarCnt>0
				BEGIN
					-- 12/12/13 VL added one more criteria to prevent endless loop
					WHILE @lnDelta>0 AND @lnTableVarCnt>@lnCount
					BEGIN
						-- update the count
						SET @lnCount=@lnCount+1;
						SELECT @lnQtyAlloc=QtyAlloc,@lcInvtRes_no=Invtres_no
						--@lIsFromSO = lIsFromSO 
						FROM @tInvtAlloc where nrecno=@lncount;
						IF (@@ROWCOUNT=0)
						--no more records leave the while loop
						BREAK;
						
						IF (@lnQtyAlloc>@lnDelta)
						BEGIN
							-- more than enough decrease the reserved records
							UPDATE Invt_res set QtyAlloc = QtyAlloc-@lnDelta,
								SaveInit = @lcSaveInit,
								[DateTime]=GETDATE() where Invtres_no=@lcInvtres_no;
							-- check if the qty stayed positive
							-- 11/30/12 VL assigned it into a variable
							--IF (SELECT Qtyalloc from invt_res where invtres_no=@lcInvtres_no)<0 
							SELECT @lnChkQtyalloc = Qtyalloc from invt_res where invtres_no=@lcInvtres_no
							IF @lnChkQtyalloc < 0 
							BEGIN
								--SET @lRollBack=1;
								RAISERROR('No quantity available to unallocate. This operation will be cancelled.',1,1)
								ROLLBACK TRANSACTION
								RETURN	
								BREAK;
							END -- end of the if (SELECT Qtyalloc from invt_res where invtres_no=@lcInvtres_no)<0 block
							ELSE -- (SELECT Qtyalloc from invt_res where invtres_no=@lcInvtres_no)<0 
							BEGIN
								-- 02/03/11 VL added code to create allocation record for the WO-WIP. (unallocate from original location, but need to allocate to the WO-WIP)
								-- will insert into invt_res after invtmfgr.qty_oh is updated
								--EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
								--INSERT INTO INVT_RES(W_KEY,[UNIQ_KEY],[DATETIME],[QTYALLOC],[WONO],[INVTRES_NO],[LOTCODE],[EXPDATE],[REFERENCE] ,[PONUM],[SAVEINIT] ,[FK_PRJUNIQUE] ,[SERIALNO],[SERIALUNIQ])
								--	 SELECT ToWkey,Uniq_key,GETDATE(),@lnDelta,
								--	CASE WHEN @lReservedWo=1 THEN @lcWono ELSE ' ' END,
								--	 @lcNewUniqNbr,LotCode,ExpDate,Reference,Ponum,Saveinit,
								--	  CASE WHEN @lReservedPrj=1 THEN @lcFk_PrjUnique ELSE ' ' END,
								--	  SerialNo,SerialUniq FROm Inserted

								-- 11//30/12 VL changed to save one record at a time
								--INSERT INTO @ZWo_WipAlloc(W_KEY,[UNIQ_KEY],[DATETIME],[QTYALLOC],[WONO],[INVTRES_NO],[LOTCODE],[EXPDATE],[REFERENCE] ,[PONUM],
								--	[SAVEINIT] ,[FK_PRJUNIQUE] ,[SERIALNO],[SERIALUNIQ],[Sono],[Uniqueln],[RefinvtRes])
								--	 SELECT ToWkey,Uniq_key,GETDATE(),@lnDelta,
								--	CASE WHEN @lReservedWo=1 THEN @lcWono ELSE ' ' END,
								--	 @lcNewUniqNbr,LotCode,ExpDate,Reference,Ponum,Saveinit,
								--	  CASE WHEN @lReservedPrj=1 THEN @lcFk_PrjUnique ELSE ' ' END,
								--	  SerialNo,SerialUniq, '' AS Sono,'' AS Uniqueln,'' AS RefinvtRes FROm Inserted
					-- 02/09/2017  Satish B : Remove cloumns :Serialno,SerialUniq,lIsFromSO as per new database structure
								INSERT INTO @ZWo_WipAlloc(W_KEY,[UNIQ_KEY],[DATETIME],[QTYALLOC],[WONO],[INVTRES_NO],[LOTCODE],[EXPDATE],[REFERENCE] ,[PONUM],
									[SAVEINIT] ,[FK_PRJUNIQUE] ,[Sono],[Uniqueln],[RefinvtRes]
									--[SERIALNO],
									--[SERIALUNIQ],
									--[lIsFromSO]
									)
									VALUES 
									(@lcToWKey, @lcUniq_key, GETDATE(), @lnDelta, CASE WHEN @lReservedWo=1 THEN @lcWono ELSE ' ' END,
									dbo.fn_GenerateUniqueNumber(), @lcLotCode, @ltExpdate, @lcReference, @lcPonum, @lcSaveInit, CASE WHEN @lReservedPrj=1 THEN @lcFk_PrjUnique ELSE ' ' END,
									'','',''
									--@lcSerialno, 
									--@lcSerialUniq,@lIsFromSo
									)
									  
								SET @lnUnreserved=@lnUnreserved+@lnDelta;
								SET @lnDelta=0;	 
									 
							END -- end of block of the else -- (SELECT Qtyalloc from invt_res where invtres_no=@lcInvtres_no)<0 
						END	-- end of block for the if (@lnQtyAlloc>@lnDelta)	block
						ELSE -- (@lnQtyAlloc>@lnDelta)
						BEGIN
							-- 02/03/11 VL added code to create allocation record for the WO-WIP. (unallocate from original location, but need to allocate to the WO-WIP)
							-- will insert into invt_res after invtmfgr.qty_oh is updated							
							--EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
							--INSERT INTO INVT_RES(W_KEY,[UNIQ_KEY],[DATETIME],[QTYALLOC],[WONO],[INVTRES_NO],[LOTCODE],[EXPDATE],[REFERENCE] ,[PONUM],[SAVEINIT] ,[FK_PRJUNIQUE] ,[SERIALNO],[SERIALUNIQ])
							--		 SELECT ToWkey,Uniq_key,GETDATE(),@lnQtyAlloc,
							--		CASE WHEN @lReservedWo=1 THEN @lcWono ELSE ' ' END,
							--		 @lcNewUniqNbr,LotCode,ExpDate,Reference,Ponum,Saveinit,
							--		  CASE WHEN @lReservedPrj=1 THEN @lcFk_PrjUnique ELSE ' ' END,
							--		  SerialNo,SerialUniq FROm Inserted

							-- 11/30/12 VL changed to save a record at a time
							--INSERT INTO @ZWo_WipAlloc (W_KEY,[UNIQ_KEY],[DATETIME],[QTYALLOC],[WONO],[INVTRES_NO],[LOTCODE],[EXPDATE],[REFERENCE],
							--		[PONUM],[SAVEINIT] ,[FK_PRJUNIQUE] ,[SERIALNO],[SERIALUNIQ],[Sono],[Uniqueln],[RefinvtRes])
							--		 SELECT ToWkey,Uniq_key,GETDATE(),@lnQtyAlloc,
							--		CASE WHEN @lReservedWo=1 THEN @lcWono ELSE ' ' END,
							--		 @lcNewUniqNbr,LotCode,ExpDate,Reference,Ponum,Saveinit,
							--		  CASE WHEN @lReservedPrj=1 THEN @lcFk_PrjUnique ELSE ' ' END,
							--		  SerialNo,SerialUniq, '' AS Sono,'' AS Uniqueln,'' AS RefinvtRes FROm Inserted

							-- 02/09/2017  Satish B : Remove cloumns :Serialno,SerialUniq,lIsFromSO as per new database structure
							INSERT INTO @ZWo_WipAlloc(W_KEY,[UNIQ_KEY],[DATETIME],[QTYALLOC],[WONO],[INVTRES_NO],[LOTCODE],[EXPDATE],[REFERENCE] ,[PONUM],
								[SAVEINIT] ,[FK_PRJUNIQUE] ,[Sono],[Uniqueln],[RefinvtRes]
								--,[SERIALNO]
								--,[SERIALUNIQ],[lIsFromSo]
								)
								VALUES 
								(@lcToWKey, @lcUniq_key, GETDATE(), @lnQtyAlloc, CASE WHEN @lReservedWo=1 THEN @lcWono ELSE ' ' END,
								dbo.fn_GenerateUniqueNumber(), @lcLotCode, @ltExpdate, @lcReference, @lcPonum, @lcSaveInit, 
								CASE WHEN @lReservedPrj=1 THEN @lcFk_PrjUnique ELSE ' ' END, '','',''
								--@lcSerialno,
								--,@lcSerialUniq,@lIsFromSo
								)
									  
							-- assign new lnDelta and remove allocation from the table
							SET @lnDelta=@lnDelta-@lnQtyAlloc;
							SET @lnUnreserved=@lnUnreserved+@lnQtyAlloc;
							DELETE FROM Invt_res WHERE Invtres_no=@lcInvtres_no 
						END	--ELSE -- (@lnQtyAlloc>@lnDelta)
					END -- WHILE @lnDelta>0	Loop in the allocation for a work order
				END --	@@ROWCOUNT>0 allocation for a work order
			END --	IF @lReservedWo=1
			IF (@lnDelta>0) and (@lReservedPrj=1)
			BEGIN
				-- look for more allocations to the project related to a work order
				-- 11/30/12 VL added to set @lnTableVarCnt = 0, will reset the recno
				DELETE FROM @tInvtAlloc WHERE 1 = 1
				SET @lnTableVarCnt = 0
				
				-- 11/30/12 VL changed to update one record at a time
				-- 06/28/11 VL added to consider expdate = null, if don't add ISNULL(), it won't find null record
				--INSERT into @tInvtAlloc SELECT invt_res.Invtres_no,invt_res.W_key,invt_res.wono,invt_res.LotCode,invt_res.ExpDate,invt_res.Reference,
				--	invt_res.PoNum,invt_res.Serialno,invt_res.qtyalloc,Invt_res.Fk_PrjUnique,Invt_res.UniqueLn from invt_res,INSERTED I 
				--	where Invt_res.w_key=I.FromWkey and Invt_res.Fk_PrjUnique=@lcFk_PrjUnique 
				--	AND Invt_res.qtyalloc>0 
				--	and invt_res.LotCode=I.LotCode AND ISNULL(invt_res.ExpDate,1)=ISNULL(I.ExpDate,1) and invt_res.Reference = I.Reference and invt_res.Ponum=I.Ponum 
				--	and invt_res.SerialNo=I.SerialNo and NOT EXISTS (SELECT 1 from invt_res R2 where r2.REFINVTRES=Invt_res.InvtRes_no) ORDER BY Invt_res.qtyalloc DESC

				INSERT INTO @tInvtAlloc SELECT 0 AS nRecno, Invtres_no,invt_res.W_key,invt_res.wono,invt_res.LotCode,invt_res.ExpDate,
						invt_res.Reference, invt_res.PoNum,invt_res.qtyalloc,Invt_res.Fk_PrjUnique,Invt_res.UniqueLn

				-- 02/08/2017  Satish B : Serialno and lIsFromSo columns are not present in INVT_RES table as per the new database structute
						--invt_res.Serialno, Invt_res.lIsFromSo 
					FROM invt_res 
					WHERE Invt_res.w_key = @lcFromWkey 
					AND Invt_res.Fk_PrjUnique=@lcFk_PrjUnique 
					AND Invt_res.qtyalloc > 0 
					AND Invt_res.LotCode = @lcLotCode 
					AND ISNULL(Invt_res.ExpDate,1)=ISNULL(@ltExpDate,1) 
					AND Invt_res.Reference = @lcReference 
					AND Invt_res.Ponum = @lcPonum 
				 -- 02/08/2017  Satish B : Serialno and lIsFromSo columns are not exist in INVT_RES table as per the new database structute
					--AND Invt_res.SerialNo =  @lcSerialNo 
					AND NOT EXISTS (SELECT 1 FROM Invt_res R2 WHERE R2.REFINVTRES=Invt_res.InvtRes_no)
					ORDER BY Invt_res.Qtyalloc DESC

				UPDATE @tInvtAlloc SET @lnTableVarCnt = nRecno = @lnTableVarCnt + 1
				-- 11/30/12 VL End}
											
				-- 08/28/13 VL changed from checking @@ROWCOUNT>0 to @lnTableVarCnt > 0																
				IF (@lnTableVarCnt<>0)
				BEGIN	
					SET @lnCount=0;
					-- 12/12/13 VL added one more criteria to prevent endless loop
					WHILE @lnDelta>0 AND @lnTableVarCnt>@lnCount
					BEGIN
					-- update the count
						set @lnCount=@lnCount+1;
						-- get next record
						SELECT @lnQtyAlloc=QtyAlloc,@lcInvtres_no=Invtres_no FROM  @tInvtAlloc where nrecno=@lncount;
						-- check if any records were selected
						IF (@@ROWCOUNT=0)
						--no more records
						BREAK;
						IF (@lnQtyAlloc>@lnDelta)
						BEGIN
							-- more than enough decrease the reserved records
							UPDATE Invt_res set QtyAlloc = QtyAlloc-@lnDelta ,
								SaveInit = @lcSaveInit,
								[DateTime]=GETDATE()where Invtres_no=@lcInvtres_no;
								-- check if the qty stayed positive
							-- 11/30/12 VL assigned it into a variable
							--IF (SELECT Qtyalloc from invt_res where invtres_no=@lcInvtres_no)<0 
							SELECT @lnChkQtyalloc = Qtyalloc from invt_res where invtres_no=@lcInvtres_no
							IF @lnChkQtyalloc < 0 								
							BEGIN
								RAISERROR('No quantity available to unallocate. This operation will be cancelled.',1,1)
								ROLLBACK TRANSACTION
								RETURN
								BREAK;
							END -- IF (SELECT Qtyalloc from invt_res where invtres_no=@lcInvtres_no)<0
							ELSE -- (SELECT Qtyalloc from invt_res where invtres_no=@lcInvtres_no)<0 
							BEGIN
								--EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
								-- 02/03/11 VL added code to create allocation record for the WO-WIP. (unallocate from original location, but need to allocate to the WO-WIP)
								-- will insert into invt_res after invtmfgr.qty_oh is updated
								--INSERT INTO INVT_RES(W_KEY,[UNIQ_KEY],[DATETIME],[QTYALLOC],[WONO],[INVTRES_NO],[LOTCODE],[EXPDATE],[REFERENCE] ,[PONUM],[SAVEINIT] ,[FK_PRJUNIQUE] ,[SERIALNO],[SERIALUNIQ])
								--	 SELECT ToWkey,Uniq_key,GETDATE(),@lnDelta,
								--	CASE WHEN @lReservedWo=1 THEN @lcWono ELSE ' ' END,
								--	 @lcNewUniqNbr,LotCode,ExpDate,Reference,Ponum,Saveinit,
								--	  CASE WHEN @lReservedPrj=1 THEN @lcFk_PrjUnique ELSE ' ' END,
								--	  SerialNo,SerialUniq FROm Inserted
								
								-- 11/30/12 VL changed save a record a time, don't use Inserted
								--INSERT INTO @ZWo_WipAlloc(W_KEY,[UNIQ_KEY],[DATETIME],[QTYALLOC],[WONO],[INVTRES_NO],[LOTCODE],[EXPDATE],[REFERENCE],
								--		[PONUM],[SAVEINIT] ,[FK_PRJUNIQUE] ,[SERIALNO],[SERIALUNIQ],[Sono],[Uniqueln],[RefinvtRes])
								--	 SELECT ToWkey,Uniq_key,GETDATE(),@lnDelta,
								--	CASE WHEN @lReservedWo=1 THEN @lcWono ELSE ' ' END,
								--	 @lcNewUniqNbr,LotCode,ExpDate,Reference,Ponum,Saveinit,
								--	  CASE WHEN @lReservedPrj=1 THEN @lcFk_PrjUnique ELSE ' ' END,
								--	  SerialNo,SerialUniq, '' AS Sono,'' AS Uniqueln,'' AS RefinvtRes FROm Inserted

								-- 02/09/2017  Satish B : Remove cloumns :Serialno,SerialUniq,lIsFromSO as per new database structure
								INSERT INTO @ZWo_WipAlloc(W_KEY,[UNIQ_KEY],[DATETIME],[QTYALLOC],[WONO],[INVTRES_NO],[LOTCODE],[EXPDATE],[REFERENCE],
										[PONUM],[SAVEINIT] ,[FK_PRJUNIQUE] ,[Sono],[Uniqueln],[RefinvtRes]
										--[SERIALNO],
										--,[SERIALUNIQ],[lIsFromSo]
										)
									VALUES 
									(@lcToWKey, @lcUniq_key, GETDATE(), @lnDelta, CASE WHEN @lReservedWo=1 THEN @lcWono ELSE ' ' END,
									dbo.fn_GenerateUniqueNumber(), @lcLotCode, @ltExpdate, @lcReference, @lcPonum, @lcSaveInit, 
									CASE WHEN @lReservedPrj=1 THEN @lcFk_PrjUnique ELSE ' ' END, '','',''
									--@lcSerialno,
									--, @lcSerialUniq, @lIsFromSo
									)
								
								SET @lnUnreserved=@lnUnreserved+@lnDelta;
								SET @lnDelta=0;
							END -- end of block of the else -- (SELECT Qtyalloc from invt_res where invtres_no=@lcInvtres_no)<0 
						END	-- end of block for the IF (@lnQtyAlloc>@lnDelta)	
						ELSE -- (@lnQtyAlloc>@lnDelta)
						BEGIN
							-- 02/03/11 VL added code to create allocation record for the WO-WIP. (unallocate from original location, but need to allocate to the WO-WIP)
							-- will insert into invt_res after invtmfgr.qty_oh is updated
							--EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
							--INSERT INTO INVT_RES(W_KEY,[UNIQ_KEY],[DATETIME],[QTYALLOC],[WONO],[INVTRES_NO],[LOTCODE],[EXPDATE],[REFERENCE] ,[PONUM],[SAVEINIT] ,[FK_PRJUNIQUE] ,[SERIALNO],[SERIALUNIQ])
							--		 SELECT ToWkey,Uniq_key,GETDATE(),@lnQtyAlloc,
							--		CASE WHEN @lReservedWo=1 THEN @lcWono ELSE ' ' END,
							--		 @lcNewUniqNbr,LotCode,ExpDate,Reference,Ponum,Saveinit,
							--		  CASE WHEN @lReservedPrj=1 THEN @lcFk_PrjUnique ELSE ' ' END,
							--		  SerialNo,SerialUniq FROm Inserted
							
							-- 11/30/12 VL changed to save a record at a time
							--INSERT INTO @ZWo_WipAlloc (W_KEY,[UNIQ_KEY],[DATETIME],[QTYALLOC],[WONO],[INVTRES_NO],[LOTCODE],[EXPDATE],[REFERENCE],
							--		[PONUM],[SAVEINIT] ,[FK_PRJUNIQUE] ,[SERIALNO],[SERIALUNIQ],[Sono],[Uniqueln],[RefinvtRes])
							--		 SELECT ToWkey,Uniq_key,GETDATE(),@lnQtyAlloc,
							--		CASE WHEN @lReservedWo=1 THEN @lcWono ELSE ' ' END,
							--		 @lcNewUniqNbr,LotCode,ExpDate,Reference,Ponum,Saveinit,
							--		  CASE WHEN @lReservedPrj=1 THEN @lcFk_PrjUnique ELSE ' ' END,
							--		  SerialNo,SerialUniq, '' AS Sono,'' AS Uniqueln,'' AS RefinvtRes FROm Inserted

							-- 02/09/2017  Satish B : Remove cloumns :Serialno,SerialUniq,lIsFromSO as per new database structure
							INSERT INTO @ZWo_WipAlloc(W_KEY,[UNIQ_KEY],[DATETIME],[QTYALLOC],[WONO],[INVTRES_NO],[LOTCODE],[EXPDATE],[REFERENCE],
									[PONUM],[SAVEINIT] ,[FK_PRJUNIQUE] ,[Sono],[Uniqueln],[RefinvtRes]
									--,[SERIALNO]
									--,[SERIALUNIQ],[lIsFromSo]
									)
								VALUES 
								(@lcToWKey, @lcUniq_key, GETDATE(), @lnQtyAlloc, CASE WHEN @lReservedWo=1 THEN @lcWono ELSE ' ' END,
								dbo.fn_GenerateUniqueNumber(), @lcLotCode, @ltExpdate, @lcReference, @lcPonum, @lcSaveInit, 
								CASE WHEN @lReservedPrj=1 THEN @lcFk_PrjUnique ELSE ' ' END,  '','',''
								--@lcSerialno,
								--,@lcSerialUniq, @lIsFromSo
								)
							
							-- assign new lnDelta and remove allocation from the table
							SET @lnDelta=@lnDelta-@lnQtyAlloc;
							SET @lnUnreserved=@lnUnreserved+@lnQtyAlloc;
							DELETE FROM Invt_res WHERE Invtres_no=@lcInvtres_no 
						END	--ELSE -- (@lnQtyAlloc>@lnDelta)
					END  -- WHILE @lnDelta>0 loop in the allocation to project
				END -- if @@ROWCOUNT<>0 alllocated to project
			END --IF (@lnDelta>0) and (@lReservedPrj=1)
		END --IF (@lToWO_WIP=1 OR @lFromWO_WIP=1) AND (@lReservedWo=1 OR @lReservedPrj=1) AND (@lcModId<>'K' AND @lSkipUnallocCode=0)
		
		-- update from w_key location qty
		-- 04/30/12 VL found Reserved is not updated correctly, it should compare @lnUnreserved with real Reserved value
		--UPDATE Invtmfgr SET Qty_Oh=Qty_oh-@lnQtyThisTime, Reserved=Reserved-@lnUnreserved where w_key=@lcFromWKey;
		UPDATE Invtmfgr SET Qty_Oh = (Qty_oh - @lnQtyThisTime), 
							RESERVED = CASE WHEN @lnUnreserved <> 0 THEN CASE WHEN @lnUnreserved>RESERVED THEN 0 ELSE RESERVED - @lnUnreserved END ELSE RESERVED END
			WHERE W_key = @lcFromWKey;
			
			
		-- check if location needs to be removed
		SELECT @lnQty_oh=Qty_oh,@lnReserved=Reserved FROM Invtmfgr where w_key=@lcFromWKey;
		
		IF @lnQty_oh = 0
			BEGIN
				-- 11/30/12 VL changed to use a variable
				--IF (dbo.fRemoveLocation((Select Invtmfgr.UniqWh from Invtmfgr where Invtmfgr.W_key=@lcFromWKey),@lcUniqMfgrhd)=1)
				IF (dbo.fRemoveLocation(@lcFromWkeyUniqWh,@lcFromWkeyUniqMfgrhd)=1)
				BEGIN
					UPDATE InvtMfgr SET is_Deleted=1 WHERE W_key=@lcFromWKey;
				END	 -- (dbo.fRemoveLocation((Select Invtmfgr.UniqWh from Invtmfgr where Invtmfgr.W_key=@lcFromWKey),@lcUniqMfgrhd)=1)	
			END -- end of if @lnQty_oh = 0
		ELSE -- @lnQty_oh = 0
		BEGIN	
		IF @lnQty_oh < 0 or @lnReserved<0
		BEGIN
			--SET @lRollBack=1
			RAISERROR('No quantity available to issue. This operation will be cancelled.',1,1)
			ROLLBACK TRANSACTION
			RETURN
		END -- end of if @lnQty_oh < 0 or @lnReserved<0
		END-- end of else @lnQty_oh = 0
		
		-- 02/03/12 VL added to check if need to update MatlType in Invmfhd
		-- 11/30/12 VL changed to use variable, also added @lnQty_oh > 0 @lnReserved > 0 criteria
		--UPDATE Invtmfhd SET Is_Deleted = 0 WHERE UniqMfgrHd IN (SELECT UniqMfgrHD FROM INVTMFGR WHERE W_KEY=@lcFromWKey)
		--SELECT @lcMatlType = MatlType FROM INVTMFHD WHERE UNIQMFGRHD IN (SELECT UniqMfgrHD FROM INVTMFGR WHERE W_KEY=@lcFromWKey)
		--UPDATE Invtmfhd SET MatlType='Unk' WHERE MatlType NOT IN (SELECT AVLMATLTYPE FROM AvlMatlTp) 
		--									AND UniqMfgrHD IN (SELECT UniqMfgrHd FROM INVTMFGR WHERE W_KEY=@lcFromWKey)
		--10/09/14 YS removed invtmfhd table
		--UPDATE Invtmfhd SET Is_Deleted = 0 WHERE UniqMfgrHd = @lcFromWkeyUniqMfgrhd AND @lnQty_oh > 0 AND @lnReserved > 0

		UPDATE InvtMPNLink SET Is_Deleted = 0 WHERE UniqMfgrHd = @lcFromWkeyUniqMfgrhd AND @lnQty_oh > 0 AND @lnReserved > 0
		UPDATE MfgrMaster SET is_deleted = 0 WHERE MfgrMasterId IN 
			(SELECT MfgrMasterId 
					from InvtMPNLink L where L.UniqMfgrHd = @lcFromWkeyUniqMfgrhd AND l.is_deleted=0)

		--03/09/15 YS missed code for the matltype. Invtmfhd is removed. Assign @lcMatlType when assigning variables from mfgrmaster
		--SELECT @lcMatlType = MatlType FROM INVTMFHD WHERE UNIQMFGRHD = @lcFromWkeyUniqMfgrhd
		
		--10/09/14 YS removed invtmfhd table
		--UPDATE Invtmfhd SET MatlType='Unk' WHERE MatlType NOT IN (SELECT AVLMATLTYPE FROM AvlMatlTp) 
		--									AND UniqMfgrHD = @lcFromWkeyUniqMfgrhd
		
		UPDATE MfgrMaster SET MatlType='Unk' 
		FROM InvtMPNLink L WHERE L.MfgrMasterId= MfgrMaster.MfgrMasterId and L.UniqMfgrHD = @lcFromWkeyUniqMfgrhd
		AND MfgrMaster.MatlType NOT IN (SELECT AVLMATLTYPE FROM AvlMatlTp) 

		IF @@ROWCOUNT<>0
		BEGIN
			set @lcMatlType='Unk' 
			INSERT INTO UpdMatTpLog (UqMttpLog, Uniq_key, FromMatlType, ToMatlType, MtChgDt, MtChgInit) 
				VALUES (dbo.fn_GenerateUniqueNumber(), @lcUniq_key, @lcMatlType, 'Unk', GETDATE(), 'SYS')
		END

		IF (@lIsInStore=1) AND( @lFromInstore=1) AND (@lToInstore=0)
		BEGIN	
			--EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
			-- 11/30/12 VL changed to save record per inserted record
			--INSERT INTO POSTORE (UniqRecord,Date_isu,Uniq_key,UniqSupno,Qty_isu,Partmfgr,Mfgr_pt_no,LotCode,ExpDate,Reference,UsedBy,UniqMfgrHd,SerialNo,SerialUniq,UniqWh,Location) 
			--	SELECT @lcNewUniqNbr,CAST(GETDATE() as smalldatetime),M.Uniq_key,M.UniqSupNo,@lnQtyThisTime,H.PartMfgr,H.Mfgr_pt_no,
			--		I.LotCode,I.ExpDate,I.Reference,'In-store 2 Internal',M.UniqMfgrhd,I.Serialno,I.SerialUniq,M.Uniqwh,M.Location 
			--	FROM Invtmfgr M,Invtmfhd H,Inserted I WHERE M.W_key=I.FROMWkey and H.UniqMfgrhd=I.UniqMfgrhd; 

			-- 05/07/19 Shrikant changed --@lcSerialno, @lcSerialUniq to blank value to fixed the issue of while saving packing list consg xfer chnage throws error Cannot insert the value NULL into column 'serialno', table 'Broadcom_3165.dbo.POSTORE
			INSERT INTO POSTORE (UniqRecord,Date_isu,Uniq_key,UniqSupno,Qty_isu,Partmfgr,Mfgr_pt_no,LotCode,ExpDate,Reference,UsedBy,UniqMfgrHd,SerialNo,SerialUniq,UniqWh,Location) 
				VALUES (dbo.fn_GenerateUniqueNumber(),CAST(GETDATE() as smalldatetime),@lcUniq_key,@lcFromWkeyUniqSupno,@lnQtyThisTime,@lcPartMfgr,@lcMfgr_pt_no,
					@lcLotCode, @ltExpDate, @lcReference,'In-store 2 Internal',@lcFromWkeyUniqMfgrhd,
            '', '',@lcFromWkeyUniqWh,@lcFromLocation)  
	 --@lcSerialno, @lcSerialUniq
				
		 END --(@lIsInStore=1) AND( @lFromInstore=1) AND (@lToInstore=0)
		 -- 09/11/14 YS added code to check if from location is not in-store, but to location is. Should not allow to proceed
		 if (@lIsInStore=1) AND( @lFromInstore=0) AND (@lToInstore=1)
		 BEGIN
			RAISERROR('Cannot transfer from regular location to in-store location. This operation will be cancelled. Please try again',1,1)
			ROLLBACK TRANSACTION;
			RETURN;
			BREAK;
		 END

		IF (@lFromWO_WIP=1) and (@lcModId<>'U') --  transfer from wo-wip and not from kit update
		BEGIN
			-- need to update kit files
			-- 11/30/12 VL moved all these code to top, here only delete all records
			--DECLARE @zKamain Table (nRecno Int Identity,KaSeqNum char(10),Act_qty numeric(12,2),ShortQty Numeric(12,2))
			--DECLARE @zKaLocate TABLE (nRecno Int Identity,KaSeqNum char(10), OverW_key char(10),LotCode char(15),
			--		ExpDate SmallDatetime,Reference char(12),Ponum char(15),OverIssQty Numeric(12,2),UniqKalocate char(10))
			--DECLARE @lnDeltaOver Numeric(12,2)=0.00,@lnOverLeft Numeric(12,2)=0.00, @lnLocCount int=0
			-- 04/29/11 VL changed to get right kamain record if the invttrns record is from KIT module,
			-- found a problem that if user has more than one same part numbers for the WO, even user is editing
			-- the 2nd record, the code always update from the first one to scan and down
			-- 06/02/11 VL found the code only need to find right kamain if the wono of WO-WIP locatin the same as the @lcWono
			DELETE FROM @zKamain WHERE 1 = 1
			DELETE FROM @zKaLocate WHERE 1 = 1
			-- 11/30/12 VL added next to help reset counter
			SET @lnTableVarCnt2 = 0	
			
			SET @lnDeltaOver = 0.00
			SET @lnOverLeft = 0.00
			SET @lnLocCount = 0
			-- 02/12/14 VL found need to save wono that will be used when inserting Kadetail			
			IF @lcKaseqnum <> '' AND SUBSTRING(@lcFromLOCATION,3,10) = @lcWono
				INSERT INTO @zKamain 
					SELECT 0 AS nRecno, KaMain.KaSeqNum,KaMain.Act_qty,KaMain.ShortQty, Wono 
				FROM KaMain 
				WHERE Kamain.Kaseqnum = @lcKaseqnum
			ELSE
				INSERT INTO @zKamain
					SELECT 0 AS nRecno, KaMain.KaSeqNum,KaMain.Act_qty,KaMain.ShortQty, Wono
				FROM KaMain 
				WHERE Kamain.WONO=SUBSTRING(@lcFromLOCATION,3,10)
				AND Kamain.Uniq_key=@lcUniq_key									
			-- 04/26/11 VL End}
	
			UPDATE @zKamain SET @lnTableVarCnt2 = nRecno = @lnTableVarCnt2 + 1
			-- 11/30/12 VL End}
			
			-- 08/28/13 VL found somehow when assign @lnTotalCnt = @lnTableVarCnt2, @lnTotalCnt just didn't take the right value, decided just use @lnTableVarCnt2 directly
			SELECT @lnTotalCnt = @lnTableVarcnt2
			
			--IF @lnTotalCnt<>0
		
			IF @lnTableVarcnt2<>0
			BEGIN
				SET @lnDeltaOver = @lnQtyThisTime;
				set @lnCount=0;
				SET @lnReduceThisTime=0.00;
				-- 08/27/13 VL found the CONTINUE might cause endless loop, need to add one more criteria in WHILE to make it out of the loop if 
				
				-- 02/08/2017  Satish B : Kalocate and KalocSer tables are not exist in new database structute
				--WHILE @lnDeltaOver>0 AND @lnTableVarcnt2>@lnCount
				--BEGIN
				--	--11/30/12 VL reset the count
				--	SET @lnTableVarCnt = 0
				--	SET @lnCount=@lnCount+1

				--	INSERT INTO @zKaLocate 
				--		SELECT 0 AS nRecno, Km.KaSeqNum,Kalocate.OverW_key,Kalocate.LotCode,
				--		Kalocate.ExpDate,Kalocate.Reference,KaLocate.Ponum,KaLocate.OverIssQty,
				--		KaLocate.UniqKalocate 
				--		FROM @zKamain Km,Kalocate
				--		WHERE Km.nRecno=@lnCount 
				--		AND Kalocate.KaSeqNum=Km.KaSeqnUm
				--		AND KaLocate.OverW_key=@lcFromWKey
				--		AND Kalocate.LotCode=@lcLotCode
				--		AND KaLocate.Reference=@lcReference
				--		AND ISNULL(Kalocate.Expdate,1)=ISNULL(@ltExpdate,1)
				--		AND Kalocate.PoNum=@lcPonum
				--		AND Kalocate.OverIssQty>0
				--		ORDER BY OverIssQty DESC
						
				--	UPDATE @zKaLocate SET @lnTableVarCnt = nRecno = @lnTableVarCnt + 1
				--	-- 11/30/12 VL End}
						
				--	-- 05/19/11 VL end}
				
				
				--	-- 08/28/13 VL changed from checking @@ROWCOUNT>0 to @lnTableVarCnt > 0	
				--	IF	(@lnTableVarcnt=0)
				--	BEGIN
				--		-- 12/06/11 VL added code to make to next record in @Zkamain not just return false because maybe this kamain didn't have overissued qty, but next one has
				--		CONTINUE					
				--		--RAISERROR('No over-issued quantity found. This operation will be cancelled. Please try again',1,1)
				--		--ROLLBACK TRANSACTION;
				--		--RETURN;
				--		--BREAK;
				--	END	--(@@ROWCOUNT=0) in Kalocate for over-issued
				--	SET @lnLocCount=0
				--	-- 12/12/13 VL added one more criteria, only @lnDeltaOver>0 might cause endless loop
				--	WHILE @lnDeltaOver>0 AND @lnTableVarcnt>@lnLocCount
				--	BEGIN	
				--		SET @lnLocCount=@lnLocCount+1;
				--		-- 11/30/12 VL added to assign variable for UniqKalocate
				--		SELECT @lnOverLeft=
				--			CASE WHEN OverIssQty>=@lnDeltaOver THEN 0
				--			ELSE @lnDeltaOver-OverIssQty END,
				--			@lcChkUniqKalocate = UniqKalocate 
				--		FROM @zKaLocate where nRecno=@lnLocCount
				--		IF (@@ROWCOUNT<>0)
				--		BEGIN
				--			--@lcModid='C' - close kit
				--			--@lcModid='E' - manual shortage editing
				--			-- 11/30/12 VL changed to use @lcChkUniqKalocate
				--			UPDATE Kalocate SET OverIssQty=
				--				CASE WHEN Kalocate.OverIssQty>@lnDeltaOver THEN Kalocate.OverIssQty-@lnDeltaOver
				--				ELSE 0.00 END,
				--				OverW_key =
				--				CASE WHEN Kalocate.OverIssQty-@lnDeltaOver>0 THEN OverW_key ELSE ' ' END,
				--				Pick_qty = 
				--				CASE WHEN @lcModid='E' THEN Pick_Qty ELSE Pick_Qty-(@lnDeltaOver-@lnOverLeft) END
				--				WHERE Kalocate.UniqKalocate = @lcChkUniqKalocate
							
				--			-- {05/18/11 VL added code to delete kalocate if Pick_qty and OverIssQty are both 0
				--			-- 11/30/12 VL changed to use @lcChkUniqKalocate
				--			DELETE FROM Kalocate 
				--				WHERE UniqKalocate = @lcChkUniqKalocate
				--				AND Pick_qty = 0
				--				AND OverIssQty = 0
				--			-- 05/18/11 VL End}								
						
				--			SET @lnReduceThisTime=@lnReduceThisTime+@lnDeltaOver-@lnOverLeft ;
				--			SET @lnDeltaOver=@lnOverLeft ;
				--			IF (@lSerialYes=1) 
				--			BEGIN	
				--				-- 11/30/12 VL changed to use variable, not SELECT... FROM
				--				--DELETE FROM KalocSer WHERE UniqKaLocate IN (SELECT UniqKalocate FROM @zKaLocate  where nRecno=@lnLocCount) and
				--				--	Serialno IN (SELECT Serialno FROm Inserted) and Is_overissued=1
				--				DELETE FROM KalocSer WHERE UniqKaLocate = @lcChkUniqKalocate 
				--					AND	Serialno = @lcSerialno and Is_overissued=1

				--				IF @@ROWCOUNT=0
				--				BEGIN
				--					RAISERROR('Serial Number was not marked as Over issued. This operation will be cancelled. Please try again',1,1)
				--					ROLLBACK TRANSACTION;
				--					RETURN;
				--					BREAK;
				--				END	
				--			END -- @lSerialYes=1
				--		END -- @@ROWCOUNT<>0 in  SELECT @lnOverLeft...	
				--	END --WHILE @lnDeltaOver>0
				--END -- while @lnDelta>0
			
		
			-- 12/03/12 VL found need to move next END to lower place, after updatig Kamain
			--END -- @@ ROWCOUNT<>0 @ZKamain
				IF @lnReduceThisTime<>0.00
				BEGIN
					-- update kamain
					UPDATE KaMain SET Act_qty =
						CASE WHEN @lcModId<>'E' THEN Act_qty-@lnReduceThisTime ELSE Act_qty END,
						ShortQty = ShortQty+@lnReduceThisTime WHERE KaSeqnum IN (SELECT KaSeqNum from @zKamain where nRecno=@lnCount)

					-- 05/19/11 VL added Wono field and UniqueRec, also added @lcModId <>'K', inside of Kit form will update
					IF @lcModId <> 'K' AND @lcModId <> 'E'
					BEGIN
						--EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
						-- 02/12/14 use @zKamain.Wono, not @lcWono
						INSERT INTO KaDetail (KaSeqNum,ShReason,ShortQty,ShQualify,
									ShortBal,AuditDate,AuditBy, UniqueRec, Wono) SELECT 
									KaSeqNum,'Issue', @lnReduceThisTime,'EDT',
									ShortQty,GETDATE(),@lcSaveInit, dbo.fn_GenerateUniqueNumber(), Wono from @zKamain where nRecno=@lnCount
					END			
				END -- @lnReducethistime<>0.00
			END -- @@ ROWCOUNT<>0 @ZKamain
		END -- IF (@lFromWO_WIP=1) and (@lcModId<>'U')
		
		-- 11/30/12 VL changed to following what was set up for this part
		--IF (SELECT LotCode FROM INSERTED)<>' '
		IF @llLotDetail = 1
		BEGIN
			-- 11/29/12 VL found if now @llLotDetail = 1 but @lcLotCode= '', has to give dummy invlot info
			IF @lcLotCode = ''
			BEGIN
				SET @lcLotCode = CAST(CONVERT(DATE,GETDATE()) AS CHAR(10)) ;
				SET @ltExpDate = NULL
				SET @lcReference = 'LOT' + RIGHT(dbo.fn_GenerateUniqueNumber(),9)
				SET @lcPonum = 'UNKNOWN'
			END				
			-- 11/29/12 VL End}			
			-- 11/30/12 VL changed to save one record at a time
			--SELECT @lnLotQty=LotQty,@lnLotResQty=LotResQty FROM InvtLot 
			--	WHERE EXISTS (SELECT 1 FROM Inserted where Invtlot.W_key=Inserted.FromWkey and
			--			InvtLot.LotCode=Inserted.LotCode and ISNULL(InvtLot.ExpDate,1)=ISNULL(Inserted.ExpDate,1)
			--			AND InvtLot.Reference=Inserted.Reference and Invtlot.Ponum=Inserted.Ponum)
			--02/24/2020 Nitesh B Modify trigger for sfbl warehouse 
			SELECT @lnLotQty=LotQty,@lnLotResQty=LotResQty FROM InvtLot 
				WHERE Invtlot.W_key = CASE WHEN (SELECT SFBL FROM INVTMFGR WHERE W_KEY=@lcFromWkey AND SFBL=1) = 1 THEN @lcToWKey ELSE @lcFromWkey END  
				AND InvtLot.LotCode=@lcLotCode
				AND ISNULL(InvtLot.ExpDate,1)=ISNULL(@ltExpDate,1)
				AND InvtLot.Reference=@lcReference
				AND Invtlot.Ponum=@lcPonum
								
			IF (@lnLotQty < @lnQTYTHISTIME) 
			BEGIN
				RAISERROR('No enough LOT quantities to issue. This operation will be cancelled. Please try again',1,1)
				ROLLBACK TRANSACTION;
				RETURN;
			END	--@lnLotQty<@lnQTYTHISTIME and @lnQTYTHISTIME>0
			IF (@lnLotQty - @lnQTYTHISTIME)<(@lnLotResQty - @lnUnReserved) 
			BEGIN
				RAISERROR('Cannot reduce LOT quantities below allocated. This operation will be cancelled. Please try again',1,1)
				ROLLBACK TRANSACTION;
				RETURN;
			END	-- (@lnLotQty-@lnQTYTHISTIME)<(@lnLotResQty-@lnUnReserved) and (@lnQTYTHISTIME>0)
			IF (@lnLotResQty<@lnUnReserved) 
			BEGIN
				RAISERROR('Cannot reduce LOT quantities reserved below zero. This operation will be cancelled. Please try again',1,1)
				ROLLBACK TRANSACTION;
				RETURN;
			END	--(@lnLotResQty<@lnUnReserved) and (@lnQTYTHISTIME>0)
		  
			--11/30/12 VL chaned to save a record at a time
			--UPDATE InvtLot SET LotQty = LotQty-@lnQTYTHISTIME,
			--				LotResQty =LotResQty-@lnUnreserved WHERE EXISTS (SELECT 1 FROM Inserted where Invtlot.W_key=Inserted.FROMWkey and
			--			InvtLot.LotCode=Inserted.LotCode and ISNULL(InvtLot.ExpDate,1)=ISNULL(Inserted.ExpDate,1)
			--			AND InvtLot.Reference=Inserted.Reference and Invtlot.Ponum=Inserted.Ponum)
			UPDATE InvtLot SET LotQty = (LotQty - @lnQTYTHISTIME),
							LotResQty =LotResQty-@lnUnreserved 
				WHERE Invtlot.W_key=@lcFROMWkey
				AND InvtLot.LotCode=@lcLotCode
				AND ISNULL(InvtLot.ExpDate,1)=ISNULL(@ltExpDate,1)
				AND InvtLot.Reference=@lcReference
				AND Invtlot.Ponum=@lcPonum
			
			-- remove lot code with 0 qty				
			DELETE FROM InvtLot WHERE LotQty=0.00 and LotResQty=0.00
		END --(SELECT LotCode FROM INSERTED)<>' '
		
		-- update "to" mfgr
		UPDATE Invtmfgr SET QTY_oh = (Qty_oh + @lnQTYTHISTIME),
							Is_deleted=0 WHERE W_key = @lcToWKey
		-- 11/30/12 VL changed to use variable
		--IF (SELECT LotCode FROM INSERTED)<>' '
		IF @llLotDetail = 1						
		BEGIN
			-- 11/29/12 VL found if now @llLotDetail = 1 but @lcLotCode= '', has to give dummy invlot info
			IF @lcLotCode = ''
			BEGIN
				SET @lcLotCode = CAST(CONVERT(DATE,GETDATE()) AS CHAR(10)) ;
				SET @ltExpDate = NULL
				SET @lcReference = 'LOT' + RIGHT(dbo.fn_GenerateUniqueNumber(),9)
				SET @lcPonum = 'UNKNOWN'
			END				
			-- 11/29/12 VL End}			
			-- 11/30/12 VL changed to save a record at a time
			--SELECT @lcToUniqLot	= InvtLot.Uniq_lot FROM InvtLot,Inserted WHERE InvtLot.W_key=@lcToWKey and 
			--		InvtLot.LotCode=Inserted.LotCode and ISNULL(InvtLot.ExpDate,1)=ISNULL(Inserted.ExpDate,1) and InvtLot.Reference=Inserted.Reference AND InvtLot.Ponum=Inserted.Ponum	
			
			SELECT @lcToUniqLot	= InvtLot.Uniq_lot 
				FROM InvtLot
				WHERE InvtLot.W_key=@lcToWKey
				AND InvtLot.LotCode=@lcLotCode
				AND ISNULL(InvtLot.ExpDate,1)=ISNULL(@ltExpDate,1)
				AND InvtLot.Reference=@lcReference
				AND InvtLot.Ponum=@lcPonum	
			
			IF @@ROWCOUNT<>0
				UPDATE InvtLot SET LotQty= (LotQty + @lnQTYTHISTIME) WHERE Uniq_lot=@lcToUniqLot
			ELSE
			BEGIN
				--EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
				-- 11/30/12 VL changed to save variable not select from inserted
				--INSERT INTO InvtLot (W_key,LotCode,ExpDate,LotQty,Reference,Ponum,Uniq_lot) 
				--SELECT ToWkey,LotCode,ExpDate,@lnQtyThisTime,Reference,Ponum,@lcNewUniqNbr FROM Inserted
				INSERT INTO InvtLot (W_key,LotCode,ExpDate,LotQty,Reference,Ponum,Uniq_lot) 
					VALUES(@lcToWKey, @lcLotCode, @ltExpdate, @lnQtyThisTime, @lcReference, @lcPonum, dbo.fn_GenerateUniqueNumber())
				
			END	-- IF @@ROWCOUNT<>0 in invtlot			
		END -- (SELECT LotCode FROM INSERTED)<>' '
		-- 08/07/14 YS added code to check if from new ipkey (cloud) development, serial numbers will be entered into a different table
		-- 04/05/2017  Satish B : We Insert Serial Numbers in iTransferSerial table (We are not inserting SerialUniq in INVTTRNS table)
		--IF @lSerialYes=1 and @sourceDev<>'I'
		--BEGIN
		--	UPDATE InvtSer SET ID_KEY='W_KEY',
		--					ID_VALUE=@lcToWKey,
		--					Uniq_lot=@lcToUniqLot
		--					where Serialuniq=@lcSerialUniq
		--	IF @@ROWCOUNT=0
		--	BEGIN				
		--		RAISERROR('Record is missing from INVTSER table. This operation will be cancelled.',1,1)
		--		ROLLBACK TRANSACTION;
		--		RETURN;
		--	END 	-- @@ROWCOUNT=0 could not find serial number record					
		--END --@lSerialYes and and @sourceDev<>'I'
	
		-- 12/03/12 VL moved to bottom
		-- 02/15/12 VL added code to insert into invt_res from @ZWO_WIPAlloc
		--INSERT INVT_RES SELECT * FROM @ZWO_WIPAlloc
		-- 08/16/10 YS use function get gl_nbr_inv
		
		UPDATE Invttrns SET Gl_nbr_inv=
				CASE WHEN @lcPart_sourc='CONSG' THEN ' ' 
				WHEN @lIsInStore=1 and @lToInStore=1 AND @lFromInStore=1 THEN ' '
				WHEN @lIsInStore=1 and @lToInStore=1 THEN ' '
				--10/14/13 YS added variable to store in-store gl, when transfer from in-store to none-instore location
				WHEN @lIsInStore=1 and @lFromInStore=1 and @lToInStore=0 THEN @lcInStoreGlNbr 
				ELSE dbo.fn_GETINVGLNBR(Invttrns.FromWKey,'T',0) END,
				Gl_nbr=
				CASE WHEN @lcPart_sourc='CONSG' THEN ' ' 
				WHEN @lIsInStore=1 and @lToInStore=1 AND @lFromInStore=1 THEN ' '
				WHEN @lIsInStore=1 and @lToInStore=1 THEN ' '
				ELSE dbo.fn_GETINVGLNBR(Invttrns.TOWKEY,'T',0) END
		WHERE Invttrns.Invtxfer_n = @lcInvtxfer_n		
		END	-- End of WHILE @lnTotalCount> @lnCnt	

		

    END -- End of @lnTotalCount <> 0	
	-- 11/30/12 VL End				
 
	-- 02/15/12 VL added code to insert into invt_res from @ZWO_WIPAlloc

	--INSERT INVT_RES SELECT * FROM @ZWO_WIPAlloc
	
	COMMIT	
END -- end of the insert trigger