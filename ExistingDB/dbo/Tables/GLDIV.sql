CREATE TABLE [dbo].[GLDIV] (
    [UNIQDIV]   CHAR (10) CONSTRAINT [DF__GLDIV__UNIQDIV__63AEB143] DEFAULT ('') NOT NULL,
    [GLDIVNO]   CHAR (2)  CONSTRAINT [DF__GLDIV__GLDIVNO__64A2D57C] DEFAULT ('') NOT NULL,
    [GLDIVNAME] CHAR (25) CONSTRAINT [DF__GLDIV__GLDIVNAME__6596F9B5] DEFAULT ('') NOT NULL,
    [LLOCALDIV] BIT       CONSTRAINT [DF__GLDIV__LLOCALDIV__668B1DEE] DEFAULT ((0)) NOT NULL,
    [LHQ]       BIT       CONSTRAINT [DF__GLDIV__LHQ__677F4227] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [GLDIV_PK] PRIMARY KEY CLUSTERED ([UNIQDIV] ASC)
);


GO
CREATE NONCLUSTERED INDEX [GLDIVNO]
    ON [dbo].[GLDIV]([GLDIVNO] ASC);


GO

-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <11/03/2009>
-- Description:	<Delete Trigger for the GlDiv. When record is deleted need to remove record from GLDEP table>
-- =============================================
CREATE TRIGGER [dbo].[GlDiv_Delete] 
   ON  [dbo].[GLDIV]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION 
	-- Insert statements for trigger here
	DELETE FROM GLDEP WHERE GlDivNo IN (SELECT GlDivNo FROM DELETED)
	COMMIT
END

