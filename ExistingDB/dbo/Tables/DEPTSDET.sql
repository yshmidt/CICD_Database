CREATE TABLE [dbo].[DEPTSDET] (
    [DEPT_ID]    CHAR (4)    CONSTRAINT [DF__DEPTSDET__DEPT_I__36BC0F3B] DEFAULT ('') NOT NULL,
    [ACTIV_ID]   CHAR (4)    CONSTRAINT [DF__DEPTSDET__ACTIV___37B03374] DEFAULT ('') NOT NULL,
    [NUMBER]     NUMERIC (4) CONSTRAINT [DF__DEPTSDET__NUMBER__38A457AD] DEFAULT ((0)) NOT NULL,
    [deptsdetuk] CHAR (10)   CONSTRAINT [DF_DEPTSDET_deptsdetuk] DEFAULT ('') NOT NULL,
    CONSTRAINT [DEPTSDET_PK] PRIMARY KEY CLUSTERED ([deptsdetuk] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ACTIV_ID]
    ON [dbo].[DEPTSDET]([ACTIV_ID] ASC);


GO
CREATE NONCLUSTERED INDEX [DEPT_ID]
    ON [dbo].[DEPTSDET]([DEPT_ID] ASC);


GO
CREATE NONCLUSTERED INDEX [DEPTNUMBER]
    ON [dbo].[DEPTSDET]([DEPT_ID] ASC, [NUMBER] ASC);


GO
CREATE NONCLUSTERED INDEX [NUMBER]
    ON [dbo].[DEPTSDET]([NUMBER] ASC);


GO
-- Create Trigger DeptsDet_Delete
--Print 'Create Trigger DeptsDet_Delete'
--GO

-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/20/2009
-- Description:	After Delete trigger for the DeptsDet table
-- =============================================
CREATE TRIGGER  [dbo].[DeptsDet_Delete]
   ON  [dbo].[DEPTSDET] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION 
	DELETE FROM ACTIVITY WHERE Activ_id IN (SELECT Activ_id FROM DELETED) 
	COMMIT

END
