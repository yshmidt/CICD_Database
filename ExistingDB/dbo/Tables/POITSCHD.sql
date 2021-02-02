CREATE TABLE [dbo].[POITSCHD] (
    [UNIQLNNO]     CHAR (10)       CONSTRAINT [DF__POITSCHD__UNIQLN__53391DAF] DEFAULT ('') NOT NULL,
    [UNIQDETNO]    CHAR (10)       CONSTRAINT [DF__POITSCHD__UNIQDE__542D41E8] DEFAULT ('') NOT NULL,
    [SCHD_DATE]    SMALLDATETIME   NULL,
    [REQ_DATE]     SMALLDATETIME   NULL,
    [SCHD_QTY]     NUMERIC (10, 2) CONSTRAINT [DF__POITSCHD__SCHD_Q__55216621] DEFAULT ((0)) NOT NULL,
    [RECDQTY]      NUMERIC (10, 2) CONSTRAINT [DF__POITSCHD__RECDQT__56158A5A] DEFAULT ((0)) NOT NULL,
    [BALANCE]      NUMERIC (10, 2) CONSTRAINT [DF__POITSCHD__BALANC__5709AE93] DEFAULT ((0)) NOT NULL,
    [GL_NBR]       CHAR (13)       CONSTRAINT [DF__POITSCHD__GL_NBR__57FDD2CC] DEFAULT ('') NOT NULL,
    [REQUESTTP]    CHAR (10)       CONSTRAINT [DF__POITSCHD__REQUES__58F1F705] DEFAULT ('') NOT NULL,
    [REQUESTOR]    CHAR (40)       CONSTRAINT [DF__POITSCHD__REQUES__59E61B3E] DEFAULT ('') NOT NULL,
    [UNIQWH]       CHAR (10)       CONSTRAINT [DF__POITSCHD__UNIQWH__5CC287E9] DEFAULT ('') NOT NULL,
    [LOCATION]     NVARCHAR (200)  CONSTRAINT [DF__POITSCHD__LOCATI__5DB6AC22] DEFAULT ('') NOT NULL,
    [WOPRJNUMBER]  CHAR (10)       CONSTRAINT [DF__POITSCHD__WOPRJN__5EAAD05B] DEFAULT ('') NOT NULL,
    [COMPLETEDT]   SMALLDATETIME   NULL,
    [PONUM]        CHAR (15)       CONSTRAINT [DF__POITSCHD__PONUM__5F9EF494] DEFAULT ('') NOT NULL,
    [ORIGCOMMITDT] SMALLDATETIME   NULL,
    [SCHDNOTES]    TEXT            CONSTRAINT [DF__POITSCHD__SCHDNO__609318CD] DEFAULT ('') NOT NULL,
    CONSTRAINT [POITSCHD_PK] PRIMARY KEY CLUSTERED ([UNIQDETNO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
    ON [dbo].[POITSCHD]([BALANCE] ASC)
    INCLUDE([UNIQLNNO], [SCHD_DATE], [SCHD_QTY], [REQUESTTP], [UNIQWH], [WOPRJNUMBER]);


GO
CREATE NONCLUSTERED INDEX [POITSCHD]
    ON [dbo].[POITSCHD]([UNIQLNNO] ASC, [SCHD_DATE] ASC);


GO
CREATE NONCLUSTERED INDEX [SCHD_DATE]
    ON [dbo].[POITSCHD]([SCHD_DATE] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQLNNO]
    ON [dbo].[POITSCHD]([UNIQLNNO] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/13/2012
-- Description: Create Delete trigger to check if the line deleted was not received at the last moment. 
-- If two screens open and PO is in the edit mode while received item then receipt saved, and schedule removed, will create an issue (ticket 6550)
-- =============================================
CREATE TRIGGER [dbo].[Poitschd_Delete]
   ON  dbo.POITSCHD 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    BEGIN TRANSACTION
    DECLARE @RECEIVERNO char(10)=' '
    SELECT TOP 1 @RECEIVERNO=RECEIVERNO  
	 FROM Porecloc 
	 WHERE Uniqdetno IN (SELECT UniqDetNo FROM deleted )
	 AND (AccptQty > 0 OR RejQty>0) ORDER BY Receiverno 
	 IF @@ROWCOUNT <> 0
	 BEGIN
	 -- -raise an error
	 RAISERROR('System was trying to remove schedule line, which was used by Receiver Number %s . '
				,1 -- Severity
				,1  -- State
				,@RECEIVERNO )  -- receiver number				
		ROLLBACK TRANSACTION
		RETURN 
	END
	COMMIT
END