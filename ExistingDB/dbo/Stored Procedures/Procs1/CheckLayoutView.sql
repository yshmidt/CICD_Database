

CREATE PROCEDURE dbo.CheckLayoutView 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Checklayout.formname, Checklayout.formdescr,
  Checklayout.no_section, Checklayout.layout, Checklayout.reportname,
  Checklayout.checktype, Checklayout.uniqlayout, Checklayout.detaillines
 FROM 
    checklayout

END
