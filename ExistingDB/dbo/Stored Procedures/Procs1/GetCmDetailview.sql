CREATE PROCEDURE [dbo].[GetCmDetailview]
	-- Add the parameters for the stored procedure here
	@gcCmemoNo as char(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 03/13/15 VL added FC fields: cmpriceFC
	-- 03/22/15 VL added CmPrUniq
	-- 11/02/16 VL added PR fields
	SELECT DISTINCT cmprices.*,cmprices.cmprice as price,
		CASE WHEN cmprices.RECORDTYPE='P' THEN	inventor.part_type ELSE SPACE(8) END AS Part_type,
		CASE WHEN cmprices.RECORDTYPE='P' THEN inventor.part_class ELSE SPACE(8) END AS Part_class,
		CASE WHEN cmprices.RECORDTYPE='P' THEN inventor.part_no ELSE SPACE(25) END as Part_no, 
		CASE WHEN cmprices.RECORDTYPE='P' THEN inventor.revision ELSE SPACE(8) END as Revision,
		cmprices.cmquantity AS quantity,cmdetail.lAdjustLine, cmpriceFC as priceFC, Cmprices.CmPrUniq AS CmprUniq, CmPricePR AS PricePR 
		FROM cmdetail,sodetail,inventor,cmprices 
		WHERE cmprices.cmemono = @gcCmemoNo 
		AND cmprices.cmpricelnk = cmdetail.cmpricelnk 
		AND cmdetail.uniqueln = sodetail.uniqueln 
		AND sodetail.uniq_key = inventor.uniq_key 
		UNION 
		SELECT DISTINCT cmprices.*,cmprices.cmprice as price,SPACE(8) AS part_type,SPACE(8) AS part_class,
		SPACE(25) AS part_no,SPACE(4) AS revision,cmprices.cmquantity AS quantity,cmdetail.lAdjustLine, cmpriceFC as priceFC, Cmprices.CmPrUniq AS CmprUniq, CmPricePR AS PricePR  
		FROM cmdetail,sodetail,cmprices 
		WHERE cmprices.cmemono = @gcCmemoNo 
		AND cmprices.cmpricelnk = cmdetail.cmpricelnk 
		AND cmdetail.uniqueln = sodetail.uniqueln 
		AND sodetail.uniq_key = space(10)  
		UNION 
		SELECT DISTINCT cmprices.*,cmprices.cmprice as price,SPACE(8) AS part_type,SPACE(8) AS part_class,
		SPACE(25) AS part_no,SPACE(4) AS revision,cmprices.cmquantity AS quantity ,cmdetail.lAdjustLine, cmpriceFC as priceFC, Cmprices.CmPrUniq AS CmprUniq, CmPricePR AS PricePR  
		FROM cmdetail,cmprices
		WHERE cmprices.cmemono = @gcCmemoNo 
		AND cmprices.cmpricelnk = cmdetail.cmpricelnk 
		AND LEFT(cmdetail.uniqueln,1) <> '_'
END		