CREATE PROCEDURE [dbo].[AntiAVl4BomParentView] 
	-- Add the parameters for the stored procedure here
	@gUniq_key char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    
	SELECT BomParent,Uniq_key,PartMfgr,Mfgr_pt_no,UNIQANTI  
	from ANTIAVL
	WHERE BomParent=@gUniq_key
END






