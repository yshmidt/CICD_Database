-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/06/2016
-- Description:	Import Beginning Inventory Qty OH
-- =============================================
CREATE PROCEDURE [dbo].[importBeginningInventoryQty] 
	-- Add the parameters for the stored procedure here
	@qtyimportId char(10) = null
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @ErrorMessage NVARCHAR(4000),
    @ErrorSeverity INT,
    @ErrorState INT,
	@gl_nbr char(13) = null ,
	@gl_nbr_issue char(13) = null;
	
	BEGIN TRY
	BEGIN TRANSACTION
		-- check if the impotrt with the given ID exists
		if @qtyimportId is null or not exists (select 1 from importBeginningInventoryHeader where qtyImportId=@qtyimportId and importComplete=0)
			RAISERROR ('Cannot find a record in the importBeginningInventoryHeader table with the given import Id.', -- Message text.
				   16, -- Severity.
					1 -- State.
				);

		-- add validations
		-- for now just go and create invt_rec
		-- get first gl_nbr from the setup for the inventory manual receiving
		select top 1 @gl_nbr=gl_nbr from InvtGls where REC_TYPE='R' order by DESCRIPT
		if @gl_nbr is null
			RAISERROR ('Cannot find a Inventory Receiving G/L account.', -- Message text.
				   16, -- Severity.
					1 -- State.
				);
		select top 1 @gl_nbr_issue=gl_nbr from InvtGls where REC_TYPE='I' order by DESCRIPT
		if @gl_nbr_issue is null
			RAISERROR ('Cannot find a Inventory Issue G/L account.', -- Message text.
				   16, -- Severity.
					1 -- State.
				);

		--- find only records that have qty_oh>invtmfgr.qty_oh
		;with
		Receiv
		as
		(
		SELECT 
			D.[w_key]
           ,D.[UNIQ_KEY]
           ,D.[QTY_OH]-M.qty_oh as [QTYREC]
           ,'BEGINNING RAW MATL. INV.' as [COMMREC]
           ,@GL_NBR as GL_NBR
           ,dbo.fn_generateuniquenumber() as [INVTREC_NO]
           ,d.[LOTCODE]
           ,d.[EXPDATE]
           ,d.[REFERENCE]
           ,'Upload' as [SAVEINIT]
           ,M.[UNIQMFGRHD]
           ,H.[importUserId] as [fk_userid]
           ,'D' as [sourceDev]
		   FROM importBeginningInventoryDetails D inner join importBeginningInventoryHeader h ON d.qtyImportId =H.qtyImportId 
		   inner join Invtmfgr M on d.w_key=M.W_KEY
		   left outer join InvtLot on d.w_key=Invtlot.w_key and d.lotcode=invtlot.lotcode
		   and (d.expdate is null and invtlot.expdate is null) or ( d.expdate=invtlot.expdate)
		   and d.reference=invtlot.reference
		   where D.qtyImportId=@qtyimportId
		   and M.qty_oh<d.qty_oh
		   )
		   	
		INSERT INTO [dbo].[INVT_REC]
           ([W_KEY]
           ,[UNIQ_KEY]
           ,[QTYREC]
           ,[COMMREC]
           ,[GL_NBR]
           ,[INVTREC_NO]
           ,[LOTCODE]
           ,[EXPDATE]
           ,[REFERENCE]
           ,[SAVEINIT]
           ,[UNIQMFGRHD]
           ,[fk_userid]
           ,[sourceDev])
		   SELECT 
			R.[w_key]
           ,R.[UNIQ_KEY]
           ,R.[QTYREC]
           ,R.[COMMREC]
           ,R.GL_NBR
           ,R.[INVTREC_NO]
           ,R.[LOTCODE]
           ,R.[EXPDATE]
           ,R.[REFERENCE]
           ,SAVEINIT
           ,R.[UNIQMFGRHD]
           ,R.[fk_userid]
           ,R.[sourceDev]
		   FROM Receiv R
		   --- find only records that have qty_oh<invtmfgr.qty_oh
			;with
			Issue
			as
			(
			SELECT 
			D.[w_key]
           ,D.[UNIQ_KEY]
		   ,'Inventory Adjustment          ' as [ISSUEDTO]
           ,M.qty_oh-D.[QTY_OH] as [QTYISU]
           ,@gl_nbr_issue as GL_NBR
           ,dbo.fn_generateuniquenumber() as [INVTISU_NO]
           ,d.[LOTCODE]
           ,d.[EXPDATE]
           ,d.[REFERENCE]
		   ,d.ponum
		   ,'Upload' as [SAVEINIT]
           ,M.[UNIQMFGRHD]
           ,H.[importUserId] as [fk_userid]
           ,'D' as [sourceDev]
		   FROM importBeginningInventoryDetails D inner join importBeginningInventoryHeader h ON d.qtyImportId =H.qtyImportId 
		   inner join Invtmfgr M on d.w_key=M.W_KEY
		   left outer join InvtLot on d.w_key=Invtlot.w_key and d.lotcode=invtlot.lotcode
		   and (d.expdate is null and invtlot.expdate is null) or ( d.expdate=invtlot.expdate)
		   and d.reference=invtlot.reference
		   where D.qtyImportId=@qtyimportId
		   and M.qty_oh<d.qty_oh
		   )

		  INSERT INTO [dbo].[INVT_ISU]
           ([W_KEY]
           ,[UNIQ_KEY]
           ,[ISSUEDTO]
           ,[QTYISU]
           ,[GL_NBR]
           ,[INVTISU_NO]
           ,[LOTCODE]
           ,[EXPDATE]
           ,[REFERENCE]
			,[PONUM]
           ,[SAVEINIT]
           ,[INSTORERETURN]
           ,[UNIQMFGRHD]
           ,[CMODID]
           ,[fk_userid]
           ,[sourceDev])
     SELECT
		[W_KEY]
           ,[UNIQ_KEY]
           ,[ISSUEDTO]
           ,[QTYISU]
           ,[GL_NBR]
           ,[INVTISU_NO]
           ,[LOTCODE]
           ,[EXPDATE]
           ,[REFERENCE]
			,[PONUM]
           ,[SAVEINIT]
           ,0
           ,[UNIQMFGRHD]
           ,'I'
           ,[fk_userid]
           ,[sourceDev]
	 from Issue
      update importBeginningInventoryHeader set importComplete =1 where qtyImportId=@qtyimportId

	END TRY
	
	BEGIN CATCH
		IF @@TRANCOUNT>0
		ROLLBACK

		SELECT @ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );

	END CATCH
	IF @@TRANCOUNT>0
		COMMIT
END