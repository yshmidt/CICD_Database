CREATE TABLE [dbo].[NOTESETUP] (
    [NOTENAME]   CHAR (25) CONSTRAINT [DF__NOTESETUP__NOTEN__41B98BF2] DEFAULT ('') NOT NULL,
    [NOTETEXT]   TEXT      CONSTRAINT [DF__NOTESETUP__NOTET__42ADB02B] DEFAULT ('') NOT NULL,
    [NOTEUNIQUE] CHAR (10) CONSTRAINT [DF__NOTESETUP__NOTEU__43A1D464] DEFAULT ('') NOT NULL,
    CONSTRAINT [NOTESETUP_PK] PRIMARY KEY CLUSTERED ([NOTEUNIQUE] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NOTENAME]
    ON [dbo].[NOTESETUP]([NOTENAME] ASC);


GO

-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/17/2009
-- Description:	After Delete trigger for the NoteSetup table
-- =============================================
CREATE TRIGGER  [dbo].[fNoteSetup_Delete]
   ON  [dbo].[NOTESETUP] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DELETE FROM NoteAssign WHERE fknoteunique IN (SELECT NoteUnique FROM DELETED)
END
