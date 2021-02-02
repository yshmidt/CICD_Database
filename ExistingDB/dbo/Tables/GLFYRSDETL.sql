CREATE TABLE [dbo].[GLFYRSDETL] (
    [FK_FY_UNIQ] CHAR (10)        CONSTRAINT [DF__GLFYRSDET__FY_UN__1451E89E] DEFAULT ('') NOT NULL,
    [FYDTLUNIQ]  UNIQUEIDENTIFIER CONSTRAINT [DF__GLFYRSDET__FYDTL__15460CD7] DEFAULT (newsequentialid()) NOT NULL,
    [PERIOD]     NUMERIC (2)      CONSTRAINT [DF__GLFYRSDET__PERIO__163A3110] DEFAULT ((0)) NOT NULL,
    [ENDDATE]    SMALLDATETIME    NULL,
    [cDescript]  CHAR (20)        CONSTRAINT [DF_GLFYRSDETL_cDescript] DEFAULT ('') NOT NULL,
    [lClosed]    BIT              CONSTRAINT [DF_GLFYRSDETL_lClosed] DEFAULT ((0)) NOT NULL,
    [lCurrent]   BIT              CONSTRAINT [DF_GLFYRSDETL_lCurrent] DEFAULT ((0)) NOT NULL,
    [nQtr]       NUMERIC (1)      CONSTRAINT [DF_GLFYRSDETL_nQtr] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [GLFYRSDETL_PK] PRIMARY KEY CLUSTERED ([FYDTLUNIQ] ASC),
    CONSTRAINT [FK_GLFYRSDETL_GLFISCALYRS] FOREIGN KEY ([FK_FY_UNIQ]) REFERENCES [dbo].[GLFISCALYRS] ([FY_UNIQ]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [ENDDATE]
    ON [dbo].[GLFYRSDETL]([ENDDATE] ASC);


GO
CREATE NONCLUSTERED INDEX [FY_UNIQ]
    ON [dbo].[GLFYRSDETL]([FK_FY_UNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [FyPeriod]
    ON [dbo].[GLFYRSDETL]([FK_FY_UNIQ] ASC, [PERIOD] ASC);


GO
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/23/2009>
-- Description:	<UPDATE Trigger for the GlFyrsDetl.>
-- =============================================
CREATE TRIGGER [dbo].[GlFyrsDetl_Update]
   ON  [dbo].[GLFYRSDETL]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for trigger here
	-- insert audit record	
	 BEGIN TRANSACTION
		INSERT AuditFYDtl (Fk_fy_uniq,Fk_FyDtlUniq,UserId,changetype,changetext) SELECT Inserted.fk_fy_uniq,Inserted.FyDtlUniq,SUSER_SNAME(),'U','List of  Changes for Fiscal Year :' +GlFiscalYrs.FiscalYr+
			CASE WHEN Deleted.Period<>Inserted.Period then 'Changed Period from '+CAST(Deleted.Period as char(2))+' to '+CAST(Inserted.Period as char(2)) else '' END +
			CASE WHEN Deleted.EndDate<>Inserted.EndDate then 'Changed EndDate from '+CONVERT(CHAR(20),Deleted.EndDate,120)+' to '+CONVERT(CHAR(20),Inserted.EndDate,120) ELSE '' END +
			CASE WHEN Deleted.lClosed<>Inserted.lClosed then 'Changed Closed flag from '+CASE WHEN Deleted.lClosed=1 Then 'Closed' ELSE 'Open' END +
			' to '+CASE WHEN Inserted.lClosed=1 Then 'Closed' ELSE 'Open' END ELSE '' END +
			CASE WHEN Deleted.nQtr<>Inserted.nQtr then 'Changed Quoter number from '+CAST(Deleted.nQtr as char(1))+' to '+CAST(Inserted.nQtr as char(1)) else '' END
			FROM INSERTED,DELETED,GlFiscalYrs WHERE Inserted.FyDtlUniq = DELETED.FyDtlUniq and Inserted.fk_fy_uniq=GlFiscalYrs.fy_uniq ;
	COMMIT
END

GO
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/01/2009>
-- Description:	<INSERT Trigger for the GlFyrsDetl. When record is inserted need to insert new records into GL_ACCT table>
-- =============================================
CREATE TRIGGER [dbo].[GlFyrsDetl_Insert]
   ON  [dbo].[GLFYRSDETL]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION 
	INSERT INTO GL_ACCT (GL_NBR,FK_FYDTLUNIQ) SELECT GL_NBRS.GL_NBR,INSERTED.FYDTLUNIQ from GL_NBRS CROSS JOIN INSERTED
	COMMIT
    -- Insert statements for trigger here
	-- insert audit record	
	 BEGIN TRANSACTION
	INSERT AuditFYDtl (Fk_fy_uniq,Fk_FyDtlUniq,UserId,changetype,changetext) SELECT fk_fy_uniq,FyDtlUniq,SUSER_SNAME(),'I','Insert Period '+CAST(Inserted.Period as char(2))+
	' for Fiscal Year '+CASE WHEN GlFiscalYrs.FiscalYr IS NULL THEN Inserted.fk_fy_uniq ELSE GlFiscalYrs.FiscalYr END FROM INSERTED LEFT OUTER JOIN GlFiscalYrs ON INSERTED.Fk_fy_uniq=GlFiscalYrs.Fy_uniq
	COMMIT
END

GO
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/01/2009>
-- Description:	<Delete Trigger for the GlFyrsDetl. When record is deleted need to remove record from GL_ACCT table>
-- =============================================
CREATE TRIGGER [dbo].[GlFyrsDetl_Delete] 
   ON  [dbo].[GLFYRSDETL]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION 
	DELETE FROM GL_ACCT WHERE Fk_FyDtlUniq IN (SELECT FyDtlUniq FROM DELETED)
	COMMIT
    -- Insert statements for trigger here
	-- insert audit record
	BEGIN TRANSACTION
	INSERT AuditFYDtl (Fk_fy_uniq,Fk_FyDtlUniq,UserId,changetype,changetext) SELECT fk_fy_uniq,FyDtlUniq,SUSER_SNAME(),'D','Deleted Period '+CAST(Deleted.Period as char(2))+
	' for Fiscal Year '+CASE WHEN GlFiscalYrs.FiscalYr IS NULL THEN Deleted.fk_fy_uniq ELSE GlFiscalYrs.FiscalYr END FROM DELETED LEFT OUTER JOIN GlFiscalYrs ON DELETED.Fk_fy_uniq=GlFiscalYrs.Fy_uniq
	COMMIT
END
