CREATE TABLE [dbo].[receiverDetail] (
    [receiverHdrId]   CHAR (10)       CONSTRAINT [DF_receiverDetail_receiverHdrId] DEFAULT ('') NOT NULL,
    [uniqlnno]        CHAR (10)       CONSTRAINT [DF_receiverDetail_uniqlnno] DEFAULT ('') NOT NULL,
    [Uniq_key]        CHAR (10)       CONSTRAINT [DF_receiverDetail_Uniq_key] DEFAULT ('') NOT NULL,
    [Partmfgr]        CHAR (8)        CONSTRAINT [DF_receiverDetail_Partmfgr] DEFAULT ('') NOT NULL,
    [mfgr_pt_no]      CHAR (30)       CONSTRAINT [DF_receiverDetail_mfgr_pt_no] DEFAULT ('') NOT NULL,
    [Qty_rec]         NUMERIC (10, 2) CONSTRAINT [DF_receiverDetail_Qty_rec] DEFAULT ((0.00)) NOT NULL,
    [isinspReq]       BIT             CONSTRAINT [DF_receiverDetail_isinspReq] DEFAULT ((0)) NOT NULL,
    [isinspCompleted] BIT             CONSTRAINT [DF_receiverDetail_isinspCompleted] DEFAULT ((0)) NOT NULL,
    [isCompleted]     BIT             CONSTRAINT [DF_receiverDetail_isCompleted] DEFAULT ((0)) NOT NULL,
    [receiverDetId]   CHAR (10)       CONSTRAINT [DF_receiverDetail_receiverDetId] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [QtyPerPackage]   NUMERIC (12, 2) NULL,
    [GL_NBR]          CHAR (13)       CONSTRAINT [DF__receiverD__GL_NB__06B1CD70] DEFAULT (NULL) NULL,
    CONSTRAINT [PK_receiverDetail] PRIMARY KEY CLUSTERED ([receiverDetId] ASC),
    CONSTRAINT [FK_receiverDetail_receiverHeader] FOREIGN KEY ([receiverHdrId]) REFERENCES [dbo].[receiverHeader] ([receiverHdrId]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_receiverDetail]
    ON [dbo].[receiverDetail]([receiverHdrId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_rditem]
    ON [dbo].[receiverDetail]([uniqlnno] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_rdpart]
    ON [dbo].[receiverDetail]([Uniq_key] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_rdmpn]
    ON [dbo].[receiverDetail]([mfgr_pt_no] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_rdpartmfgr]
    ON [dbo].[receiverDetail]([Partmfgr] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_receiverDetail_1]
    ON [dbo].[receiverDetail]([isinspReq] ASC);


GO
-- ==========================================================================================
-- Author:		Nitesh B
-- Create date: 05/16/2016
-- Description:	Update the receiving status status based on receiverDetail.isCompleted
-- Nilesh Sa 3/12/2018 :Update received headers recStatus,completeDate based receiver details records
-- Nilesh Sa 3/12/2018 :Update completeBy,completeDate if receipt not complete
-- ==========================================================================================
CREATE TRIGGER [dbo].[ReceiverDetail_Insert]
   ON  [dbo].[receiverDetail] 
   AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @isCompleted bit
	-- Nilesh Sa 3/12/2018 :Update received headers recStatus,completeDate based receiver details records
	-- SELECT @isCompleted = isCompleted from inserted

	SELECT * FROM receiverDetail WHERE isCompleted = 0 AND receiverHdrId = (select receiverHdrId from inserted)

	IF @@ROWCOUNT = 0
		BEGIN
		   SET @isCompleted = 1
		END
    ELSE 
		BEGIN
		   SET @isCompleted = 0
		END

	IF @isCompleted = 1
		BEGIN
		  Update receiverHeader set recStatus='Complete',completeDate= GETDATE() where receiverHdrId = (select receiverHdrId from inserted) 
		END
	ELSE
		BEGIN
		-- Nilesh Sa 3/12/2018 :Update completeBy,completeDate if receipt not complete
		  Update receiverHeader set recStatus='In Process',completeBy=null,completeDate=null where receiverHdrId = (select receiverHdrId from inserted) 
		END
END


GO
-- ==========================================================================================
-- Author:		Nilesh Sa
-- Create date: 3/12/2018
-- Description:	Update the receiving status status based on receiverDetail.isCompleted
-- Nilesh Sa 3/12/2018 :Update received headers recStatus,completeDate based receiver details records
-- Nilesh Sa 3/12/2018 :Update completeBy,completeDate if receipt not complete
-- ==========================================================================================
CREATE TRIGGER [dbo].[ReceiverDetail_Update]
   ON  [dbo].[receiverDetail] 
   AFTER UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @isCompleted bit
	-- Nilesh Sa 3/12/2018 :Update received headers recStatus,completeDate based receiver details records
	-- SELECT @isCompleted = isCompleted from inserted
	SELECT * FROM receiverDetail WHERE isCompleted = 0 AND receiverHdrId = (select receiverHdrId from inserted)

	IF @@ROWCOUNT = 0
		BEGIN
		   SET @isCompleted = 1
		END
    ELSE 
		BEGIN
		   SET @isCompleted = 0
		END

	IF @isCompleted = 1
		BEGIN
		  Update receiverHeader set recStatus='Complete',completeDate= GETDATE() where receiverHdrId = (select receiverHdrId from inserted) 
		END
	ELSE
		BEGIN
			-- Nilesh Sa 3/12/2018 :Update completeBy,completeDate if receipt not complete
		  Update receiverHeader set recStatus='In Process' where receiverHdrId = (select receiverHdrId from inserted) 
		END
END

