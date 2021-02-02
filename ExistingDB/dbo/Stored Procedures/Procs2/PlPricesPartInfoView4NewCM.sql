-- =============================================
-- Author:		??
-- Create date:	
-- Description:	The invoice detail records for adding a new CM
-- Modifications:	
-- 03/16/15 VL added FC fields
-- 09/08/16 VL Change the criteria AND  CASE WHEN C.CMQTY IS NULL THEN PlPrices.Extended ELSE (PlPrices.Quantity-C.CMQTY)*PlPrices.PRICE END>0
--				 to AND  CASE WHEN C.CMQTY IS NULL THEN PlPrices.Quantity ELSE (PlPrices.Quantity-C.CMQTY) END>0
-- 11/02/16 VL added PR fields
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- =============================================
CREATE PROCEDURE [dbo].[PlPricesPartInfoView4NewCM] 
	-- Add the parameters for the stored procedure here
	@gcPacklistNo as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 03/16/15 VL added FC fields
	-- 11/02/16 VL added PR fields
	SELECT  
	CASE WHEN Inventor.UNIQ_KEY IS NULL OR Plprices.RECORDTYPE<>'P' THEN CAST(' ' as CHAR(8))
		 WHEN plprices.RECORDTYPE ='P' THEN Part_type ELSE SPACE(8) END as Part_type,
	CASE WHEN Inventor.UNIQ_KEY IS NULL OR Plprices.RECORDTYPE<>'P' THEN CAST(' ' as CHAR(8)) 
		 WHEN  PlPrices.RECORDTYPE='P' THEN Part_class ELSE SPACE(8) END as Part_class,
		 --- 03/28/17 YS changed length of the part_no column from 25 to 35
	CASE WHEN Inventor.UNIQ_KEY IS NULL OR Plprices.RECORDTYPE<>'P' THEN CAST(' ' as CHAR(35)) 
		 WHEN  PlPrices.RECORDTYPE='P' THEN Part_no ELSE SPACE(35) END as Part_no,
	CASE WHEN Inventor.UNIQ_KEY IS NULL OR Plprices.RECORDTYPE<>'P' THEN CAST(' ' as CHAR(8)) 
		 WHEN  PlPrices.RECORDTYPE='P' THEN  Revision ELSE SPACE(8) END as Revision,
	PlPrices.PacklistNo,PlPrices.Quantity-ISNULL(C.CMQTY,0.00) as Quantity, PlPrices.RecordType, PlPrices.flat, PlPrices.Price, 
			CASE WHEN C.CMQTY IS NULL THEN PlPrices.Extended ELSE (PlPrices.Quantity-C.CMQTY)*PlPrices.PRICE END as Extended ,
			plPrices.PLPRICELNK, 
			plprices.DESCRIPT, PlPrices.PlUniqlnk,
			PlPrices.Pl_Gl_nbr, PlPrices.taxable,  
			PlPrices.Inv_Link, PlPrices.Uniqueln, PlPrices.Cog_Gl_nbr, 
			PlPrices.Quantity-ISNULL(C.CMQTY,0.00) as OrgQty,PlPrices.Price as OrgPrice,PlPrices.Quantity-ISNULL(C.CMQTY,0.00)  as ScrapQty, 
			PlPrices.PriceFC, CASE WHEN C.CMQTY IS NULL THEN PlPrices.ExtendedFC ELSE (PlPrices.Quantity-C.CMQTY)*PlPrices.PRICEFC END as ExtendedFC, 
			PlPrices.PriceFC as OrgPriceFC,
			PlPrices.PricePR, CASE WHEN C.CMQTY IS NULL THEN PlPrices.ExtendedPR ELSE (PlPrices.Quantity-C.CMQTY)*PlPrices.PRICEPR END as ExtendedPR, 
			PlPrices.PricePR as OrgPricePR
		FROM PlPrices  LEFT OUTER JOIN SODETAIL ON Plprices.UNIQUELN=Sodetail.UNIQUELN
		LEFT OUTER JOIN INVENTOR ON Sodetail.UNIQ_KEY =Inventor.UNIQ_KEY 
		OUTER APPLY (SELECT cmprices.pluniqlnk,sum(Cmdetail.CMQTY) as CmQty FROM CMDETAIL INNER JOIN CMPRICES on cmdetail.CMPRICELNK =cmprices.CMPRICELNK  
																						INNER JOIN CMMAIN on cmmain.CMUNIQUE =cmdetail.cmUnique 
						where cmmain.cStatus<>'CANCELLED' and plPrices.PLUNIQLNK=cmprices.PLUNIQLNK GROUP BY cmprices.PLUNIQLNK ) C 
		WHERE PLPRICES.PACKLISTNO = @gcPacklistNo
		-- 09/08/16 VL Change the criteria (PlPrices.Quantity-C.CMQTY)*PlPrices.PRICE END>0 to (PlPrices.Quantity-C.CMQTY)>0, in Penang's case, it's possible they have price $0 item
		--AND  CASE WHEN C.CMQTY IS NULL THEN PlPrices.Extended ELSE (PlPrices.Quantity-C.CMQTY)*PlPrices.PRICE END>0
		AND  CASE WHEN C.CMQTY IS NULL THEN PlPrices.Quantity ELSE (PlPrices.Quantity-C.CMQTY) END>0
		
END