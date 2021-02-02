CREATE TABLE [dbo].[KAMAIN] (
    [WONO]         CHAR (10)        CONSTRAINT [DF__KAMAIN__WONO__2E86BBED] DEFAULT ('') NOT NULL,
    [DEPT_ID]      CHAR (4)         CONSTRAINT [DF__KAMAIN__DEPT_ID__2F7AE026] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]     CHAR (10)        CONSTRAINT [DF__KAMAIN__UNIQ_KEY__306F045F] DEFAULT ('') NOT NULL,
    [ACT_QTY]      NUMERIC (12, 2)  CONSTRAINT [DF__KAMAIN__ACT_QTY__31632898] DEFAULT ((0)) NOT NULL,
    [KITCLOSED]    BIT              CONSTRAINT [DF__KAMAIN__KITCLOSE__32574CD1] DEFAULT ((0)) NOT NULL,
    [INITIALS]     CHAR (8)         CONSTRAINT [DF__KAMAIN__INITIALS__3533B97C] DEFAULT ('') NOT NULL,
    [ENTRYDATE]    SMALLDATETIME    CONSTRAINT [DF_KAMAIN_ENTRYDATE] DEFAULT (getdate()) NULL,
    [KASEQNUM]     CHAR (10)        CONSTRAINT [DF__KAMAIN__KASEQNUM__3627DDB5] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [BOMPARENT]    CHAR (10)        CONSTRAINT [DF__KAMAIN__BOMPAREN__371C01EE] DEFAULT ('') NOT NULL,
    [SHORTQTY]     NUMERIC (12, 2)  CONSTRAINT [DF__KAMAIN__SHORTQTY__38102627] DEFAULT ((0)) NOT NULL,
    [LINESHORT]    BIT              CONSTRAINT [DF__KAMAIN__LINESHOR__39044A60] DEFAULT ((0)) NOT NULL,
    [QTY]          NUMERIC (12, 2)  CONSTRAINT [DF__KAMAIN__QTY__39F86E99] DEFAULT ((0)) NOT NULL,
    [REF_DES]      CHAR (15)        CONSTRAINT [DF__KAMAIN__REF_DES__3AEC92D2] DEFAULT ('') NOT NULL,
    [IGNOREKIT]    BIT              CONSTRAINT [DF__KAMAIN__IGNOREKI__3BE0B70B] DEFAULT ((0)) NOT NULL,
    [sourceDev]    CHAR (1)         CONSTRAINT [DF_KAMAIN_sourceDev] DEFAULT ('D') NOT NULL,
    [allocatedQty] NUMERIC (12, 2)  CONSTRAINT [DF_KAMAIN_allocatedQty] DEFAULT ((0.00)) NOT NULL,
    [userid]       UNIQUEIDENTIFIER NULL,
    CONSTRAINT [KAMAIN_PK] PRIMARY KEY CLUSTERED ([KASEQNUM] ASC)
);


GO
CREATE NONCLUSTERED INDEX [SHORTUNIQ]
    ON [dbo].[KAMAIN]([WONO] ASC, [UNIQ_KEY] ASC, [DEPT_ID] ASC, [BOMPARENT] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[KAMAIN]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQWOPART]
    ON [dbo].[KAMAIN]([WONO] ASC, [UNIQ_KEY] ASC, [DEPT_ID] ASC, [BOMPARENT] ASC);


GO
CREATE NONCLUSTERED INDEX [WONO]
    ON [dbo].[KAMAIN]([WONO] ASC);


GO
CREATE NONCLUSTERED INDEX [WOPARTNO]
    ON [dbo].[KAMAIN]([WONO] ASC, [UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [IXKAMAIN_User]
    ON [dbo].[KAMAIN]([userid] ASC);


GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 08/29/14
-- Description:	Insert trigger for Kamain table
-- Modified:
-- =============================================
CREATE TRIGGER [dbo].[Kamain_Insert]
   ON  dbo.KAMAIN
   AFTER INSERT
AS 
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- Insert statements for trigger here

DECLARE @Kaseqnum char(10), @Wono char(10), @UserId char(8), @OpenClos char(10), @IsFirstTime bit

SELECT @Kaseqnum = Kaseqnum, @Wono = Wono, @UserId = Initials FROM inserted
SELECT @OpenClos = OpenClos FROM WOENTRY WHERE WONO = @Wono

-- if Only first time
SELECT @IsFirstTime = CASE WHEN NOT EXISTS (SELECT 1 FROM KAMAIN WHERE WONO = @Wono AND KASEQNUM <> @Kaseqnum) THEN 1 ELSE 0 END

IF NOT EXISTS(Select 1 from Inserted where Inserted.sourceDev='D')
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
	-- If OpenClos <> 'Rework' or 'ReworkFirm' and it's first time to add, will udate KitStatus to 'KIT PROCSS'
	-- If OpenClos = 'Rework' or 'ReworkFirm', will keep old kitstatus

		UPDATE Woentry	SET KitStatus = CASE WHEN @IsFirstTime = 1 THEN
				CASE WHEN (@OpenClos <> 'Rework' AND @OpenClos <> 'ReworkFirm') THEN 'KIT PROCSS' ELSE KITSTATUS END 
				ELSE KITSTATUS END,
			Start_date = ISNULL(Start_date,GETDATE()),
			KITSTARTINIT = CASE WHEN KITSTARTINIT = '' THEN @UserId ELSE KITSTARTINIT END,
			KITLSTCHDT = GETDATE(),
			KITLSTCHINIT = @Userid
			WHERE WONO = @Wono

		IF @IsFirstTime = 1
		BEGIN
			EXEC dbo.sp_UpdOneWOChkLst @Wono, 'KIT IN PROCESS', @UserId
		END

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT >0
		ROLLBACK TRANSACTION ;
		RETURN
	END CATCH

	IF @@TRANCOUNT >0
		COMMIT TRANSACTION ;	
		
END
						
END