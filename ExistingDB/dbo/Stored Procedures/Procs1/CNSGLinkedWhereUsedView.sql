CREATE PROCEDURE [dbo].[CNSGLinkedWhereUsedView]
	-- this procedure will find all the consign parts linked to a given internal part
	-- if used on any BOM
	-- Add the parameters for the stored procedure here
	-- 03/01/14 YS added term_dt and eff_dt columns
	@lcUniq_key as char(10) =' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Bom_det.UniqBomNo, Bom_det.BomParent,Bom_Det.Uniq_key,M.BomCustNo,
		 D.PART_NO as CompPartNo,D.REVISION as CompRev,D.CUSTPARTNO,D.CUSTREV,M.PART_NO as MakePartNo,
		 M.REVISION as MakeRev ,bom_det.EFF_DT ,bom_det.TERM_DT 
		 FROM Bom_Det,Inventor M, INVENTOR D
	WHERE D.INT_UNIQ  = @lcUniq_Key
		AND BOM_DET.UNIQ_KEY = D.UNIQ_KEY 
		AND M.Uniq_key=Bom_det.BomParent
END