CREATE TABLE [dbo].[PRODFETR] (
    [PRODTPUNIQ] CHAR (10) CONSTRAINT [DF__PRODFETR__PRODTP__4E0A543E] DEFAULT ('') NOT NULL,
    [PRODFEUNIQ] CHAR (10) CONSTRAINT [DF__PRODFETR__PRODFE__4EFE7877] DEFAULT ('') NOT NULL,
    [PDFETRUNIQ] CHAR (10) CONSTRAINT [DF__PRODFETR__PDFETR__4FF29CB0] DEFAULT ('') NOT NULL,
    [ISREQUIRED] BIT       CONSTRAINT [DF__PRODFETR__ISREQU__50E6C0E9] DEFAULT ((0)) NOT NULL,
    [ISEXCL]     BIT       CONSTRAINT [DF__PRODFETR__ISEXCL__51DAE522] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PRODFETR_PK] PRIMARY KEY CLUSTERED ([PDFETRUNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [PRODTPUNIQ]
    ON [dbo].[PRODFETR]([PRODTPUNIQ] ASC);


GO
-- =============================================
-- Author:		Vicky
-- Create date: 09/21/16
-- Description:	After Delete trigger for the Prodfetr table to delete child table ProdOptn records
-- =============================================
CREATE TRIGGER  [dbo].[ProdFetr_Delete]
   ON  [dbo].[PRODFETR] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION 

	DELETE FROM ProdOptn WHERE ProdtpUniq + PdFetrUniq IN (SELECT ProdtpUniq + PdFetrUniq FROM Deleted)

	COMMIT

END