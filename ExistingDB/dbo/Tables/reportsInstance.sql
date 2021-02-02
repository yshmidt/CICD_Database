CREATE TABLE [dbo].[reportsInstance] (
    [instanceId] UNIQUEIDENTIFIER CONSTRAINT [DF__reportsIn__insta__544ED427] DEFAULT (newid()) NOT NULL,
    [runDate]    SMALLDATETIME    CONSTRAINT [DF__reportsIn__runDa__5542F860] DEFAULT (getdate()) NOT NULL,
    [params]     VARCHAR (MAX)    CONSTRAINT [DF__reportsIn__param__56371C99] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_reportsInstance] PRIMARY KEY CLUSTERED ([instanceId] ASC)
);


GO
-- =============================================
-- Author:		Anuj Kumar
-- Create date: 
-- Description:	inserrt trigger for reportsInstance table that will delete a record after 24 hrs
-- =============================================
CREATE TRIGGER [dbo].[reportsInstance_Insert] ON [dbo].[reportsInstance] 
	AFTER INSERT
AS

BEGIN --BEGIN

SET NOCOUNT ON;

BEGIN TRANSACTION --BEGIN TRANSACTION

BEGIN TRY
-- Delete 24 hrs old record from the reportInstance table

	DELETE FROM reportsInstance where DATEDIFF(HH,runDate,GETDATE())>=24

END TRY --END TRY

BEGIN CATCH --BEGIN CATCH

--IF EXCEPTION OCCURS ROLLBACK TRANSACTION
	if @@TRANCOUNT<>0
		ROLLBACK TRANSACTION;

END CATCH --End Catch

if @@TRANCOUNT<>0
	COMMIT; --End Transaction

END --End


