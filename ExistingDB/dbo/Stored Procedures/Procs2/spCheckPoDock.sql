-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/21/13
-- Description:	Procedure will check in PoDock 
-- =============================================
CREATE PROCEDURE [dbo].[spCheckPoDock]
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
	SELECT distinct d.UNIQLNNO 
		FROM PoDock D inner join @PoItemsLink P on d.UNIQLNNO =p.Uniqlnno
		WHERE compby=' ' 
	
	
		
END
