CREATE TABLE [dbo].[INVENTOR] (
    [UNIQ_KEY]              CHAR (10)        CONSTRAINT [DF__INVENTOR__UNIQ_K__50F0E28A] DEFAULT ('') NOT NULL,
    [PART_CLASS]            CHAR (8)         CONSTRAINT [DF__INVENTOR__PART_C__51E506C3] DEFAULT ('') NOT NULL,
    [PART_TYPE]             CHAR (8)         CONSTRAINT [DF__INVENTOR__PART_T__52D92AFC] DEFAULT ('') NOT NULL,
    [CUSTNO]                CHAR (10)        CONSTRAINT [DF__INVENTOR__CUSTNO__53CD4F35] DEFAULT ('') NOT NULL,
    [PART_NO]               CHAR (35)        CONSTRAINT [DF__INVENTOR__PART_N__54C1736E] DEFAULT ('') NOT NULL,
    [REVISION]              CHAR (8)         CONSTRAINT [DF__INVENTOR__REVISI__55B597A7] DEFAULT ('') NOT NULL,
    [PROD_ID]               CHAR (10)        CONSTRAINT [DF__INVENTOR__PROD_I__56A9BBE0] DEFAULT ('') NOT NULL,
    [CUSTPARTNO]            CHAR (35)        CONSTRAINT [DF__INVENTOR__CUSTPA__579DE019] DEFAULT ('') NOT NULL,
    [CUSTREV]               CHAR (8)         CONSTRAINT [DF__INVENTOR__CUSTRE__58920452] DEFAULT ('') NOT NULL,
    [DESCRIPT]              CHAR (45)        CONSTRAINT [DF__INVENTOR__DESCRI__5986288B] DEFAULT ('') NOT NULL,
    [U_OF_MEAS]             CHAR (4)         CONSTRAINT [DF__INVENTOR__U_OF_M__5A7A4CC4] DEFAULT ('') NOT NULL,
    [PUR_UOFM]              CHAR (4)         CONSTRAINT [DF__INVENTOR__PUR_UO__5B6E70FD] DEFAULT ('') NOT NULL,
    [ORD_POLICY]            CHAR (12)        CONSTRAINT [DF__INVENTOR__ORD_PO__5C629536] DEFAULT ('') NOT NULL,
    [PACKAGE]               CHAR (15)        CONSTRAINT [DF__INVENTOR__PACKAG__5D56B96F] DEFAULT ('') NOT NULL,
    [NO_PKG]                NUMERIC (5)      CONSTRAINT [DF__INVENTOR__NO_PKG__5E4ADDA8] DEFAULT ((0)) NOT NULL,
    [INV_NOTE]              TEXT             CONSTRAINT [DF__INVENTOR__INV_NO__5F3F01E1] DEFAULT ('') NOT NULL,
    [BUYER_TYPE]            CHAR (3)         CONSTRAINT [DF__INVENTOR__BUYER___6033261A] DEFAULT ('') NOT NULL,
    [STDCOST]               NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__STDCOS__61274A53] DEFAULT ((0)) NOT NULL,
    [MINORD]                NUMERIC (7)      CONSTRAINT [DF__INVENTOR__MINORD__621B6E8C] DEFAULT ((0)) NOT NULL,
    [ORDMULT]               NUMERIC (7)      CONSTRAINT [DF__INVENTOR__ORDMUL__630F92C5] DEFAULT ((0)) NOT NULL,
    [USERCOST]              NUMERIC (11, 5)  CONSTRAINT [DF__INVENTOR__USERCO__6403B6FE] DEFAULT ((0)) NOT NULL,
    [PULL_IN]               NUMERIC (3)      CONSTRAINT [DF__INVENTOR__PULL_I__64F7DB37] DEFAULT ((0)) NOT NULL,
    [PUSH_OUT]              NUMERIC (3)      CONSTRAINT [DF__INVENTOR__PUSH_O__65EBFF70] DEFAULT ((0)) NOT NULL,
    [PTLENGTH]              NUMERIC (7, 3)   CONSTRAINT [DF__INVENTOR__PTLENG__66E023A9] DEFAULT ((0)) NOT NULL,
    [PTWIDTH]               NUMERIC (7, 3)   CONSTRAINT [DF__INVENTOR__PTWIDT__67D447E2] DEFAULT ((0)) NOT NULL,
    [PTDEPTH]               NUMERIC (7, 3)   CONSTRAINT [DF__INVENTOR__PTDEPT__68C86C1B] DEFAULT ((0)) NOT NULL,
    [FGINOTE]               TEXT             CONSTRAINT [DF__INVENTOR__FGINOT__69BC9054] DEFAULT ('') NOT NULL,
    [STATUS]                CHAR (8)         CONSTRAINT [DF__INVENTOR__STATUS__6AB0B48D] DEFAULT ('') NOT NULL,
    [PERPANEL]              NUMERIC (4)      CONSTRAINT [DF__INVENTOR__PERPAN__6BA4D8C6] DEFAULT ((0)) NOT NULL,
    [ABC]                   CHAR (1)         CONSTRAINT [DF__INVENTOR__ABC__6C98FCFF] DEFAULT ('') NOT NULL,
    [LAYER]                 CHAR (4)         CONSTRAINT [DF__INVENTOR__LAYER__6D8D2138] DEFAULT ('') NOT NULL,
    [PTWT]                  NUMERIC (9, 2)   CONSTRAINT [DF__INVENTOR__PTWT__6E814571] DEFAULT ((0)) NOT NULL,
    [GROSSWT]               NUMERIC (9, 2)   CONSTRAINT [DF__INVENTOR__GROSSW__6F7569AA] DEFAULT ((0)) NOT NULL,
    [REORDERQTY]            NUMERIC (7)      CONSTRAINT [DF__INVENTOR__REORDE__70698DE3] DEFAULT ((0)) NOT NULL,
    [REORDPOINT]            NUMERIC (7)      CONSTRAINT [DF__INVENTOR__REORDP__715DB21C] DEFAULT ((0)) NOT NULL,
    [PART_SPEC]             CHAR (100)       CONSTRAINT [DF__INVENTOR__PART_S__7251D655] DEFAULT ('') NOT NULL,
    [PUR_LTIME]             NUMERIC (3)      CONSTRAINT [DF__INVENTOR__PUR_LT__7345FA8E] DEFAULT ((0)) NOT NULL,
    [PUR_LUNIT]             CHAR (2)         CONSTRAINT [DF__INVENTOR__PUR_LU__743A1EC7] DEFAULT ('') NOT NULL,
    [KIT_LTIME]             NUMERIC (3)      CONSTRAINT [DF__INVENTOR__KIT_LT__752E4300] DEFAULT ((0)) NOT NULL,
    [KIT_LUNIT]             CHAR (2)         CONSTRAINT [DF__INVENTOR__KIT_LU__76226739] DEFAULT ('') NOT NULL,
    [PROD_LTIME]            NUMERIC (3)      CONSTRAINT [DF__INVENTOR__PROD_L__77168B72] DEFAULT ((0)) NOT NULL,
    [PROD_LUNIT]            CHAR (2)         CONSTRAINT [DF__INVENTOR__PROD_L__780AAFAB] DEFAULT ('') NOT NULL,
    [UDFFIELD1]             CHAR (10)        CONSTRAINT [DF__INVENTOR__UDFFIE__78FED3E4] DEFAULT ('') NOT NULL,
    [WT_AVG]                NUMERIC (10, 2)  CONSTRAINT [DF__INVENTOR__WT_AVG__79F2F81D] DEFAULT ((0)) NOT NULL,
    [PART_SOURC]            CHAR (10)        CONSTRAINT [DF__INVENTOR__PART_S__7AE71C56] DEFAULT ('') NOT NULL,
    [INSP_REQ]              BIT              CONSTRAINT [DF__INVENTOR__INSP_R__7BDB408F] DEFAULT ((0)) NOT NULL,
    [CERT_REQ]              BIT              CONSTRAINT [DF__INVENTOR__CERT_R__7CCF64C8] DEFAULT ((0)) NOT NULL,
    [CERT_TYPE]             CHAR (10)        CONSTRAINT [DF__INVENTOR__CERT_T__7DC38901] DEFAULT ('') NOT NULL,
    [SCRAP]                 NUMERIC (6, 2)   CONSTRAINT [DF__INVENTOR__SCRAP__7EB7AD3A] DEFAULT ((0)) NOT NULL,
    [SETUPSCRAP]            NUMERIC (4)      CONSTRAINT [DF__INVENTOR__SETUPS__7FABD173] DEFAULT ((0)) NOT NULL,
    [OUTSNOTE]              TEXT             CONSTRAINT [DF__INVENTOR__OUTSNO__009FF5AC] DEFAULT ('') NOT NULL,
    [BOM_STATUS]            CHAR (10)        CONSTRAINT [DF__INVENTOR__BOM_ST__019419E5] DEFAULT ('') NOT NULL,
    [BOM_NOTE]              TEXT             CONSTRAINT [DF__INVENTOR__BOM_NO__02883E1E] DEFAULT ('') NOT NULL,
    [BOM_LASTDT]            SMALLDATETIME    NULL,
    [SERIALYES]             BIT              CONSTRAINT [DF__INVENTOR__SERIAL__037C6257] DEFAULT ((0)) NOT NULL,
    [LOC_TYPE]              CHAR (10)        CONSTRAINT [DF__INVENTOR__LOC_TY__04708690] DEFAULT ('') NOT NULL,
    [DAY]                   NUMERIC (1)      CONSTRAINT [DF__INVENTOR__DAY__0564AAC9] DEFAULT ((0)) NOT NULL,
    [DAYOFMO]               NUMERIC (2)      CONSTRAINT [DF__INVENTOR__DAYOFM__0658CF02] DEFAULT ((0)) NOT NULL,
    [DAYOFMO2]              NUMERIC (2)      CONSTRAINT [DF__INVENTOR__DAYOFM__074CF33B] DEFAULT ((0)) NOT NULL,
    [SALETYPEID]            CHAR (10)        CONSTRAINT [DF__INVENTOR__SALETY__08411774] DEFAULT ('') NOT NULL,
    [FEEDBACK]              TEXT             CONSTRAINT [DF__INVENTOR__FEEDBA__09353BAD] DEFAULT ('') NOT NULL,
    [ENG_NOTE]              TEXT             CONSTRAINT [DF__INVENTOR__ENG_NO__0B1D841F] DEFAULT ('') NOT NULL,
    [BOMCUSTNO]             CHAR (10)        CONSTRAINT [DF__INVENTOR__BOMCUS__0C11A858] DEFAULT ('') NOT NULL,
    [LABORCOST]             NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__LABORC__0D05CC91] DEFAULT ((0)) NOT NULL,
    [INT_UNIQ]              CHAR (10)        CONSTRAINT [DF__INVENTOR__INT_UN__0DF9F0CA] DEFAULT ('') NOT NULL,
    [EAU]                   NUMERIC (14)     CONSTRAINT [DF__INVENTOR__EAU__0EEE1503] DEFAULT ((0)) NOT NULL,
    [REQUIRE_SN]            BIT              CONSTRAINT [DF__INVENTOR__REQUIR__0FE2393C] DEFAULT ((0)) NOT NULL,
    [OHCOST]                NUMERIC (8, 2)   CONSTRAINT [DF__INVENTOR__OHCOST__10D65D75] DEFAULT ((0)) NOT NULL,
    [PHANT_MAKE]            BIT              CONSTRAINT [DF__INVENTOR__PHANT___11CA81AE] DEFAULT ((0)) NOT NULL,
    [CNFGCUSTNO]            CHAR (10)        CONSTRAINT [DF__INVENTOR__CNFGCU__12BEA5E7] DEFAULT ('') NOT NULL,
    [CONFGDATE]             SMALLDATETIME    NULL,
    [CONFGNOTE]             TEXT             CONSTRAINT [DF__INVENTOR__CONFGN__13B2CA20] DEFAULT ('') NOT NULL,
    [XFERDATE]              SMALLDATETIME    NULL,
    [XFERBY]                CHAR (8)         CONSTRAINT [DF__INVENTOR__XFERBY__14A6EE59] DEFAULT ('') NOT NULL,
    [PRODTPUNIQ]            CHAR (10)        CONSTRAINT [DF__INVENTOR__PRODTP__159B1292] DEFAULT ('') NOT NULL,
    [MRP_CODE]              NUMERIC (2)      CONSTRAINT [DF__INVENTOR__MRP_CO__168F36CB] DEFAULT ((0)) NOT NULL,
    [MAKE_BUY]              BIT              CONSTRAINT [DF__INVENTOR__MAKE_B__17835B04] DEFAULT ((0)) NOT NULL,
    [LABOR_OH]              NUMERIC (8, 2)   CONSTRAINT [DF__INVENTOR__LABOR___18777F3D] DEFAULT ((0)) NOT NULL,
    [MATL_OH]               NUMERIC (8, 2)   CONSTRAINT [DF__INVENTOR__MATL_O__196BA376] DEFAULT ((0)) NOT NULL,
    [MATL_COST]             NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__MATL_C__1A5FC7AF] DEFAULT ((0)) NOT NULL,
    [OVERHEAD]              NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__OVERHE__1B53EBE8] DEFAULT ((0)) NOT NULL,
    [OTHER_COST]            NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__OTHER___1C481021] DEFAULT ((0)) NOT NULL,
    [STDBLDQTY]             NUMERIC (8)      CONSTRAINT [DF__INVENTOR__STDBLD__1D3C345A] DEFAULT ((0)) NOT NULL,
    [USESETSCRP]            BIT              CONSTRAINT [DF__INVENTOR__USESET__1E305893] DEFAULT ((0)) NOT NULL,
    [CONFIGCOST]            NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__CONFIG__1F247CCC] DEFAULT ((0)) NOT NULL,
    [OTHERCOST2]            NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__OTHERC__2018A105] DEFAULT ((0)) NOT NULL,
    [MATDT]                 SMALLDATETIME    NULL,
    [LABDT]                 SMALLDATETIME    NULL,
    [OHDT]                  SMALLDATETIME    NULL,
    [OTHDT]                 SMALLDATETIME    NULL,
    [OTH2DT]                SMALLDATETIME    NULL,
    [STDDT]                 SMALLDATETIME    NULL,
    [ARCSTAT]               CHAR (8)         CONSTRAINT [DF__INVENTOR__ARCSTA__210CC53E] DEFAULT ('') NOT NULL,
    [IS_NCNR]               BIT              CONSTRAINT [DF__INVENTOR__IS_NCN__2200E977] DEFAULT ((0)) NOT NULL,
    [TOOLREL]               BIT              CONSTRAINT [DF__INVENTOR__TOOLRE__22F50DB0] DEFAULT ((0)) NOT NULL,
    [TOOLRELDT]             SMALLDATETIME    NULL,
    [TOOLRELINT]            CHAR (8)         CONSTRAINT [DF__INVENTOR__TOOLRE__23E931E9] DEFAULT ('') NOT NULL,
    [PDMREL]                BIT              CONSTRAINT [DF__INVENTOR__PDMREL__24DD5622] DEFAULT ((0)) NOT NULL,
    [PDMRELDT]              SMALLDATETIME    NULL,
    [PDMRELINT]             CHAR (8)         CONSTRAINT [DF__INVENTOR__PDMREL__25D17A5B] DEFAULT ('') NOT NULL,
    [ITEMLOCK]              BIT              CONSTRAINT [DF__INVENTOR__ITEMLO__26C59E94] DEFAULT ((0)) NOT NULL,
    [LOCKDT]                SMALLDATETIME    NULL,
    [LASTCHANGEDT]          SMALLDATETIME    NULL,
    [LASTCHANGEINIT]        NVARCHAR (256)   NULL,
    [BOMLOCK]               BIT              CONSTRAINT [DF__INVENTOR__BOMLOC__29A20B3F] DEFAULT ((0)) NOT NULL,
    [BOMLOCKINIT]           NVARCHAR (256)   NULL,
    [BOMLOCKDT]             SMALLDATETIME    NULL,
    [BOMLASTINIT]           NVARCHAR (256)   NULL,
    [ROUTREL]               BIT              CONSTRAINT [DF__INVENTOR__ROUTRE__2C7E77EA] DEFAULT ((0)) NOT NULL,
    [ROUTRELDT]             SMALLDATETIME    NULL,
    [ROUTRELINT]            CHAR (8)         CONSTRAINT [DF__INVENTOR__ROUTRE__2D729C23] DEFAULT ('') NOT NULL,
    [TARGETPRICE]           NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__TARGET__2E66C05C] DEFAULT ((0)) NOT NULL,
    [FIRSTARTICLE]          BIT              CONSTRAINT [DF__INVENTOR__FIRSTA__2F5AE495] DEFAULT ((0)) NOT NULL,
    [MRC]                   CHAR (15)        CONSTRAINT [DF__INVENTOR__MRC__304F08CE] DEFAULT ('') NOT NULL,
    [TARGETPRICEDT]         SMALLDATETIME    NULL,
    [PPM]                   NUMERIC (3)      CONSTRAINT [DF__INVENTOR__PPM__31432D07] DEFAULT ((0)) NOT NULL,
    [MATLTYPE]              CHAR (10)        CONSTRAINT [DF__INVENTOR__MATLTY__32375140] DEFAULT ('') NOT NULL,
    [NEWITEMDT]             SMALLDATETIME    CONSTRAINT [DF_INVENTOR_NEWITEMDT] DEFAULT (getdate()) NULL,
    [BOMINACTDT]            SMALLDATETIME    NULL,
    [BOMINACTINIT]          CHAR (8)         CONSTRAINT [DF__INVENTOR__BOMINA__332B7579] DEFAULT ('') NULL,
    [MTCHGDT]               SMALLDATETIME    NULL,
    [MTCHGINIT]             CHAR (8)         CONSTRAINT [DF__INVENTOR__MTCHGI__341F99B2] DEFAULT ('') NULL,
    [BOMITEMARC]            BIT              CONSTRAINT [DF__INVENTOR__BOMITE__3513BDEB] DEFAULT ((0)) NOT NULL,
    [CNFGITEMARC]           BIT              CONSTRAINT [DF__INVENTOR__CNFGIT__3607E224] DEFAULT ((0)) NOT NULL,
    [C_LOG]                 TEXT             CONSTRAINT [DF__INVENTOR__C_LOG__36FC065D] DEFAULT ('') NOT NULL,
    [importid]              UNIQUEIDENTIFIER CONSTRAINT [DF_INVENTOR_importid] DEFAULT (NULL) NULL,
    [useipkey]              BIT              CONSTRAINT [DF_INVENTOR_useipkey] DEFAULT ((0)) NOT NULL,
    [TechnicalDataSheetReq] BIT              CONSTRAINT [DF_INVENTOR_TechnicalDataSheetReq] DEFAULT ((0)) NOT NULL,
    [CalibrationReq]        BIT              CONSTRAINT [DF_INVENTOR_CalibrationReq] DEFAULT ((0)) NOT NULL,
    [Polarized]             BIT              CONSTRAINT [DF_INVENTOR_Polarized] DEFAULT ((0)) NOT NULL,
    [IsSynchronizedFlag]    BIT              CONSTRAINT [DF_INVENTOR_isSync] DEFAULT ((0)) NOT NULL,
    [IsBomSynchronized]     BIT              CONSTRAINT [DF_INVENTOR_IsBomSynchronized] DEFAULT ((0)) NOT NULL,
    [Taxable]               BIT              CONSTRAINT [DF_INVENTOR_Taxable] DEFAULT ((0)) NOT NULL,
    [lblSize]               VARCHAR (50)     CONSTRAINT [DF_INVENTOR_lblSize] DEFAULT ('') NOT NULL,
    [STDCOSTPR]             NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__STDCOS__166846F5] DEFAULT ((0)) NOT NULL,
    [USERCOSTPR]            NUMERIC (11, 5)  CONSTRAINT [DF__INVENTOR__USERCO__175C6B2E] DEFAULT ((0)) NOT NULL,
    [LABORCOSTPR]           NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__LABORC__18508F67] DEFAULT ((0)) NOT NULL,
    [OHCOSTPR]              NUMERIC (8, 2)   CONSTRAINT [DF__INVENTOR__OHCOST__1944B3A0] DEFAULT ((0)) NOT NULL,
    [MATL_COSTPR]           NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__MATL_C__1A38D7D9] DEFAULT ((0)) NOT NULL,
    [OVERHEADPR]            NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__OVERHE__1B2CFC12] DEFAULT ((0)) NOT NULL,
    [OTHER_COSTPR]          NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__OTHER___1C21204B] DEFAULT ((0)) NOT NULL,
    [CONFIGCOSTPR]          NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__CONFIG__1D154484] DEFAULT ((0)) NOT NULL,
    [OTHERCOST2PR]          NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__OTHERC__1E0968BD] DEFAULT ((0)) NOT NULL,
    [TARGETPRICEPR]         NUMERIC (13, 5)  CONSTRAINT [DF__INVENTOR__TARGET__1EFD8CF6] DEFAULT ((0)) NOT NULL,
    [FUNCFCUSED_UNIQ]       CHAR (10)        CONSTRAINT [DF__INVENTOR__FUNCFC__1FF1B12F] DEFAULT ('') NOT NULL,
    [PRFCUSED_UNIQ]         CHAR (10)        CONSTRAINT [DF__INVENTOR__PRFCUS__20E5D568] DEFAULT ('') NOT NULL,
    [ITAR]                  BIT              CONSTRAINT [DF_INVENTOR_iTar] DEFAULT ((0)) NOT NULL,
    [RoutingEditedBy]       NVARCHAR (256)   NULL,
    [RoutingEditedDate]     DATETIME         CONSTRAINT [DF__INVENTOR__Routin__4C7A3EE3] DEFAULT (getdate()) NOT NULL,
    [AspnetBuyer]           UNIQUEIDENTIFIER CONSTRAINT [DF__INVENTOR__Aspnet__3C98DCD5] DEFAULT ('00000000-0000-0000-0000-000000000000') NOT NULL,
    [LastChangeUserId]      UNIQUEIDENTIFIER NULL,
    [LOCKINIT]              UNIQUEIDENTIFIER NULL,
    CONSTRAINT [INVENTOR_PK] PRIMARY KEY CLUSTERED ([UNIQ_KEY] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CONSGPART]
    ON [dbo].[INVENTOR]([CUSTPARTNO] ASC, [CUSTREV] ASC, [CUSTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [CUSTPARTNO]
    ON [dbo].[INVENTOR]([CUSTPARTNO] ASC, [CUSTREV] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [CUSTREF]
    ON [dbo].[INVENTOR]([INT_UNIQ] ASC, [CUSTNO] ASC) WHERE ([Int_uniq]<>' ' AND [Custno]<>' ');


GO
CREATE NONCLUSTERED INDEX [INT_UNIQ]
    ON [dbo].[INVENTOR]([INT_UNIQ] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [INVENTOR]
    ON [dbo].[INVENTOR]([PART_NO] ASC, [REVISION] ASC, [PROD_ID] ASC, [CUSTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [InvtReordQtyReordPt]
    ON [dbo].[INVENTOR]([REORDERQTY] ASC, [REORDPOINT] ASC)
    INCLUDE([UNIQ_KEY], [PART_CLASS], [PART_TYPE], [CUSTNO], [PART_NO], [REVISION], [CUSTPARTNO], [CUSTREV], [DESCRIPT], [U_OF_MEAS], [PUR_UOFM], [BUYER_TYPE], [STDCOST], [MINORD], [ORDMULT], [PART_SOURC]);


GO
CREATE NONCLUSTERED INDEX [InvtResvLocWkeyMfgrWh]
    ON [dbo].[INVENTOR]([PART_CLASS] ASC, [PART_SOURC] ASC)
    INCLUDE([UNIQ_KEY], [PART_TYPE], [CUSTNO], [PART_NO], [REVISION], [DESCRIPT], [U_OF_MEAS], [BUYER_TYPE], [STDCOST]);


GO
CREATE NONCLUSTERED INDEX [MAKEPART]
    ON [dbo].[INVENTOR]([PART_NO] ASC, [REVISION] ASC, [PROD_ID] ASC);


GO
CREATE NONCLUSTERED INDEX [MAKEPHANTO]
    ON [dbo].[INVENTOR]([PART_NO] ASC, [REVISION] ASC);


GO
CREATE NONCLUSTERED INDEX [PART_NO]
    ON [dbo].[INVENTOR]([PART_NO] ASC);


GO
CREATE NONCLUSTERED INDEX [PART_CLASS]
    ON [dbo].[INVENTOR]([PART_CLASS] ASC);


GO
CREATE NONCLUSTERED INDEX [PARTSOURCEINCL]
    ON [dbo].[INVENTOR]([PART_SOURC] ASC)
    INCLUDE([UNIQ_KEY], [PART_CLASS], [PART_TYPE], [CUSTNO], [PART_NO], [REVISION], [CUSTPARTNO], [CUSTREV], [DESCRIPT], [U_OF_MEAS], [BUYER_TYPE], [STDCOST], [STATUS]);


GO
CREATE NONCLUSTERED INDEX [PART_SOURC]
    ON [dbo].[INVENTOR]([PART_SOURC] ASC);


GO
CREATE NONCLUSTERED INDEX [PART_TYPE]
    ON [dbo].[INVENTOR]([PART_TYPE] ASC);


GO
CREATE NONCLUSTERED INDEX [PRICE]
    ON [dbo].[INVENTOR]([PART_NO] ASC);


GO
CREATE NONCLUSTERED INDEX [rptInvtMtlChgDtIndex]
    ON [dbo].[INVENTOR]([MTCHGDT] ASC)
    INCLUDE([UNIQ_KEY], [PART_CLASS], [PART_TYPE], [CUSTNO], [PART_NO], [REVISION], [CUSTPARTNO], [CUSTREV], [DESCRIPT], [PART_SOURC], [MATLTYPE], [MTCHGINIT]);


GO
CREATE NONCLUSTERED INDEX [PRODTPUNIQ]
    ON [dbo].[INVENTOR]([PRODTPUNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [INVTPARTINCL]
    ON [dbo].[INVENTOR]([PART_NO] ASC)
    INCLUDE([UNIQ_KEY], [PART_CLASS], [PART_TYPE], [CUSTNO], [REVISION], [DESCRIPT], [PART_SOURC]);


GO
CREATE NONCLUSTERED INDEX [STATUS]
    ON [dbo].[INVENTOR]([STATUS] ASC);


GO
CREATE NONCLUSTERED INDEX [WOPRICE]
    ON [dbo].[INVENTOR]([UNIQ_KEY] ASC);


GO
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <05/27/10>
-- Description:	<Update trigger for Inventor>
-- 05/20/14 YS force some columns to be upper case. UI Independent
--04/06/15 YS some column's values depending on the part source
-- 07/13/15 YS update lastchangedt
--07/27/15 YS validate Bom_Status changes
--08/03/15 YS if isSync was changed from 0 to 1 do not update lastChangeDt, otherwise the service will think that the record was updated and will try to sync again
--08/06/15/ YS change the name for the isSync column to IsSynchronizedFlag
--08/06/15/ YS modified update trigger to changes IsSynchronizedFlag=0 by any updates to the inventor table
-- 08/13/15 Sachins -update IsSynchronizedFlag to 0,WHEN update the from web service
--08/28/15 Sachin s-delete record from SynchronizationMultiLocationLog if uniquenum exists
-- 09/14/15 YS added I.MRP_CODE<>D.Mrp_Code ( when MRP is running it is updating mrp_code for make parts when leveling parts)
	-- do not change lastchangedt
	-- --09/23/15 YS more Changes in addition to Sachin's 08/28/15 changes
--09-26-2015- SS update IsBomSynchronized flag set 0  when BOM fields updated
--09-29-2015-Sachin s- comment out the above code for Bom Synchronization when BOM fields were updated the IsSynchronizedFlag set 1 other wise 0  
--10-10-2015- SS update IsBomSynchronized flag set 0  when BOM fields updated
--10-10-2015- SS update IsSynchronizedFlag flag set 0  when BOM fields not updated
-- 11/04/15 YS no need to change IsBomSynchronized for none assembly parts
--11-04-2015 SS verify  IsBomSynchronized in the SynchronizationMultiLocationLog for delete the entry
-- 03/10/16 YS removed serialno and serialuniq from invt_res and added to the ireserveSerial. Removed kalocSer table
-- 10/19/16 YS check if matltype is changed for the internal then change it for the consign associated with it
-- 11/06/2017 Rajendra K : Added logic to update ITAR for BOM_PARENT of Updated Uniq_Key
--- 07/23/18 YS added new filed to populate lastchangeuserid and new log if lot code trace changed
--03/13/2019 Sanjayb : to update the record in INVT_RES and INVT_ISU on PartType validation
--04/04/2019 Sanjayb : to update the record in Invt_Rec,IPKEY and INVTSER on PartType validation
-- 07/02/2019 Maheshb : column size of LASTCHANGEINIT is 256  
-- =============================================
CREATE TRIGGER [dbo].[Inventor_Update]
   ON  [dbo].[INVENTOR]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    -- for now log material type changes
    DECLARE @lcNewUniqNbr char(10),@lnCount as Int, @llxxUseWoChk AS bit ;
    --12/01/10 YS added table variable for the LotDetail changes
    DECLARE @tLotD TABLE (Uniq_key char(10),OldLotDetail bit,NewLotDetail bit,nId int identity(1,1));
    --12/01/10 YS added table variable for the SerialYes changes
    DECLARE @tSerialYesD TABLE (Uniq_key char(10),Part_sourc char(10),Make_buy bit,oldSerialYes bit,NewSerialYes bit,nId int identity(1,1));
    
    DECLARE @tMfgWithQty TABLE (W_key char(10),Qty_oh Numeric(12,2),Reserved Numeric(12,2),nId Int IDENTITY(1,1));
    -- 10/15/10 VL added code to update Jbshpchk and Woentry
    --12/01/10 YS add Uniq_key to the @tOpenWo4Uniq_key in case multiple records where updated at once
    DECLARE @tUpdWo TABLE (Wono char(10));
    DECLARE @tOpenWo4Uniq_key TABLE (Wono char(10),Uniq_key char(10));
	--12/01/10 YS replace "WHERE Uniq_key = " to "WHERE Uniq_key IN "..
	INSERT @tOpenWo4Uniq_key
		SELECT Wono,Uniq_key
		FROM Woentry
		WHERE Uniq_key IN (SELECT Uniq_key FROM Inserted)
		 AND (OpenClos <> 'Cancel' AND OpenClos <> 'Closed' AND OpenClos <> 'ARCHIVED')
	
	SELECT @llxxUseWoChk = xxUseWoChk FROM ShopfSet
	
    BEGIN TRANSACTION
    --07/27/15 YS validate Bom_Status changes
	/*
	1. Bom_status was changed from 'Inactive' to 'Active' 
		check if the customer assigned to this BOM (Bomcustno <>' ' and <> '000000000~') is inactive and change it to 'Active' 
	*/
	;with Activate
	as
	(
	select I.bomcustno,c.status	
	from Inserted I inner join Deleted D on I.Uniq_key=D.Uniq_key
	inner join Customer C on I.bomcustno=C.Custno
	where I.BOM_STATUS ='Active' and D.Bom_status='Inactive'
	and C.STATUS='Inactive' and I.bomcustno<>' ' and I.Bomcustno<>'000000000~'
	)
	UPDATE Customer Set Status='Active' where exists (select 1 from Activate where customer.custno=Activate.BOMCUSTNO)
	
	-- 10/19/16 YS check if matltype is changed for the internal then change it for the consign associated with it
	update Inventor set MATLTYPE=I.Matltype ,LASTCHANGEINIT=i.LASTCHANGEINIT
			from Inserted I inner join deleted d on i.UNIQ_KEY=d.UNIQ_KEY 
			where i.part_sourc<>'CONSG' and i.PART_SOURC<>'PHANTOM' and i.MATLTYPE<>d.MATLTYPE 
			and I.uniq_key=Inventor.INT_UNIQ and Inventor.MATLTYPE<>I.MATLTYPE
			
	-- and if was changed for consign change for the internal and all other consign
	update Inventor set MATLTYPE=I.Matltype,LASTCHANGEINIT=i.LASTCHANGEINIT
			from Inserted I inner join deleted d on i.UNIQ_KEY=d.UNIQ_KEY 
			where i.MATLTYPE<>d.MATLTYPE 
			and i.part_sourc='CONSG'
			and (I.INT_UNIQ=Inventor.UNIQ_KEY OR (I.INT_UNIQ=Inventor.INT_UNIQ and i.UNIQ_KEY<>Inventor.UNIQ_KEY))
			
	-- END 10/19/16 YS
	/* 12/01/10 YS this comparison will only work when 1 record at a time is updated. 
    If inventory records where updated in bulk, like from [sp_CalculateEAU] (ABC code Setup)
    SELECT MatlType FROM DELETED and SELECT MatlType FROM INSERTED cannot be campared
    */
    
    --IF (SELECT MatlType FROM DELETED)<> (SELECT MatlType FROM INSERTED)
    -- 12/01/10 YS find if any material type changes
	---- 07/02/2019 Maheshb : column size of LASTCHANGEINIT is 256 
    DECLARE @tMaterialD Table (Uniq_key char(10),FromMatlType char(10), ToMatlType char(10),LastChangeInit NVARCHAR(256) , nId Int IDENTITY(1,1))
    INSERT INTO @tMaterialD (Uniq_key,FromMatlType,ToMatlType,LastChangeInit) 
		SELECT D.Uniq_key,D.MatlType,ISNULL(I.MatlType,SPACE(10)),ISNULL(I.LastChangeInit,space(8)) FROM Deleted D LEFT OUTER JOIN Inserted I ON D.Uniq_key=I.Uniq_key 
			WHERE D.Matltype<>I.MatlType OR I.MatlType IS NULL 
	
	--07/15/11 YS @@ROWCOUNT will change to 0 after IF 
	-- assign @lnCount first
	SET @lnCount=@@ROWCOUNT;
	IF @lnCount<>0		
	--IF @@ROWCOUNT<>0
	BEGIN
		-- create a log	
        --12/01/10 YS if multiple uniq_key are updated need to create multiple records in the UpdMatTpLog and generate UqMttpLog inside the insert
        -- EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
	    -- INSERT INTO UpdMatTpLog (UqMttpLog, Uniq_key, FromMatlType, ToMatlType, MtChgDt, MtChgInit) 
		-- SELECT @lcNewUniqNbr,Inserted.Uniq_key,Deleted.MatlTYpe,Inserted.MatlType,GETDATE(),Inserted.LastChangeInit FROM Inserted,Deleted WHERE Inserted.Uniq_key=Deleted.Uniq_key;
		-- 07/15/11 YS move set @lncount up prior to IF @@ROWCOUNT
		--SET @lnCount=@@ROWCOUNT;
		WHILE @lnCount>0
		BEGIN
			EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT;
			INSERT INTO UpdMatTpLog (UqMttpLog, Uniq_key, FromMatlType, ToMatlType, MtChgDt, MtChgInit) 
					SELECT @lcNewUniqNbr,T.Uniq_key,T.FromMatlType, T.ToMatlType,
						GETDATE(),T.LastChangeInit
					FROM @tMaterialD T WHERE nId=@lnCount;
			SET @lnCount=@lnCount-1;
		END	-- WHILE @lnCount>0
	END	-- @@ROWCOUNT<>0	
	--12/01/10}
	-- check if part type was changed and need to remove or add lot details
	--12/01/10 YS create atemp table instead of variables. If multiple update happen will have problem here
	--12/01/10 YS added table variable for the LotDetail changes
	--11/28/12 YS looks like we do not need these variable. Using INSERT into @tLotD
    --DECLARE @lTestLotBefore bit=0,@lTestLotAfter bit=0
    --SELECT @lTestLotBefore = PD.LotDetail from PartType PD,Deleted D where PD.Part_class=D.Part_class and PD.Part_type=D.Part_type
    --SELECT @lTestLotAfter = PI.LotDetail from PartType PI,INSERTED I where PI.Part_class=I.Part_class and PI.Part_type=I.Part_type
    
  --  INSERT INTO @tLotD (Uniq_key,OldLotDetail,NewLotDetail) 
		--SELECT D.Uniq_key,PD.LotDetail,PI.LotDetail 
		--	FROM Deleted D,Inserted I,PartType PD,PartType PI
		--	WHERE D.Uniq_key=I.Uniq_key
		--	AND PD.Part_class=D.Part_class and PD.Part_type=D.Part_type
		--	AND PI.Part_class=I.Part_class and PI.Part_type=I.Part_type
		--	AND PD.LotDetail<>PI.LotDetail   ;
    --11/28/12 YS need to use LEFT outer join in case only part class is selected and part typr is empty
	INSERT INTO @tLotD (Uniq_key,OldLotDetail,NewLotDetail) 
		SELECT D.Uniq_key,ISNULL(PD.LotDetail,0),ISNULL(PI.LotDetail,0) 
			FROM Deleted D INNER JOIN Inserted I ON D.Uniq_key=I.Uniq_key
			LEFT OUTER JOIN PartType PD ON D.Part_class=PD.Part_class and D.Part_type=PD.Part_type
			LEFT OUTER JOIN PartType PI ON I.Part_class=PI.Part_class and I.Part_type=PI.Part_type
			WHERE ISNULL(PD.LotDetail,0)<>ISNULL(PI.LotDetail,0)    ;
	
	--SELECT  @lOldLotCode = PartType.LotDetail FROM PartType,Deleted WHERE PartType.Part_class=Deleted.Part_class and PartType.Part_type=Deleted.Part_type
	--SELECT @lNewLotCode= PartType.LotDetail FROM PartType,Inserted WHERE PartType.Part_class=Inserted.Part_class and PartType.Part_type=Inserted.Part_type
	--IF (@lOldLotCode<>@lNewLotCode)
	
	IF @@ROWCOUNT<>0
	BEGIN
	-- lot code changed
	--	if (@lNewLotCode=1) -- lot code is on now
	--BEGIN
		-- check if need to create system generated LotCode
		INSERT INTO @tMfgWithQty (W_key,Qty_oh,Reserved)  
		SELECT W_key,Qty_oh,Reserved 
			FROM InvtMfgr
				WHERE UNIQ_KEY IN (SELECT Uniq_key from @tLotD where NewLotDetail=1) 
				AND Qty_oh>0
				AND NOT EXISTS (SELECT w_key FROM InvtLot WHERE InvtLot.W_key=Invtmfgr.w_key);
		--07/15/11 YS @@ROWCOUNT will change to 0 after IF 
		-- assign @lnCount first
		SET @lnCount=@@ROWCOUNT;
		IF @lnCount<>0		
		--IF @@ROWCOUNT<>0
		BEGIN 
			-- 07/15/11 YS move set @lncount up prior to IF @@ROWCOUNT
			--SET @lnCount=@@ROWCOUNT;
			WHILE @lnCount>0
			BEGIN
				EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT;
			    DECLARE @lotCode NVARCHAR(50) = 'mnx' + cast(convert(date,getdate()) as CHAR(10)),
				@reference CHAR(12) = cast(convert(date,getdate()) as CHAR(10)),
				@expdate CHAR(12)= cast(convert(date,getdate()) as CHAR(10)),
				@ponum CHAR(15) = dbo.padl('UNKNOWN',15,'0');

				INSERT INTO InvtLot (Uniq_lot,w_key,LotCode,LotQty,Reference,LotResQty,PoNum) 
				SELECT @lcNewUniqNbr,T.W_key,@lotCode as LotCode,T.Qty_oh,
					@reference,T.Reserved,@ponum FROM @tMfgWithQty T WHERE nId=@lnCount;

				--03/13/2019 Sanjayb : to update the record in INVT_RES and INVT_ISU on PartType validation
				--- update all open kit records
				if OBJECT_ID('tempdb..#updateKit') IS NOT NULL
				DROP TABLE #updateKit

				--- finds all the records in open kit linked to the new lot code parts
				select invtlot.lotcode as updatelotcode, invtlot.reference as updateReference,
				invtlot.EXPDATE as updateexpdate,invtlot.ponum as updateponum,
				kamain.* 
				INTO #updateKit
				from Invtlot inner join invtmfgr on invtlot.w_key=invtmfgr.w_key and invtlot.ponum=@ponum
				and invtlot.LOTCODE=@lotCode
				and invtlot.REFERENCE=@reference
				inner join kamain on invtmfgr.UNIQ_KEY=kamain.UNIQ_KEY
				inner join woentry on KAMAIN.wono=woentry.wono
				inner join inserted on kamain.UNIQ_KEY = inserted.UNIQ_KEY
				where (left(WOENTRY.OPENCLOS,1)<>'C' OR (WOENTRY.OPENCLOS='Closed' and KITSTATUS<>'KIT CLOSED'))

				update INVT_RES set lotcode=updateKit.updatelotcode ,
				Reference=updateKit.updateReference,
				Expdate=updateKit.updateexpdate,
				Ponum=updateKit.updateponum
				from #updateKit updateKit ,inserted i
				where updateKit.KASEQNUM=INVT_RES.KASEQNUM  ;

				update INVT_ISU set lotcode=updateKit.updatelotcode ,
				Reference=updateKit.updateReference,
				Expdate=updateKit.updateexpdate,
				Ponum=updateKit.updateponum
				from #updateKit updateKit ,inserted i
				where updateKit.KASEQNUM=INVT_ISU.KASEQNUM ;

				--04/04/2019 Sanjayb : to update the record in Invt_Rec,IPKEY and INVTSER on PartType validation
				update Invt_Rec set lotcode=updateKit.updatelotcode ,
				Reference=updateKit.updateReference,
				Expdate=updateKit.updateexpdate
				from #updateKit updateKit,inserted i 
				where Invt_Rec.UNIQ_KEY = i.UNIQ_KEY;

				update IPKEY set lotcode=updateKit.updatelotcode ,
				Reference=updateKit.updateReference,
				Expdate=updateKit.updateexpdate,
				Ponum=updateKit.updateponum
				from #updateKit updateKit,inserted i 
				where IPKEY.UNIQ_KEY = i.UNIQ_KEY;

				update INVTSER set lotcode=updateKit.updatelotcode ,
				Reference=updateKit.updateReference,
				Expdate=updateKit.updateexpdate,
				Ponum=updateKit.updateponum
				from #updateKit updateKit,inserted i 
				where INVTSER.UNIQ_KEY = i.UNIQ_KEY;


				if OBJECT_ID('tempdb..#updateKit') IS NOT NULL
				DROP TABLE #updateKit
				SET @lnCount=@lnCount-1;
			END	-- WHILE @lnCount>0
		END -- @@ROWCOUNT<>0
	--END -- (@lNewLotCode=1)
	--ELSE -- if (@lNewLotCode=1)
	--	BEGIN
		-- check if lot code was turned off and lotcode records are exists
		DELETE FROM InvtLot WHERE W_key IN (SELECT InvtMfgr.W_key FROM InvtMfgr,@tLotD T WHERE InvtMfgr.Uniq_key=T.Uniq_key and T.NewLotDetail=0);

		--03/13/2019 Sanjayb : to update the record in INVT_RES and INVT_ISU on PartType validation
		IF @@ROWCOUNT <> 0
		BEGIN 
			    update INVT_RES set lotcode='' ,
				Reference='',
				Expdate=NULL,
				Ponum=''
				from inserted i,@tLotD T
				where INVT_RES.UNIQ_KEY = i.UNIQ_KEY and T.NewLotDetail = 0 ;

			    update INVT_ISU set lotcode='' ,
				Reference='',
				Expdate=NULL,
				Ponum=''
				from inserted i,@tLotD T
				where INVT_ISU.UNIQ_KEY = i.UNIQ_KEY and T.NewLotDetail = 0;

				--04/04/2019 Sanjayb : to update the record in Invt_Rec,IPKEY and INVTSER on PartType validation
				update Invt_Rec set lotcode='' ,
				Reference='',
				Expdate=NULL
				from inserted i,@tLotD T
				where Invt_Rec.UNIQ_KEY = i.UNIQ_KEY and T.NewLotDetail = 0;

				update IPKEY set lotcode='' ,
				Reference='',
				Expdate=NULL,
				Ponum=''
				from inserted i,@tLotD T
				where IPKEY.UNIQ_KEY = i.UNIQ_KEY and T.NewLotDetail = 0;

				update INVTSER set lotcode='' ,
				Reference='',
				Expdate=NULL,
				Ponum=''
				from inserted i,@tLotD T
				where INVTSER.UNIQ_KEY = i.UNIQ_KEY and T.NewLotDetail = 0;
				
		END

	--	END -- else  -- (@lNewLotCode=1)
	--- 07/23/18 YS insert record into a new log table
	--07/23/18 YS added LastChangeUserid column
	insert into InventorLotChangeLog (uniq_key,oldLotdetail,newLotDetail, userid)
		select [@tlotd].Uniq_key,OldLotDetail,NewLotDetail,inserted.LastChangeUserId 
		from @tLotD inner join inserted on [@tLotD].uniq_key=inserted.UNIQ_KEY
	END		-- @@ROWCOUNT<>0
	-- 12/01/10 YS end modifying lotcode flag changes
	-- if serialyes was changed for BUY or CONSG
	--12/01/10 YS modified check for serialyes. In case multiple record update was issued
	--12/01/10 YS added table variable for the SerialYes changes
    INSERT INTO @tSerialYesD (Uniq_key,Part_sourc,Make_buy,oldSerialYes,NewSerialYes) 
		 SELECT D.Uniq_key,I.Part_sourc,I.Make_buy,D.SerialYes,I.SerialYes 
			FROM Deleted D,Inserted I
			WHERE D.Uniq_key=I.Uniq_key
			AND D.SerialYes<>I.SerialYes  ;
	--IF (SELECT SerialYes FROM Deleted)<>(SELECT SerialYes FROM Inserted) and (SELECT SerialYes FROM Inserted)=0
	IF @@ROWCOUNT<>0
	BEGIN
		-- check again if PART is a MAKE part and had any serial numbers created at any point in time.
		-- the first check is done in the screen
		--IF (SELECT Part_sourc FROM Inserted)='MAKE' and (SELECT Make_buy FROM Inserted)=0
		--BEGIN	
		SELECT Uniq_key,SerialNo 
			FROM InvtSer 
		WHERE Uniq_key IN 
			(SELECT Uniq_key from @tSerialYesD T WHERE T.Part_sourc='MAKE' AND T.Make_buy=0 AND T.NewSerialYes=0)
		IF @@ROWCOUNT<>0
		BEGIN
			RAISERROR('Some serial numbers have been created for the assembly.  Cannot un-check ''Serialized'' checkbox.',1,1)
			ROLLBACK TRANSACTION
			RETURN	
		END -- @@ROWCOUNT<>0
			
		--END -- (Inserted.APrt_sourc='MAKE' and Inserted.Make_buy=0)
		-- remove any serial number reference form invt_res
		-- 03/10/16 YS removed serialno and serialuniq from invt_res and added to the ireserveSerial
		--UPDATE Invt_res SET Serialno=space(30),
		--		SerialUniq=space(10) FROM @tSerialYesD T where T.Uniq_key=Invt_res.Uniq_key and T.NewSerialYes=0 ;
		-- remove records from KalocSer
		delete from iReserveSerial where exists (select 1 from @tSerialYesD T inner join invt_res res on t.Uniq_key=res.UNIQ_KEY where T.NewSerialYes=0 and res.INVTRES_NO=iReserveSerial.invtres_no)
		--- 03/10/16 YS removed kalocser table
		--DELETE FROM KalocSer 
		--	WHERE EXISTS
		--	(SELECT 1 FROM KALOCATE,Kamain 
		--		WHERE Kalocate.KaSeqNum=KaMain.KaSeqNum
		--		AND Kamain.Uniq_key IN (SELECT Uniq_key from @tSerialYesD T WHERE T.NewSerialYes=0)
		--		AND Kalocate.UniqKalocate=KalocSer.UniqKalocate)  
	
		--IF (SELECT SerialYes FROM Deleted)<>(SELECT SerialYes FROM Inserted) and (SELECT SerialYes FROM Inserted)=1
		--	BEGIN
		-- check again if PART is a MAKE part and has any qty oh.
		-- the first check is done in the screen
		--IF (SELECT Part_sourc FROM Inserted) ='MAKE' and (SELECT Make_buy FROM Inserted)=0
		--BEGIN
		SELECT W_key 
			FROM InvtMfgr 
		WHERE Uniq_key IN (SELECT Uniq_key from @tSerialYesD T WHERE T.Part_sourc='MAKE' AND T.Make_buy=0 AND T.NewSerialYes=1)
		AND  Qty_oh > 0 ; 
		
		IF @@ROWCOUNT <> 0
		BEGIN
			RAISERROR('The system found on-hand quantity without serial numbers assigned. You will have to issue or create a packing list for all the quantities prior assigning serialization properties to the product',1,1)
			ROLLBACK TRANSACTION
			RETURN	
		END -- @@ROWCOUNT <> 0
		
		--END -- (SELECT Part_sourc FROM Inserted ='MAKE') and (SELECT Make_buy FROM Inserted=0)
	END -- END -- @@ROWCOUNT<>0 SerialYes changes
	-- 12/01/10 YS end modifying SerialYes changes
	-- if any cost was changed update an corresponding date
	--12/01/10 YS modify code. Cannot compare values in Deleted and Inserted if multiple records were updated at once
	UPDATE Inventor SET LabDt=GETDATE() 
		WHERE Uniq_key IN (SELECT I.Uniq_key FROM Deleted D,Inserted I 
				WHERE I.Uniq_key=D.Uniq_key and I.LaborCost<>D.LaborCost) ;
	
	--IF (SELECT  LaborCost From Deleted)<> (SELECT LaborCost From Inserted)
	--	update Inventor SET LabDt = GETDATE() FROM DELETED WHERE Inventor.Uniq_key=Deleted.Uniq_key
	UPDATE Inventor SET MatDt=GETDATE() 
		WHERE Uniq_key IN (SELECT I.Uniq_key FROM Deleted D,Inserted I 
				WHERE I.Uniq_key=D.Uniq_key and I.Matl_Cost<>D.Matl_Cost) ;
	
	--IF (SELECT  Matl_Cost From Deleted)<> (SELECT Matl_Cost From Inserted)
	--	update Inventor SET MatDt = GETDATE() FROM DELETED WHERE Inventor.Uniq_key=Deleted.Uniq_key 
	
	UPDATE Inventor SET OhDt=GETDATE() 
		WHERE Uniq_key IN (SELECT I.Uniq_key FROM Deleted D,Inserted I 
				WHERE I.Uniq_key=D.Uniq_key and I.Overhead<>D.Overhead) ;
	--IF (SELECT  Overhead From Deleted)<> (SELECT Overhead From Inserted)
	--	update Inventor SET OhDt = GETDATE() FROM DELETED WHERE Inventor.Uniq_key=Deleted.Uniq_key
	
	UPDATE Inventor SET Oth2Dt=GETDATE() 
		WHERE Uniq_key IN (SELECT I.Uniq_key FROM Deleted D,Inserted I 
				WHERE I.Uniq_key=D.Uniq_key and I.OtherCost2<>D.OtherCost2) ;
	--IF (SELECT OtherCost2 FROM Deleted)<>(SELECT OtherCost2 FROM Inserted)
	--	Update Inventor SET Oth2Dt = GETDATE() FROM DELETED WHERE Inventor.Uniq_key=Deleted.Uniq_key
	
	UPDATE Inventor SET OthDt=GETDATE() 
		WHERE Uniq_key IN (SELECT I.Uniq_key FROM Deleted D,Inserted I 
				WHERE I.Uniq_key=D.Uniq_key and I.Other_Cost<>D.Other_Cost) ;
		--IF (Select Other_Cost FROM Deleted)<>(Select Other_Cost FROM Inserted)
	--	Update Inventor SET OthDt= GETDATE() FROM DELETED WHERE Inventor.Uniq_key=Deleted.Uniq_key
	
	UPDATE Inventor SET StdDt=GETDATE() 
		WHERE Uniq_key IN (SELECT I.Uniq_key FROM Deleted D,Inserted I 
				WHERE I.Uniq_key=D.Uniq_key and I.stdcost<>D.stdcost );
	--IF (Select stdcost FROM Deleted)<>(Select stdcost FROM Inserted)
	--	Update Inventor SET StdDt= GETDATE() FROM DELETED WHERE Inventor.Uniq_key=Deleted.Uniq_key
	
	UPDATE Inventor SET targetpricedt=GETDATE() 
		WHERE Uniq_key IN (SELECT I.Uniq_key FROM Deleted D,Inserted I 
				WHERE I.Uniq_key=D.Uniq_key and I.TargetPrice<>D.TargetPrice) ;
	
	
	---06/13/12 YS update all work orders if serial check mark changed from ".f." to ".t." or vise versa
	UPDATE Woentry SET SerialYes = I.SERIALYES
		FROM Inserted I,Deleted D
		WHERE I.Uniq_key=D.Uniq_key 
		AND I.PART_SOURC ='MAKE'
		AND I.MAKE_BUY =0
		AND  I.Uniq_key=Woentry.Uniq_key
		AND I.SerialYes<>D.SERIALYES  
	
	-- 06/13/12 YS also find where the qty located in the shop floor to assign starting WC if serialized flag was turned ON
	-- I am not sure which one is faster
	-- a)
	--UPDATE Dept_qty SET SerialStrt=1 WHERE UNIQUEREC 
	--	IN (SELECT D.UniqueRec FROM @tOpenWo4Uniq_key W INNER JOIN Dept_qty D on W.Wono=D.WONO
	--		WHERE D.Number IN (SELECT MAX(number) from DEPT_QTY D2 WHERE d2.WONO=D.WONO and D2.CURR_QTY <>0 and D2.DEPT_ID NOT IN ('SCRP','FGI')))
	
	
	--- b)
	UPDATE Dept_qty SET SerialStrt=1 FROM @tOpenWo4Uniq_key W,Inserted I,deleted D 
			WHERE w.Wono =Dept_qty.WONO 
			and I.UNIQ_KEY = w.Uniq_key 
			and I.UNIQ_KEY =D.UNIQ_KEY 
			and I.SERIALYES = 1
			and I.SERIALYES <>D.SERIALYES 
			and Dept_qty.Number IN (SELECT MAX(number) from DEPT_QTY D2 WHERE d2.WONO=W.WONO and D2.CURR_QTY <>0 and D2.DEPT_ID NOT IN ('SCRP','FGI'))
	
	--06/13/12 YS  update serialstrt flag if serialized flag for a part was turned off
	UPDATE Dept_qty SET SerialStrt=0 FROM inserted I,deleted D,WOENTRY W
			WHERE w.Wono =Dept_qty.WONO 
			and I.UNIQ_KEY = w.Uniq_key 
			and I.UNIQ_KEY =D.UNIQ_KEY 
			and I.SERIALYES = 0
			and I.SERIALYES <>D.SERIALYES 
			AND I.PART_SOURC ='MAKE'
			AND I.MAKE_BUY =0
	
	--IF (Select TargetPrice FROM Deleted)<>(Select TargetPrice FROM Inserted)
	--	Update Inventor SET targetpricedt = GETDATE() FROM DELETED WHERE Inventor.Uniq_key=Deleted.Uniq_key
	--12/01/10 YS modified cost date update
	
	--12/01/10 YS modify code for tooling. Cannot compare values in Deleted and Inserted if multiple records were updated at once
	-- Added code to update JbShpChk and Woentry if Inventor.ToolRel is changed
	--IF ((SELECT ToolRel FROM DELETED) <> (SELECT ToolRel FROM INSERTED)) OR 
	--	((SELECT PDMRel FROM DELETED) <> (SELECT PDMRel FROM INSERTED))
	-- for Inserted.ToolRel=1 change 
	
	
	UPDATE JbShpChk SET ChkFlag = 1, 
			ChkDate = GETDATE(),
			ChkInit = I.ToolRelInt 
				FROM Inserted I,Deleted D,@tOpenWo4Uniq_key T 
				WHERE I.Uniq_key=D.Uniq_key 
				AND  I.Uniq_key=T.Uniq_key
				AND T.Wono=JbShpChk.Wono
				AND I.ToolRel<>D.ToolRel 
				AND I.ToolRel=1
			AND JbShpChk.Shopfl_chk = 'TOOL/FIXTURE RELEASED'
			AND JbShpChk.ChkFlag	= 0
	
	--for Inserted.PDMRel=1 change	
	UPDATE JbShpChk SET ChkFlag = 1, 
			ChkDate = GETDATE(),
			ChkInit = I.ToolRelInt 
				FROM Inserted I,Deleted D,@tOpenWo4Uniq_key T 
				WHERE I.Uniq_key=D.Uniq_key 
				AND  I.Uniq_key=T.Uniq_key
				AND T.Wono=JbShpChk.Wono
				AND I.PDMRel<>D.PDMRel 
				AND I.PDMRel=1
			AND JbShpChk.Shopfl_chk = 'PDM RELEASED'
			AND JbShpChk.ChkFlag	= 0		
	
	-- for Inserted.ToolRel=0 change 
	 UPDATE Inventor SET ToolRelDt = NULL WHERE Uniq_key 
		IN (SELECT I.Uniq_key FROM INSERTED I,Deleted D 
			WHERE I.Uniq_key=D.Uniq_key 
			AND I.ToolRel<>D.ToolRel 
			AND I.ToolRel=0)
	-- for Inserted.PDMRel=0 change 
	UPDATE Inventor SET PDMRelDt = NULL WHERE Uniq_key IN 
		(SELECT I.Uniq_key FROM INSERTED I,Deleted D 
			WHERE I.Uniq_key=D.Uniq_key 
			AND I.PDMRel<>D.PDMRel 
			AND I.PDMRel=0)
			
		
		--12/01/10 YS End modifying code for tooling.
		IF @llxxUseWoChk = 1
		BEGIN
			INSERT @tUpdWo
			SELECT Wono
				FROM @tOpenWo4Uniq_key
				WHERE Wono NOT IN 
					(SELECT DISTINCT Wono FROM JbShpChk WHERE Wono IN (SELECT Wono FROM @tOpenWo4Uniq_key) AND ChkFlag = 0)
					
			UPDATE Woentry
				SET Kit = 1, ReleDate = GETDATE()
				WHERE Wono IN 
					(SELECT Wono FROM @tUpdWo)
					AND Kit = 0
	
	
		END	-- IF @llxxUseWoChk = 1			
	--END				
	--05/20/14 YS force upper case, so data entry is UI independent
			-- Insert statements for trigger here
	/*
	Inventor table
	1. Part_sourc
	2. Part_class
	3. Part_type
	4. Part_no,
	5. CustPartNo
	6. Buyer_type
	7. CustNo
	8. U_OF_MEAS
	9. PUR_UOFM
	10. Abc
	11. PUR_LUNIT
	12. PROD_LUNIT 
	13. KIT_LUNIT
	*/

	--04/06/15 YS some column's values depending on the part source
	-- 07/13/15 YS update lastchangedt
	UPDATE Inventor SET Part_sourc=UPPER(I.Part_sourc),
			PART_CLASS=UPPER(I.Part_class),
			PART_TYPE = UPPER(I.PART_TYPE),
			PART_NO = UPPER(I.Part_no),
			--04/06/15 YS some column's values depending on the part source
			CUSTPARTNO = CASE WHEN I.Part_sourc='CONSG' THEN UPPER(I.CustPartNo) else ' ' END,
			CustRev = CASE WHEN I.Part_sourc='CONSG' THEN I.CustRev else ' ' END,
			BUYER_TYPE = UPPER(I.Buyer_type),
			--04/06/15 YS some column's values depending on the part source
			CUSTNO= CASE WHEN I.Part_sourc='CONSG' THEN UPPER(I.Custno) ELSE ' ' END,
			U_OF_MEAS = UPPER(I.U_OF_MEAS),
			PUR_UOFM =UPPER(I.PUR_UOFM),
			ABC =UPPER(I.Abc),
			PUR_LUNIT =UPPER(I.PUR_LUNIT),
			PROD_LUNIT = UPPER(I.PROD_LUNIT),
			KIT_LUNIT = UPPER(I.KIT_LUNIT) ,
			--04/06/15 YS some column's values depending on the part source
			Make_buy= CASE WHEN I.Part_sourc='MAKE' THEN I.Make_buy ELSE 0 END,
			Phant_Make= CASE WHEN I.Part_sourc='MAKE' THEN I.Phant_Make ELSE 0 END,
			-- 07/13/15 YS update lastchangedt
			--08/03/15 YS if isSync was changed from 0 to 1 do not update lastChangeDt
			--08/06/15/ YS change the name for the isSync column to IsSynchronizedFlag. If the flag was changed from 1 to 1
			-- 08/06/15 update IsSynchronizedFlag to 0, unless web service is trying to update it to 1
			-- 08/13/15 Sachins -update IsSynchronizedFlag to 0,WHEN update the from web service
			-- 09/14/15 YS added I.MRP_CODE<>D.Mrp_Code ( when MRP is running it is updating mrp_code for make parts when leveling parts)
			---- do not change lastchangedt
			--IsSynchronizedFlag=
			--			  CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
			--			       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1
			--			ELSE 0 END,
			LastChangeDt = CASE WHEN I.IsSynchronizedFlag=1 or I.Mrp_code<>D.Mrp_code THEN Inventor.LASTCHANGEDT ELSE GETDATE() END,
			--07/27/15 YS update BOMINACTDT,BOMINACTINIT
			BOMINACTDT=CASE WHEN (I.BOM_STATUS ='Active' and D.Bom_status='Inactive') THEN NULL
						WHEN  (I.BOM_STATUS ='Inactive' and D.Bom_status='Active' ) THEN GETDATE()
						ELSE Inventor.BOMINACTDT END,
			BOMINACTINIT= CASE WHEN (I.BOM_STATUS ='Active' and D.Bom_status='Inactive') THEN ' '
						WHEN  (I.BOM_STATUS ='Inactive' and D.Bom_status='Active' ) THEN I.BOMINACTINIT
						ELSE Inventor.BOMINACTINIT END,
						    --08/13/15 Sachins -update IsSynchronizedFlag to 0,WHEN update the from web service		   
      --      IsSynchronizedFlag=
						--  CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
						--       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1
						--ELSE 0 END,

		--10-10-2015- SS update IsBomSynchronized flag set 0  when BOM fields updated
			IsBomSynchronized =
				CASE WHEN (
					I.STDBLDQTY <> D.STDBLDQTY OR
					I.USESETSCRP <> D.USESETSCRP OR 
					I.BOMLOCK <> D.BOMLOCK  OR				
					--rtrim(I.BOM_NOTE) <> rtrim(D.BOM_NOTE) OR
					I.BOM_STATUS <> D.BOM_STATUS OR
					I.BOMCUSTNO  <> D.BOMCUSTNO OR
					--I.BOM_LASTDT  <> D.BOM_LASTDT OR
					I.BOMINACTDT  <> D.BOMINACTDT OR
					I.BOMINACTINIT <> D.BOMINACTINIT OR
					I.BOMITEMARC  <> D.BOMITEMARC OR
					I.BOMLASTINIT  <> D.BOMLASTINIT OR
					I.BOMLOCKDT  <> D.BOMLOCKDT OR
					I.BOMLOCKINIT <> D.BOMLOCKINIT ) AND (I.Part_sourc='MAKE' OR I.PART_SOURC='PHANTOM')
				THEN 0
				-- 11/04/15 YS no need to change IsBomSynchronized for none assembly parts
				when I.Part_sourc<>'MAKE' and I.PART_SOURC<>'PHANTOM' THEN 0
				ELSE 1 END,
				--10-10-2015- SS update IsSynchronizedFlag flag set 0  when BOM fields not updated
				IsSynchronizedFlag=						 
						      CASE 
							  -- WHEN (I.IsBomSynchronized = 1 and D.IsBomSynchronized = 0) THEN 1	
							  -- WHEN (I.IsBomSynchronized = 0 and D.IsBomSynchronized = 1) THEN 1
							  -- WHEN (
								 --  I.STDBLDQTY <> D.STDBLDQTY OR
									--I.USESETSCRP <> D.USESETSCRP OR 
									--I.BOMLOCK <> D.BOMLOCK  OR				
									----rtrim(I.BOM_NOTE) <> rtrim(D.BOM_NOTE) OR
									--I.BOM_STATUS <> D.BOM_STATUS OR
									--I.BOMCUSTNO  <> D.BOMCUSTNO OR
									----I.BOM_LASTDT  <> D.BOM_LASTDT OR
									--I.BOMINACTDT  <> D.BOMINACTDT OR
									--I.BOMINACTINIT <> D.BOMINACTINIT OR
									--I.BOMITEMARC  <> D.BOMITEMARC OR
									--I.BOMLASTINIT  <> D.BOMLASTINIT OR
									--I.BOMLOCKDT  <> D.BOMLOCKDT OR
									--I.BOMLOCKINIT <> D.BOMLOCKINIT 
							  -- ) THEN 1
							   WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
							   WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1	
						ELSE 0 END	
	
	 		FROM inserted I inner join deleted D on i.UNIQ_KEY=d.UNIQ_KEY
			where I.UNIQ_KEY =Inventor.UNIQ_KEY  
			
			--08/28/15 delete record from SynchronizationMultiLocationLog if uniquenum exists
			--Check IsSynchronizedFlag is zero
			--IF((SELECT IsSynchronizedFlag FROM inserted) = 0)
			--09/23/15 YS The code above will return error if multiple records are updted and Inserted return more than one result
			IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
				--Delete the Unique num from SynchronizationMultiLocationLog table if exists with same UNIQ_KEY so all location pick again
				-- 09/23/15 YS This delete will remove any record from SynchronizationMultiLocationLog
				-- that have connectiom to Inventor table, not just the ones you are working on right now
				--DELETE sml FROM SynchronizationMultiLocationLog sml
				--INNER JOIN Inventor inv on sml.UniqueNum=inv.UNIQ_KEY
				--where inv.UNIQ_KEY =sml.UniqueNum
				-- If I understand you want to remove any records from SynchronizationMultiLocationLog with the uniq_key in this update 
				--and IsSynchronizedFlag=0.
				--
				--11-04-2015 verify  IsBomSynchronized in the SynchronizationMultiLocationLog for delete the entry
			IF EXISTS (SELECT 1 FROM inserted where (IsSynchronizedFlag=0 OR IsBomSynchronized=0))
			BEGIN							
				DELETE FROM SynchronizationMultiLocationLog 
				--11-04-2015 verify  IsBomSynchronized in the SynchronizationMultiLocationLog for delete the entry
				where EXISTS (Select 1 from Inserted where (IsSynchronizedFlag=0 OR IsBomSynchronized=0) and Inserted.Uniq_key=SynchronizationMultiLocationLog.Uniquenum);				
			END
			END


			--11/06/2017 Rajendra K : Make ITAR 1 for BOM_PARENT of Updated Uniq_Key
			IF EXISTS(SELECT 1 FROM  inserted I WHERE I.ITAR = 1)
			BEGIN
				UPDATE INVENTOR SET ITAR =  1 
				FROM  inserted I INNER JOIN BOM_DET B ON I.UNIQ_KEY = B.UNIQ_KEY 
				WHERE B.BOMPARENT  = INVENTOR.UNIQ_KEY
			END
	COMMIT
	
END
GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/20/14 YS 
-- Description:	Force upper case, so the data is front end independed
--04/06/15 YS some column's values depending on the part source
--04/14/15 YS type in the name of the inserted
--04/21/17 VL added to update functional currency fields
-- =============================================
CREATE TRIGGER [dbo].[Inventor_Insert]
   ON [dbo].[INVENTOR] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--04/06/15 YS declare variables for the error to raise
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    -- Insert statements for trigger here
/*
Inventor table
1. Part_sourc
2. Part_class
3. Part_type
4. Part_no,
5. CustPartNo
6. Buyer_type
7. CustNo
8. U_OF_MEAS
9. PUR_UOFM
10. Abc
11. PUR_LUNIT
12. PROD_LUNIT 
13. KIT_LUNIT
*/
BEGIN TRANSACTION
BEGIN TRY
	-- 04/06/15 YS test unit of measure conversion
		--04/14/15 YS type in the name of the inserted
	IF EXISTS ( SELECT 1 FROM Inserted I LEFT OUTER JOIN Unit as U ON (I.u_of_meas=U.[To] and I.Pur_uofm =U.[From] ) OR (I.u_of_meas=U.[From] and I.Pur_uofm =U.[To])
		where I.u_of_meas <> I.Pur_uofm  and (I.Part_sourc='BUY' OR  (I.Part_sourc='MAKE' and I.Make_buy=1)) and U.Formula is NULL)
	
	BEGIN
		RAISERROR ('No Conversion between the Stock UOM has been set up in the system.', -- Message text.
               16, -- Severity.
               1 -- State.
               );

	END -- if exists -- 04/06/15 YS test unit of measure conversion
	
	UPDATE Inventor SET Part_sourc=UPPER(I.Part_sourc),
			PART_CLASS=UPPER(I.Part_class),
			PART_TYPE = UPPER(I.PART_TYPE),
			PART_NO = UPPER(I.Part_no),
			--04/06/15 YS some column's values depending on the part source
			CUSTPARTNO = CASE WHEN I.Part_sourc='CONSG' THEN UPPER(I.CustPartNo) else ' ' END,
			CustRev = CASE WHEN I.Part_sourc='CONSG' THEN I.CustRev else ' ' END,
			BUYER_TYPE = UPPER(I.Buyer_type),
			--04/06/15 YS some column's values depending on the part source
			CUSTNO= CASE WHEN I.Part_sourc='CONSG' THEN UPPER(I.Custno) ELSE ' ' END,
			U_OF_MEAS = UPPER(I.U_OF_MEAS),
			PUR_UOFM =UPPER(I.PUR_UOFM),
			ABC =UPPER(I.Abc),
			PUR_LUNIT =UPPER(I.PUR_LUNIT),
			PROD_LUNIT = UPPER(I.PROD_LUNIT),
			KIT_LUNIT = UPPER(I.KIT_LUNIT) ,
			--04/06/15 YS some column's values depending on the part source
			Make_buy= CASE WHEN I.Part_sourc='MAKE' THEN I.Make_buy ELSE 0 END,
			Phant_Make= CASE WHEN I.Part_sourc='MAKE' THEN I.Phant_Make ELSE 0 END,
			Bom_status = CASE WHEN (I.Part_sourc='MAKE' OR I.Part_sourc='PHANTOM') and I.Bom_status=' ' THEN 'Active'
							WHEN (I.Part_sourc='MAKE' OR I.Part_sourc='PHANTOM') and I.Bom_status<>' ' THEN I.Bom_status
							WHEN (I.Part_sourc<>'MAKE' AND I.Part_sourc<>'PHANTOM') THEN ' ' END,
			BomCustNo = CASE WHEN (I.Part_sourc='MAKE' OR I.Part_sourc='PHANTOM') and I.BomCUstno<>' ' THEN UPPER(I.BomCustNo)
							ELSE ' ' END,
			PRFcused_uniq = CASE WHEN dbo.fn_IsFCInstalled() = 0 THEN SPACE(10) ELSE dbo.fn_GetPresentationCurrency() END,
			FuncFcused_uniq = CASE WHEN dbo.fn_IsFCInstalled() = 0 THEN SPACE(10) ELSE dbo.fn_GetFunctionalCurrency() END 
			FROM inserted I where I.UNIQ_KEY =Inventor.UNIQ_KEY  
END TRY
BEGIN CATCH
	SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
		IF @@TRANCOUNT <>0
			ROLLBACK TRAN ;
			
END CATCH
	
IF @@TRANCOUNT>0
	COMMIT
		
END
GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/17/2010
-- Description:	Delete trigger
-- Modified : 04/22/14 YS modified code to avoid output
--- 09/28/14 when checking from MAKE parts use if EXISTS
-- 10/09/14 YS replace invtmfhd table with 2 new tables
--02/12/15 check for the release flag was missing.
--03/26/15 YS remove records with 0 accepted qty
--07/13/15 YS create deleted records log to use in sync modules
--08/12/15 sachins-Change the name of the table from DeletedRecordsLog to SynchronizationDeletedRecords
-- 08/08/19 ys updated the validation for new manex to work
-- =============================================
CREATE TRIGGER [dbo].[Inventor_Delete] 
   ON  [dbo].[INVENTOR] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	-- 03/23/12 VL added to only check un-reconciled PO if PORECON is installed
	DECLARE @lGlInstalled as bit, @lnPostType int, @lPoReconInstalled as bit
	-- check if delete should be allowed
	-- check if Invtmfgr has any qty_oh
	--04/22/14 YS modified code to avoid output
	IF EXISTS (SELECT Uniq_Key 
		FROM InvtMfgr 
		WHERE qty_oh<>0 
		AND Uniq_Key IN (SELECT Uniq_key from DELETED))
	--IF @@ROWCOUNT<>0
	BEGIN            
       RAISERROR('Inventory record shows you have quantities on hand for this part.',1,1)
       ROLLBACK TRANSACTION
	   RETURN    
    END  -- check qty_oh
	-- check if in Cycle count or Physical inventory
	--04/22/14 YS modified code to avoid output
	IF EXISTS(SELECT Uniq_Key 
		FROM InvtMfgr 
		WHERE CountFlag<>' '
		AND Is_Deleted=0		
		AND Uniq_Key IN (SELECT Uniq_key from DELETED))
	--IF @@ROWCOUNT<>0
	BEGIN            
       RAISERROR('This part cannot be deleted at this time.  It is in the process of a physical inventory or Cycle Count.  Complete the physical inventory or Cycle Count, then delete the location.',1,1)
       ROLLBACK TRANSACTION
	   RETURN    
    END  -- check Cycle count or Physical inventory
	-- check for OPEN work orders
	--04/22/14 YS modified code to avoid output
	IF EXISTS(SELECT Uniq_key 
		FROM Woentry 
		WHERE OpenClos<>'Cancel' 
		AND Openclos<>'Closed' 
		AND OpenClos<>'ARCHIVED'
		AND Uniq_key IN (SELECT Uniq_key from DELETED))
	--IF @@ROWCOUNT<>0
	BEGIN            
       RAISERROR('This part cannot be deleted because there is one or more open work orders for it.',1,1)
	   ROLLBACK TRANSACTION
	   RETURN    
    END  -- check for OPEN work orders
	
	-- check for OPEN Sales orders
	--04/22/14 YS modified code to avoid output
	IF EXISTS(SELECT Uniq_key 
		FROM Sodetail, SoMain
		WHERE SoMain.SoNo = SoDetail.SoNo 
		 AND Status <> 'Cancel' 
		 AND Status <> 'Closed' 
		 AND Uniq_key IN (SELECT Uniq_key from DELETED))
		--IF @@ROWCOUNT<>0
	BEGIN            
       RAISERROR('This part cannot be deleted because there is one or more open sales orders for it.',1,1)
	   ROLLBACK TRANSACTION
	   RETURN    
    END  -- check for OPEN sales orders
	
	-- check for BOM
	--04/22/14 YS modified code to avoid output
	-- 08/08/19 ys need to check if BOM is active
	IF EXISTS(
		SELECT b.Uniq_key
		FROM Bom_det b inner join Inventor I on b.BOMPARENT=i.UNIQ_KEY
		WHERE i.BOM_STATUS='Active' and  exists (SELECT 1 from DELETED D where d.UNIQ_KEY=b.UNIQ_KEY))
	
	--IF @@ROWCOUNT<>0
	BEGIN            
       RAISERROR('This part cannot be deleted because it is used in one or more Bill of Materials',1,1)
		ROLLBACK TRANSACTION   
		RETURN 
	END -- check for BOM

	-- check for open POs
	--04/22/14 YS modified code to avoid output
	-- 08/08/19 ys need to check if poitems items is cancelled
	IF EXISTS(SELECT Uniq_key 
		FROM PoItems INNER JOIN  PoMain on PoMain.PoNum = PoItems.PoNum 
		WHERE 
		PoMain.PoStatus <> 'CANCEL' 
		 AND PoMain.PoStatus <> 'CLOSED' 
		 and poitems.LCANCEL=0
		AND exists (SELECT 1 from DELETED where deleted.UNIQ_KEY=poitems.UNIQ_KEY)
		 )
	--IF @@ROWCOUNT<>0
	BEGIN            
       RAISERROR('This part cannot be deleted because it is on one or more purchase orders.',1,1)
		ROLLBACK TRANSACTION   
		RETURN 
	END -- check for PO
	
	-- 03/23/12 VL added The following validation has to be executed only if PO reconciliation module is installed
	-- 08/08/19 !!! ys need to find a way for the accounting to be off if users do not want to use it
	SELECT @lPoReconInstalled = Installed FROM Items WHERE ScreenName = 'PORRECON'
	IF  (@lPoReconInstalled = 1 ) 
	BEGIN
		-- check for un-reconciled
		--04/22/14 YS modified code to avoid output
		--03/26/15 YS remove records with 0 accepted qty
--08/08/19 YS added join 
	IF EXISTS
		(SELECT Uniq_key 
		 FROM Poitems PO INNEr join Porecdtl PR on po.UNIQLNNO=pr.uniqlnno
		 INNER JOIN Porecloc PL on Pr.UniqRecdtl = pl.Fk_UniqRecdtl
		 WHERE exists (SELECT 1 from DELETED d where d.UNIQ_KEY=po.UNIQ_KEY ) 
		 and pl.accptqty<>0.00
		 AND (SDet_uniq=''
		 OR SInv_uniq=''))
	   
		--IF @@ROWCOUNT<>0
	BEGIN            
		   RAISERROR('This part cannot be deleted because it is on one or more purchase orders, and those purchase orders have not been reconciled.',1,1)
			ROLLBACK TRANSACTION   
			RETURN 
		END -- check for un-reconciled POs
	END
	-- 03/23/12 VL End}
	
	-- check KIT in process
	--04/22/14 YS modified code to avoid output
	IF EXISTS
	(
	SELECT Kamain.Wono,Woentry.KitStatus
	 FROM Kamain,Woentry 
	 WHERE Kamain.Uniq_key IN (SELECT Uniq_key from DELETED) 
	 AND Woentry.Wono=Kamain.Wono
	 AND Woentry.KitStatus='KIT PROCSS')
	
	--IF @@ROWCOUNT<>0
	BEGIN            
       RAISERROR('This part cannot be deleted because it is on the open KIT list as a component.',1,1)
		ROLLBACK TRANSACTION   
		RETURN 
	END -- check for kit in process
	
	-- The following validation has to be executed only if GL is installed
	SELECT @lGlInstalled = Installed FROM Items WHERE ScreenName = 'GLREL   '
	IF  (@lGlInstalled = 1 ) 
	BEGIN
		-- check for un-released/un-posted costadj if needed
		SELECT @lnPostType=dbo.GetGlPostRules4PostType('COSTADJ');
		IF (@lnPostType=3 or @lnPostType=2)
		BEGIN
			--04/22/14 YS modified code to avoid output
			IF EXISTS
				(SELECT Uniq_Key 
				FROM UpdtStd 
				WHERE UpDtStd.Uniq_Key IN (SELECT Uniq_key from DELETED) 
				AND UpDtStd.ChangeAmt <> 0 
				AND UpDtStd.IS_rel_gl=0 )
			--IF @@ROWCOUNT<>0
			BEGIN            
				RAISERROR('This part cannot be deleted because ''Cost Adjustment'' transactions for this part are not release(posted) to G/L.',1,1)
				ROLLBACK TRANSACTION   
				RETURN 
			END -- check for un-released costadj
		END -- @lnPostTpe=3 or 2
		-- check for un-release INVTREC
		SELECT @lnPostType=dbo.GetGlPostRules4PostType('INVTREC')
		IF (@lnPostType=3 or @lnPostType=2)
		BEGIN
			--04/22/14 YS modified code to avoid output
			---08/08/19 YS change IN to Exists shoule work faster
			IF EXISTS
				(SELECT Uniq_key
				FROM Invt_Rec
				WHERE exists (select 1 from deleted d where d.uniq_key=Invt_Rec.Uniq_Key)
				AND Is_Rel_Gl=0
				AND Invt_Rec.Gl_nbr<>'')			

			--IF @@ROWCOUNT<>0
			BEGIN            
				RAISERROR('This part cannot be deleted because ''Inventory Receiving transactions'' for this part are not release(posted) to G/L.',1,1)
				ROLLBACK TRANSACTION   
				RETURN 
			END -- check for un-released INVTREC
		END -- @lnPostTpe=3 or 2

		-- check for un-release INVTISU
		SELECT @lnPostType=dbo.GetGlPostRules4PostType('INVTISU')
		IF (@lnPostType=3 or @lnPostType=2)
		BEGIN
			--04/22/14 YS modified code to avoid output
		 ---08/08/19 YS change IN to Exists should work faster.Change from charindex() to like 
			IF EXISTS
				(SELECT Uniq_key
				FROM Invt_Isu
				WHERE exists (select 1 from Deleted d where d.Uniq_Key=invt_isu.UNIQ_KEY)
				AND Is_Rel_Gl=0
				AND Gl_nbr<>''
				AND ISSUEDTO like '%REQ PKLST%')
				--CHARINDEX('REQ PKLST',IssuedTo)=0)

			--IF @@ROWCOUNT<>0
			BEGIN            
				RAISERROR('This part cannot be deleted because ''Inventory Issue'' transactions for this part are not release(posted) to G/L.',1,1)
				ROLLBACK TRANSACTION   
				RETURN 
			END -- check for un-released INVTTRANS
		END -- @lnPostTpe=3 or 2
		-- check for un-release INVTISU
		SELECT @lnPostType=dbo.GetGlPostRules4PostType('INVTTRANS')
		IF (@lnPostType=3 or @lnPostType=2)
		BEGIN
			--04/22/14 YS modified code to avoid output
			 ---08/08/19 YS change IN to Exists should work faster.
			IF EXISTS
				(SELECT Uniq_key
				FROM InvtTrns 
				WHERE exists (select 1 from deleted d where  d.Uniq_Key=INVTTRNS.Uniq_key)
				AND Is_Rel_Gl=0
				AND Gl_nbr<>''
				AND Gl_Nbr <> Gl_nbr_Inv )
				

			--IF @@ROWCOUNT<>0
			BEGIN            
				RAISERROR('This part cannot be deleted because ''Inventory Transfer'' transactions for this part are not release(posted) to G/L.',1,1)
				ROLLBACK TRANSACTION   
				RETURN 
			END -- check for un-released INVTTRANS

			
		END -- @lnPostTpe=3 or 2
		-- check for the records in the PORECRELGL table 
		SELECT @lnPostType=dbo.GetGlPostRules4PostType('UNRECREC')
		IF (@lnPostType=3 or @lnPostType=2)
		BEGIN
			--04/22/14 YS modified code to avoid output
			 ---08/08/19 YS change IN to Exists should work faster.
			IF EXISTS
			(SELECT 1
				FROM PorecrelGl PG INNER JOIN Porecloc PL on pg.Loc_uniq=pl.loc_uniq
				INNER JOIN Porecdtl PR on pl.fk_uniqrecdtl=pr.Uniqrecdtl
				INNER JOIN Poitems PO on  pr.uniqlnno=po.uniqlnno
				 WHERE pg.Is_rel_gl =0
				AND exists (select 1 from deleted d where d.UNIQ_KEY=po.uniq_key)
				)
			
			--IF @@ROWCOUNT<>0
			BEGIN            
				RAISERROR('This part cannot be deleted because ''Unreconciled Account'' has transactions for this part, which are not release(posted) to G/L.',1,1)
				ROLLBACK TRANSACTION   
				RETURN 
			END -- check for un-released UNRECREC
		END -- @lnPostTpe=3 or 2
		--- check for 'Other Costs' release records and purchase variances
		SELECT @lnPostType=dbo.GetGlPostRules4PostType('INVTCOSTS')
		IF (@lnPostType=3 or @lnPostType=2)
		BEGIN
			--04/22/14 YS modified code to avoid output
			 ---08/08/19 YS change IN to Exists should work faster.
			IF EXISTS
				(SELECT Confgvar.Uniq_key 
					FROM  Confgvar 
				 WHERE is_Rel_Gl =0
				 AND exists (select 1 from deleted d where d.uniq_key=Confgvar.uniq_key)
				 AND VarType <> 'CONFG')
			--IF @@ROWCOUNT<>0
			BEGIN            
				RAISERROR('This part cannot be deleted because ''Other Inventory Costs'' transactions for this part are not release(posted) to G/L.',1,1)
				ROLLBACK TRANSACTION   
				RETURN 
			END -- check for un-released INVTCOSTS
		END --(@lnPostType=3 or @lnPostType=2)	
		-- check purchase variance
		SELECT @lnPostType=dbo.GetGlPostRules4PostType('PURVAR')
		IF (@lnPostType=3 or @lnPostType=2)
		BEGIN
			--04/22/14 YS modified code to avoid output
			 ---08/08/19 YS change IN to Exists should work faster.
			IF EXISTS
				(SELECT pur_var.VAR_KEY 
				from pur_var
				where exists 
					(SELECT 1
					from POITEMS po inner join PORECDTL pr on pr.UNIQLNNO =po.UNIQLNNO 
					inner join PORECLOC pl on pl.FK_UNIQRECDTL =pr.UNIQRECDTL 
					inner join SINVDETL si on si.LOC_UNIQ =pl.LOC_UNIQ 
					where 
					exists (select 1 from deleted d where d.uniq_key=po.UNIQ_KEY)
					and PUR_VAR.SDET_UNIQ =si.SDET_UNIQ )
					--02/12/15 check for the release flag was missing
				AND Variance <> 0 and is_rel_gl=0)
			
			--IF @@ROWCOUNT<>0
			BEGIN            
				RAISERROR('This part cannot be deleted because ''Purchase Variance'' transactions for this part are not release(posted) to G/L.',1,1)
				ROLLBACK TRANSACTION   
				RETURN 
			END -- check for un-released PURVAR
		END --(@lnPostType=3 or @lnPostType=2)
		--- 09/28/14 When multiple records will return multiple results
		
		--IF ((SELECT Part_sourc from DELETED)='MAKE')
		IF EXISTS (SELECT Part_sourc from DELETED where Part_sourc='MAKE')
		BEGIN
			-- check MFGRVAR
			SELECT @lnPostType=dbo.GetGlPostRules4PostType('MFGRVAR')
			IF (@lnPostType=3 or @lnPostType=2)
			BEGIN
				--04/22/14 YS modified code to avoid output
				 ---08/08/19 YS change IN to Exists should work faster.
				IF EXISTS
					(SELECT mfgrvar.Uniq_key 
					FROM  mfgrvar 
					WHERE is_Rel_Gl =0
					AND exists (select 1 from deleted d where d.uniq_key=mfgrvar.uniq_key))
				--IF @@ROWCOUNT<>0
				BEGIN            
					RAISERROR('This part cannot be deleted because ''Manufacturing Variance'' transactions for this part are not release(posted) to G/L.',1,1)
					ROLLBACK TRANSACTION   
					RETURN 
				END -- check for un-released MFGRVAR
			END --(@lnPostType=3 or @lnPostType=2)
			--- check for 'CONFGVAR' release records and purchase variances
			SELECT @lnPostType=dbo.GetGlPostRules4PostType('CONFGVAR')
			IF (@lnPostType=3 or @lnPostType=2)
			BEGIN
				--04/22/14 YS modified code to avoid output
				 ---08/08/19 YS change IN to Exists should work faster.
				IF EXISTS
					(SELECT Confgvar.Uniq_key 
					FROM  Confgvar 
					WHERE is_Rel_Gl =0
					AND exists (select 1 from deleted d where d.uniq_key=Confgvar.uniq_key)
					AND VarType = 'CONFG')
				--IF @@ROWCOUNT<>0
				BEGIN            
					RAISERROR('This part cannot be deleted because ''Configuration Variance'' transactions for this part are not release(posted) to G/L.',1,1)
					ROLLBACK TRANSACTION   
					RETURN 
				END -- check for un-released CONFGVAR
			END --(@lnPostType=3 or @lnPostType=2)	
			--- check for 'SCRAP' release records and purchase variances
			SELECT @lnPostType=dbo.GetGlPostRules4PostType('SCRAP')
			IF (@lnPostType=3 or @lnPostType=2)
			BEGIN
				--04/22/14 YS modified code to avoid output
				 ---08/08/19 YS change IN to Exists should work faster.
				IF EXISTS
					(SELECT scraprel.Uniq_key 
					FROM  scraprel 
					WHERE is_Rel_Gl =0
					AND exists (select 1 from deleted d where d.uniq_key=scraprel.uniq_key))
				
				--IF @@ROWCOUNT<>0
				BEGIN            
					RAISERROR('This part cannot be deleted because ''Scrap'' transactions for this part are not release(posted) to G/L.',1,1)
					ROLLBACK TRANSACTION   
					RETURN 
				END -- check for un-released SCRAP
			END --(@lnPostType=3 or @lnPostType=2)	
		END -- MAKE
		
		--- 09/28/14 When multiple records will return multiple results
		
		
		IF EXISTS (SELECT 1 from DELETED where Part_sourc='MAKE' or Part_sourc='PHANTOM')
		--IF ((SELECT Part_sourc from DELETED)='MAKE' or (SELECT Part_sourc from DELETED)='PHANTOM')

		BEGIN
			-- check for BOM as assy
			--04/22/14 YS modified code to avoid output
			-- 08/08/19 ys need to check if BOM is active
			IF EXISTS(
			SELECT b.BomParent
			FROM Bom_det b inner join Inventor I on b.BOMPARENT=i.UNIQ_KEY
				WHERE i.BOM_STATUS='Active' and  exists (SELECT 1 from DELETED D where d.UNIQ_KEY=b.BOMPARENT))
			--IF EXISTS
			--(SELECT BomParent
			--	FROM Bom_det 
			--	WHERE Bomparent IN (SELECT Uniq_key from DELETED))
			--IF @@ROWCOUNT<>0
			BEGIN            
				RAISERROR('This part cannot be deleted because there is one or more components assigned to it in the BOM module.', 1,1)
				ROLLBACK TRANSACTION   
				RETURN 
			END -- check BOMPARENT
		
		END -- MAKE or PHANTOM
		--- 09/28/14 When multiple records will return multiple results
		

		IF EXISTS (SELECT 1 from DELETED where Part_sourc<>'CONSG')
		--IF ((SELECT Part_sourc from DELETED)<>'CONSG')
		BEGIN
			-- check if any consign parts
			--04/22/14 YS modified code to avoid output
			IF EXISTS
			(SELECT Uniq_key 
				FROM Inventor
			WHERE Int_uniq IN (SELECT Uniq_key from DELETED))
			--IF @@ROWCOUNT<>0
			BEGIN            
				RAISERROR('This part cannot be deleted because there is one or more consigned parts based on this internal part.',1,1)
				ROLLBACK TRANSACTION   
				RETURN 
			END -- check for un-released SCRAP
		END --<> CONSIGN
	END -- if  @lGlInstalled = 1
	-- pass all the validation 
	 -- Insert statements for trigger here
	 --- 09/28/14 When multiple records will return multiple results
		
		
	IF EXISTS (SELECT 1 from DELETED where SerialYes=1)
	--IF ((SELECT SerialYes FROM DELETED)=1)
	BEGIN
		-- remove records from InvtSer
		DELETE FROM InvtSer Where Uniq_key IN (SELECT Uniq_key from Deleted)
	END
	--- remove records from InvtMfsp
	DELETE FROM InvtMfsp Where Uniq_key IN (SELECT Uniq_key from Deleted)
	--- remove records from contract tables if any
	DECLARE @zContract TABLE (Contr_uniq char(10))
	INSERT INTO @zContract SELECT Contr_uniq FROM [Contract] WHERE uniq_key in (SELECT Uniq_key From DELETED)
	IF @@ROWCOUNT<>0
	BEGIN	
		DELETE FROM ContMfgr WHERE contr_uniq in (SELECT contr_uniq FROM @zContract)
		DELETE FROM ContPric WHERE contr_uniq in (SELECT contr_uniq FROM @zContract)
		DELETE FROM [Contract] WHERE contr_uniq in (SELECT contr_uniq FROM @zContract)
	END
	--- remove records from invtmfhd
	--10/09/14 YS Denis's BD. Also removed invtmfhd table and replace with 2 new tables
	DELETE FROM InvtMPNLink WHERE exists (select 1 from Deleted D where D.Uniq_key=InvtMPNLink.Uniq_key)
	--- remove records from invtmfgr
	DELETE FROM InvtMfgr WHERE Uniq_key IN (SELECT Uniq_key from Deleted)
	--07/13/15 YS create deleted records log to use in sync modules
	--08/12/15 sachins-Change the name of the table from DeletedRecordsLog to SynchronizationDeletedRecords
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'Inventor'
           ,'Uniq_key'
           ,Deleted.Uniq_key
		    from Deleted
	COMMIT
	
END