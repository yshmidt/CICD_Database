CREATE TABLE [dbo].[DMRDetail] (
    [DMRUNIQUE]    CHAR (10)       NOT NULL,
    [dmrDetailId]  CHAR (10)       CONSTRAINT [DF_DMRDetail_dmrDetailId] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [inspHeaderId] CHAR (10)       CONSTRAINT [DF__DMRDetail__FK_UN__1AD72B00] DEFAULT ('') NOT NULL,
    [RET_QTY]      NUMERIC (12, 2) CONSTRAINT [DF_DMRDetail_RET_QTY] DEFAULT ((0.00)) NOT NULL,
    [uniq_key]     CHAR (10)       CONSTRAINT [DF_DMRDetail_uniq_key] DEFAULT ('') NOT NULL,
    [Uniqmfgrhd]   CHAR (10)       CONSTRAINT [DF_DMRDetail_Uniqmfgrhd] DEFAULT ('') NOT NULL,
    [costeach]     NUMERIC (15, 7) CONSTRAINT [DF_DMRDetail_costeach] DEFAULT ((0.00)) NOT NULL,
    [isTax]        BIT             CONSTRAINT [DF_DMRDetail_isTax] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DMRDetail] PRIMARY KEY CLUSTERED ([dmrDetailId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_DMRDetail]
    ON [dbo].[DMRDetail]([DMRUNIQUE] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DMRDetail_1]
    ON [dbo].[DMRDetail]([inspHeaderId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DMRDetail_2]
    ON [dbo].[DMRDetail]([Uniqmfgrhd] ASC);


GO
-- =============================================
-- Author: Khandu N	
-- Create date: <07/20/16>
-- Description:	Update DMR details and return quantity while adding or updating line items
-- Modified : Satish B : 05/04/2018 : Declare @ErrorMessage,@ErrorSeverity,@ErrorState for error handling
--			: Satish B : 05/04/2018 : Implement BEGIN TRANSACTION,BEGIN TRY,BEGIN CATCH for error handling
-- =============================================

CREATE TRIGGER [dbo].[ReturnQty_UPDATE]
	ON [dbo].[DMRDetail]
AFTER INSERT,UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @inspHeaderId char(10);
	DECLARE @dmrRQTY numeric(12,2);
	--Satish B : 05/04/2018 : Declare @ErrorMessage,@ErrorSeverity,@ErrorState for error handling
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

	--Update retun qty and buyer action when the user update/add return quantity for line items
	SELECT @inspHeaderId= inspHeaderId from inserted
	SELECT @dmrRQTY = SUM(dmrDtl.RET_QTY) from [DMRDetail] dmrDtl where  dmrDtl.inspHeaderId = @inspHeaderId
	--Satish B : 05/04/2018 : Implement BEGIN TRANSACTION,BEGIN TRY,BEGIN CATCH for error handling
	BEGIN TRANSACTION
		BEGIN TRY
			UPDATE inspectionHeader set ReturnQty= @dmrRQTY where inspHeaderId = @inspHeaderId
		END TRY	
		BEGIN CATCH
			IF @@TRANCOUNT <>0
				ROLLBACK TRAN ;
					SELECT @ErrorMessage = ERROR_MESSAGE(),
						   @ErrorSeverity = ERROR_SEVERITY(),
						   @ErrorState = ERROR_STATE();
					RAISERROR (@ErrorMessage, -- Message text.
							   @ErrorSeverity, -- Severity.
							   @ErrorState -- State.
							   );
		END CATCH	
	IF @@TRANCOUNT>0
	COMMIT TRANSACTION
END


