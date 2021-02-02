CREATE TABLE [dbo].[MISCMAIN] (
    [WONO]       CHAR (10)       CONSTRAINT [DF__MISCMAIN__WONO__239F1926] DEFAULT ('') NOT NULL,
    [DEPT_ID]    CHAR (4)        CONSTRAINT [DF__MISCMAIN__DEPT_I__24933D5F] DEFAULT ('') NOT NULL,
    [SHORTQTY]   NUMERIC (12, 2) CONSTRAINT [DF__MISCMAIN__SHORTQ__25876198] DEFAULT ((0)) NOT NULL,
    [PART_CLASS] CHAR (8)        CONSTRAINT [DF__MISCMAIN__PART_C__267B85D1] DEFAULT ('') NOT NULL,
    [PART_TYPE]  CHAR (8)        CONSTRAINT [DF__MISCMAIN__PART_T__276FAA0A] DEFAULT ('') NOT NULL,
    [DESCRIPT]   CHAR (45)       CONSTRAINT [DF__MISCMAIN__DESCRI__2863CE43] DEFAULT ('') NOT NULL,
    [PART_NO]    CHAR (25)       CONSTRAINT [DF__MISCMAIN__PART_N__2957F27C] DEFAULT ('') NOT NULL,
    [REVISION]   CHAR (4)        CONSTRAINT [DF__MISCMAIN__REVISI__2A4C16B5] DEFAULT ('') NOT NULL,
    [PART_SOURC] CHAR (10)       CONSTRAINT [DF__MISCMAIN__PART_S__2B403AEE] DEFAULT ('') NOT NULL,
    [QTY]        NUMERIC (12, 2) CONSTRAINT [DF__MISCMAIN__QTY__2C345F27] DEFAULT ((0)) NOT NULL,
    [MISCKEY]    CHAR (10)       CONSTRAINT [DF__MISCMAIN__MISCKE__2D288360] DEFAULT ('') NOT NULL,
    [BOMPARENT]  CHAR (10)       CONSTRAINT [DF__MISCMAIN__BOMPAR__2E1CA799] DEFAULT ('') NOT NULL,
    [cSavedBy]   CHAR (8)        CONSTRAINT [DF_MISCMAIN_cSavedBy] DEFAULT ('') NOT NULL,
    [ShReason]   CHAR (15)       CONSTRAINT [DF_MISCMAIN_ShReason] DEFAULT ('') NOT NULL,
    CONSTRAINT [MISCMAIN_PK] PRIMARY KEY CLUSTERED ([MISCKEY] ASC)
);


GO
CREATE NONCLUSTERED INDEX [WONO]
    ON [dbo].[MISCMAIN]([WONO] ASC);


GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 03/15/2011
-- Description:	After Update trigger for the MiscMain table, to insert MiscDet record if shortqty or ShReason is changed
-- =============================================
CREATE TRIGGER  [dbo].[MiscMain_Update]
   ON  [dbo].[MISCMAIN] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION ;
	
	DECLARE @ZDet TABLE (nrecno int identity, DShortQty numeric(12,2), IShortQty numeric(12,2), 
		DShReason char(15), IShReason char(15), MiscKey char(10), cSavedBy char(8))

	DECLARE @lnTotalNo int, @lnCount int, @ZDShortQty numeric(12,2), @ZIShortQty numeric(12,2), 
		@ZDShReason char(15), @ZIShReason char(15), @ZMiscKey char(10), @ZcSavedBy char(8), @lcNewUniqNbr char(10)

	INSERT @ZDet
		SELECT D.ShortQty AS DShortQty, I.ShortQty AS IShortQty, D.ShReason AS DShReason, 
			I.ShReason AS IShReason, I.MiscKey, I.cSavedBy
			FROM Deleted D, Inserted I 
			WHERE D.MiscKey = I.MiscKey
			AND (D.ShortQty <> I.ShortQty 
			OR D.ShReason <> I.ShReason)
	
	SET @lnTotalNo = @@ROWCOUNT;
		
	IF (@lnTotalNo>0)
	BEGIN	
		SET @lnCount=0;
		WHILE @lnTotalNo>@lnCount
		BEGIN	
			SET @lnCount=@lnCount+1;
			SELECT @ZDShortQty = DShortQty, @ZIShortQty = IShortQty, @ZDShReason = DShReason, 
				@ZIShReason = IShReason, @ZMiscKey = MiscKey, @ZcSavedBy = cSavedBy
			FROM @ZDet WHERE nrecno = @lnCount;
			
			IF @@ROWCOUNT<> 0
			BEGIN
				EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT;
				INSERT INTO Miscdet (Misckey,ShReason,ShortQty,Shqualify,Shortbal,Auditdate,Auditby, MiscDetKey)
					VALUES (@ZMiscKey, @ZIShReason, @ZIShortQty - @ZDShortQty, 'EDT', @ZIShortQty, GETDATE(),
							@ZcSavedBy, @lcNewUniqNbr)
			END
		END
	END
	

	COMMIT

END







GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/13/2011
-- Description:	After Insert trigger for the MiscMain table, to insert MiscDet record 
-- =============================================
CREATE TRIGGER  [dbo].[MiscMain_Insert]
   ON  [dbo].[MISCMAIN] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION ;

	DECLARE @ZMiscKey char(10), @ZShReason char(15), @ZShortQty numeric(12,2), @ZcSavedBy char(8),
			@lcNewUniqNbr char(10);

	SELECT @ZMiscKey = Misckey, @ZShReason = ShReason, @ZShortQty = ShortQty, @ZcSavedBy = cSavedBy
		FROM Inserted 

	EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT;	
	INSERT INTO Miscdet (Misckey, ShReason, ShortQty, Shqualify, Shortbal, Auditdate, Auditby, MiscDetKey) 
		VALUES (@ZMiscKey, @ZShReason, @ZShortQty, 'ADD', @ZShortQty, GETDATE(), @ZcSavedBy, @lcNewUniqNbr)

	COMMIT

END







