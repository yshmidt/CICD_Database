-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/21/13
-- Description:	Procedure will check in PorecMRB 
-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
-- 05/28/15 YS remove ReceivingStatus
-- =============================================
CREATE PROCEDURE [dbo].[spCheckDMR]
	-- Add the parameters for the stored procedure here
	@Uniqlnno varchar(max)= NULL   -- need 10 characters only, but will allow for comma separated values
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @PoItemsLink TABLE (Uniqlnno char(10));
	if @Uniqlnno is not null and @Uniqlnno <>''
		INSERT INTO @PoItemsLink SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@Uniqlnno  ,',')


	
    -- Insert statements for procedure here
	-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
	SELECT distinct PORECDTL.UNIQLNNO 
		FROM Porecmrb  INNER JOIN Porecdtl ON PorecMrb.Fk_UniqRecdtl=Porecdtl.UniqRecdtl 
		INNER JOIN @PoItemsLink P on p.UNIQLNNO =Porecdtl.Uniqlnno
		inner join POITEMS on porecdtl.UNIQLNNO =poitems.UNIQLNNO 
		WHERE Dmr_no=' '  
		-- make sure only complete receivers are selected
		-- 05/28/15 YS remove ReceivingStatus
		--and (PORECDTL.ReceivingStatus='Complete' or PORECDTL.ReceivingStatus=' ') 
		
	
	
		
END