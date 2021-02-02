-- =============================================
-- Author:		Satish B
-- Create date: 4/27/2018
-- Description:	Add po import Header details
-- =============================================
CREATE PROCEDURE [dbo].[ImportPOMainAdd] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,@startedBy varchar(4),@completeDate smalldatetime='',@completedBy varchar(4)='',@message varchar(MAX)='',
	@poNum varchar(15)='',@supplier varchar(30)='',@terms varchar(20),@buyer varchar(30)='',@priority varchar(10)='',@confTo varchar(20)='',@poDate smalldatetime='',@status varchar(10)='NEW',
	@lFreightInclude bit=0,@poNote varchar(MAX)='',@shipChgAMT varchar(20)='',@is_SCTAX bit = 0,@sc_TaxPct varchar(20)='',@shipCharge varchar(20)='',@shipVia varchar(20)='',@fob varchar(20)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	select * from importpomain
	INSERT INTO [dbo].[ImportPOMain]
           ([POImportId]
           ,[Status]
           ,[CompleteDate]
           ,[CompletedBy]
           ,[Message]
           ,[PONumber]
           ,[Supplier]
		   ,[Terms]
           ,[Buyer]
           ,[Priority]
           ,[PODate]
           ,[ConfTo]
		   ,[LFreightInclude]
		   ,[PONote]
		   ,[ShipChgAMT]
		   ,[IS_SCTAX]
		   ,[SC_TAXPCT]
		   ,[ShipCharge] 
	       ,[ShipVia] 
	       ,[Fob] )
     VALUES
           (@importId
           ,@status
           ,@completeDate
           ,@completedBy
           ,@message
           ,@poNum
           ,@supplier
		   ,@terms
           ,@buyer
           ,@priority
		   ,@poDate
           ,@confTo
		   ,@lFreightInclude
		   ,@poNote
		   ,CASE WHEN @shipChgAMT ='' THEN 0 ELSE @shipChgAMT END
		   ,@is_SCTAX
		   ,CASE WHEN @sc_TaxPct ='' THEN 0 ELSE @sc_TaxPct END
		   ,@shipCharge
		   ,@shipVia
		   ,@fob)
           
END