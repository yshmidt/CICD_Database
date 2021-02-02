-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/21/12 
-- Description:	Trunctae MRP tables prior to runnning new MRP
---  Modified 09/14/17 YS added MrpSupplyDemand table
-- =============================================
CREATE PROCEDURE [dbo].[SP_MRPTruncate]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	TRUNCATE TABLE MRPSUPPL ;
	TRUNCATE TABLE MpsSch ;
	TRUNCATE TABLE MrpInvt ;
	TRUNCATE TABLE MrpWh ;
	TRUNCATE TABLE MrpAct ;
	TRUNCATE TABLE MrpSch2 ;
	TRUNCATE TABLE MrpPoHst ;
	TRUNCATE TABLE MrpPo ;
	TRUNCATE TABLE MrpUsed ;
	--09/14/17 YS added MrpSupplyDemand table
	TRUNCATE TABLE MrpSupplyDemand ;

END