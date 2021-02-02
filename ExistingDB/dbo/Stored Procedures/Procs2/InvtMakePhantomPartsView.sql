CREATE PROCEDURE dbo.InvtMakePhantomPartsView
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		SELECT Part_no, Uniq_Key, Mrp_Code, Make_Buy 
		FROM Inventor 
		WHERE Part_Sourc = 'MAKE' 
		OR Part_Sourc = 'PHANTOM' 
	
END