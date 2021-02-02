-- =============================================  
-- Author:  Vicky Lu  
-- Create date: 09/13/10  
-- Description: Update packing list tables from sales order(used in Invoice module)  
-- Modified:   
-- 01/06/15 VL Added FC and GST  
--  04/24/15 VL Found the END should be moved to after inserting plprices, otherwise, even all qty are shipped, it will still try to insert a recor in plprices  
-- 10/07/16 VL Added Functional currency code
-- 01/30/2020 Nitesh B : Change for Flat scenario "When Flat is Check AND if already invoice is created and we update SOAMOUNT/PRICE then the remaining amount left for sales order should be the so item Price"
-- 01/30/2020 Nitesh B : Added @plPrice and @soPrice for getting Price from PLPRICES and SOPRICES  
-- 06/25/2020 Shivshankar P : Change the BEGIN END Block if not find Plprices record in Soprices then need to delete
-- =============================================  
CREATE PROCEDURE [dbo].[sp_UpdPkSoPrices] @lcPacklistno AS char(10) = ''  
AS  
BEGIN  
-- SET NOCOUNT ON added to prevent extra result sets from  
-- interfering with SELECT statements.  
SET NOCOUNT ON;  
  
BEGIN TRANSACTION  
  
-- 01/06/15 VL added @SopPriceFC  
-- 10/07/16 VL added @SopPricePR  
DECLARE @lnTotalNo int, @lnCount int, @SopSono char(10), @SopUniqueln char(10), @SopDescriptio char(45),  
  @SopQuantity numeric(10,2), @SopPrice numeric(14,5), @SopTaxable bit, @SopFlat bit,   
  @SopRecordType char(1), @SopPlpricelnk char(10), @SopPl_gl_nbr char(13), @SopCog_gl_nbr char(13),   
  @lnFoundSoprices int, @lcPlUniqLnk char(10), @PldetailShippedQty numeric(9,2), @PldetailInv_link char(10),   
  @lnShippedSoQtyNotThisPK numeric(9,2), @lnShippedQtyThisTime numeric(9,2), @lnTotalNo2 int, @lnCount2 int,  
  @PlpPlpricelnk char(10), @PlpRecordType char(1), @PlpAmortFlag char(1), @PlpUniqueln char(10),   
  @PlpQuantity numeric(10,2), @PlpPlUniqLnk char(10), @chkPlpriceLnk char(10), @lnFoundPlprices int,  
  @lcChkUniqValue char(10), @lcNewUniqNbrPrice char(10), @SopPriceFC numeric(14,5), @SopPricePR numeric(14,5),  
  @plPrice numeric(14,5), @soPrice numeric(14,5); -- 01/30/2020 Nitesh B : Added @plPrice and @soPrice for getting Price from PLPRICES and SOPRICES

DECLARE @ZPlprices TABLE (nrecno int identity, Packlistno char(10), Uniqueln char(10), Descript char(45),   
  Quantity numeric(10,2), Price numeric(14,5), Extended numeric(20,2), Taxable bit, Flat bit,   
  Inv_link char(10), RecordType char(1), AmortFlag char(1), Pl_gl_nbr char(13), Plpricelnk char(10),   
  Pluniqlnk char(10), Cog_gl_nbr char(13));  
    
INSERT @ZPlprices SELECT Packlistno, Uniqueln, Descript, Quantity, Price, Extended, Taxable, Flat, Inv_link,  
  RecordType, AmortFlag, Pl_gl_nbr, Plpricelnk, Pluniqlnk, Cog_gl_nbr  
  FROM PLPRICES  
  WHERE PACKLISTNO = @lcPacklistno  
SET @lnTotalNo2 = @@ROWCOUNT;  
  
-- 01/06/15 VL added PriceFC   
-- 10/07/16 VL added PricePR  
DECLARE @ZSoprices TABLE (nrecno int identity, Sono char(10), Uniqueln char(10), Descriptio char(45),   
  Quantity numeric(10,2), Price numeric(14,5), Taxable bit, Flat bit, RecordType char(1),   
  Plpricelnk char(10), Pl_gl_nbr char(13), Cog_gl_nbr char(13), PldetailShippedQty numeric(9,2),   
  PldetailInv_link char(10), PriceFC numeric(14,5), PricePR numeric(14,5));  
    
-- 01/06/15 VL added PriceFC   
-- 10/07/16 VL added PricePR  
INSERT @ZSoprices SELECT Sono, Soprices.Uniqueln, Descriptio, Quantity, PRICE, Taxable, Flat, RecordType,   
  Plpricelnk, Pl_gl_nbr, Cog_gl_nbr, ShippedQty AS PldetailShippedQty, Pldetail.Inv_link AS PldetailInv_link, PriceFC, PricePR  
  FROM SOPRICES, Pldetail  
  WHERE SOPRICES.UNIQUELN = PLDETAIL.UNIQUELN   
  AND PACKLISTNO = @lcPacklistno  
  
SET @lnTotalNo = @@ROWCOUNT;  
-- First, check all soprices and insert or update plprices if necessary   
IF (@lnTotalNo>0)  
BEGIN  
 SET @lnCount=0;  
 WHILE @lnTotalNo>@lnCount  
 BEGIN   
  SET @lnCount=@lnCount+1;  
  -- 01/06/15 VL added PriceFC   
  -- 10/07/16 VL added PricePR  
  SELECT @SopSono = Sono, @SopUniqueln = Uniqueln, @SopDescriptio =Descriptio, @SopQuantity = Quantity,  
    @SopPrice = Price,@SopTaxable =Taxable, @SopFlat =Flat, @SopRecordType = RecordType,   
    @SopPlpricelnk =Plpricelnk, @SopPl_gl_nbr = Pl_gl_nbr, @SopCog_gl_nbr = Cog_gl_nbr, @SopPriceFC = PriceFC,  
    @SopPricePR = PricePR  
  FROM @ZSoprices WHERE nrecno = @lnCount  
  IF (@@ROWCOUNT<>0)  
  BEGIN  
  
   -- Get Pldetail info  
   SELECT @PldetailShippedQty = ShippedQty, @PldetailInv_link = Inv_link  
    FROM PLDETAIL   
    WHERE PACKLISTNO = @lcPacklistno  
    AND UNIQUELN = @SopUniqueln  
      
   -- Check if find soprices in plprices, if found, just update price, extended... otherwise, insert plprices  
   SELECT @lcPlUniqLnk = PlUniqLnk  
    FROM PLPRICES   
    WHERE PLPRICELNK = @SopPlpricelnk  
    AND PACKLISTNO = @lcPacklistno  
      
   SET @lnFoundSoprices = @@ROWCOUNT;  
     
   IF @lnFoundSoprices<>0 -- Found in plprices, update price 
   	BEGIN
	IF @SopFlat = 1
        -- 01/30/2020 Nitesh B : Change for Flat scenario "When Flat is Check AND if already invoice is created and we update SOAMOUNT/PRICE then the remaining amount left for sales order should be the so item Price"
		SELECT @plPrice = SUM(PRICE) FROM PLPRICES WHERE PLPRICELNK = @SopPlpricelnk
		SELECT @soPrice = SUM(PRICE) FROM SOPRICES WHERE PLPRICELNK = @SopPlpricelnk
		IF((@soPrice - @plPrice) > 0)
			SET @SopPrice = (@soPrice - @plPrice)   
    
    -- 01/06/15 VL added PriceFC and ExtendedFC  
    -- 10/07/16 VL added PricePR and ExtendedPR  
    UPDATE PLPRICES  
    SET PRICE = @SopPrice,  
     TAXABLE = @SopTaxable,  
     FLAT = @SopFlat,  
     EXTENDED = CASE WHEN @SopFlat = 0 THEN   
          CASE WHEN PLPRICES.QUANTITY * @SopPrice<999999999999.99   
           THEN PLPRICES.QUANTITY * @SopPrice  
           ELSE 999999999999.99 END   
          ELSE @SopPrice END,  
     PRICEFC = @SopPriceFC,  
     EXTENDEDFC = CASE WHEN @SopFlat = 0 THEN   
          CASE WHEN PLPRICES.QUANTITY * @SopPriceFC<999999999999.99   
           THEN PLPRICES.QUANTITY * @SopPriceFC  
           ELSE 999999999999.99 END   
          ELSE @SopPriceFC END,  
     PRICEPR = @SopPricePR,  
     EXTENDEDPR = CASE WHEN @SopFlat = 0 THEN   
          CASE WHEN PLPRICES.QUANTITY * @SopPricePR<999999999999.99   
           THEN PLPRICES.QUANTITY * @SopPricePR  
           ELSE 999999999999.99 END   
          ELSE @SopPricePR END       
    WHERE PLPRICES.PlPriceLnk = @SopPlpricelnk  
    AND Plprices.Packlistno = @lcPacklistno
	END  
   ELSE  
    BEGIN  
    IF @SopFlat = 1  
     BEGIN  
     -- Check if find soprices in plprices(for all packlistno, not just @lcPacklistno, if !found, insert plprices  
     SELECT @lcPlUniqLnk = plUniqLnk  
      FROM PLPRICES   
      WHERE PLPRICELNK = @SopPlpricelnk  
        
     SET @lnFoundSoprices = @@ROWCOUNT;   
       
     IF @lnFoundSoprices=0 -- didn't find flat record in plprices, will insert one  
      BEGIN  
      -- Get unique value for PlUniqLnk  
      WHILE (1=1)  
      BEGIN  
       EXEC sp_GenerateUniqueValue @lcNewUniqNbrPrice OUTPUT  
       SELECT @lcChkUniqValue = PlUniqlnk FROM Plprices WHERE PlUniqlnk = @lcNewUniqNbrPrice  
       IF (@@ROWCOUNT<>0)  
        CONTINUE  
       ELSE  
        BREAK  
      END   
         
      -- 01/06/15 VL added PriceFC and ExtendedFC   
      -- 10/07/16 VL added PricePR and ExtendedPR  
      INSERT INTO Plprices (Packlistno, Uniqueln, Descript, Quantity, Price, Extended, Taxable,   
         Flat, Inv_link, RecordType, Pl_gl_nbr, PlPricelnk, Cog_gl_nbr, PlUniqLnk, PRICEFC, ExtendedFC,  
         PRICEPR, ExtendedPR)   
       VALUES (@lcPacklistno, @SopUniqueln, @SopDescriptio, @PldetailShippedQty,   
         CASE WHEN @lnFoundSoPrices > 0 THEN 0 ELSE @SopPrice END,   
         CASE WHEN @lnFoundSoPrices > 0 THEN 0 ELSE @SopPrice END, @SopTaxable, @SopFlat,   
         @PldetailInv_link, @SopRecordType, @SopPl_gl_nbr, @SopPlPricelnk, @SopCog_gl_nbr,  
         @lcNewUniqNbrPrice, CASE WHEN @lnFoundSoPrices > 0 THEN 0 ELSE @SopPriceFC END,   
         CASE WHEN @lnFoundSoPrices > 0 THEN 0 ELSE @SopPriceFC END,  
         CASE WHEN @lnFoundSoPrices > 0 THEN 0 ELSE @SopPricePR END,   
         CASE WHEN @lnFoundSoPrices > 0 THEN 0 ELSE @SopPricePR END)  
     END  
     END  
    ELSE                        
     -- not flat     
     BEGIN                       
     IF @SopRecordType = 'P'  
      BEGIN  
      -- Get unique value for PlUniqLnk  
      WHILE (1=1)  
      BEGIN  
       EXEC sp_GenerateUniqueValue @lcNewUniqNbrPrice OUTPUT  
       SELECT @lcChkUniqValue = PlUniqlnk FROM Plprices WHERE PlUniqlnk = @lcNewUniqNbrPrice  
       IF (@@ROWCOUNT<>0)  
        CONTINUE  
       ELSE  
        BREAK  
      END   
      -- 01/06/15 VL added PriceFC and ExtendedFC    
      -- 10/07/16 VL added PricePR and ExtendedPR     
                        INSERT INTO Plprices (Packlistno, Uniqueln, Descript, Quantity, Price, Extended, Taxable,   
        Flat, Inv_link, RecordType, Pl_gl_nbr, PlPricelnk, Cog_gl_nbr, PlUniqLnk, PRICEFC, ExtendedFC,  
        PRICEPR, ExtendedPR)   
                        VALUES (@lcPacklistno, @SopUniqueln, @SopDescriptio, @PldetailShippedQty,   
        @SopPrice, @PldetailShippedQty*@SopPrice, @SopTaxable, @SopFlat,   
        @PldetailInv_link, @SopRecordType, @SopPl_gl_nbr, @SopPlPricelnk, @SopCog_gl_nbr,  
        @lcNewUniqNbrPrice, @SopPriceFC, @PldetailShippedQty*@SopPriceFC,  
        @SopPricePR, @PldetailShippedQty*@SopPricePR)  
      END         
     ELSE  
      BEGIN  
      --soprices.recordtype<>"P"  
      SELECT @lnShippedSoQtyNotThisPK = ISNULL(SUM(Quantity),0)  
       FROM Plprices  
       WHERE Plpricelnk = @SopPlPricelnk  
       AND Packlistno <> @lcPacklistno       
          
       IF @SopQuantity - @lnShippedSoQtyNotThisPK <> 0  
       BEGIN   
        BEGIN  
        IF @SopQuantity - @lnShippedSoQtyNotThisPK < @PldetailShippedQty  
         SET @lnShippedQtyThisTime = @SopQuantity - @lnShippedSoQtyNotThisPK   
        ELSE  
         SET @lnShippedQtyThisTime = @PldetailShippedQty  
        END  
       -- 04/24/15 VL found the END should be moved to after inserting plprices, otherwise, even all qty are shipped, it will still try to insert a recor in plprices  
       --END  
         
       -- Get unique value for PlUniqLnk  
       WHILE (1=1)  
       BEGIN  
        EXEC sp_GenerateUniqueValue @lcNewUniqNbrPrice OUTPUT  
        SELECT @lcChkUniqValue = PlUniqlnk FROM Plprices WHERE PlUniqlnk = @lcNewUniqNbrPrice  
        IF (@@ROWCOUNT<>0)  
         CONTINUE  
        ELSE  
         BREAK  
       END   
       -- 01/06/15 VL added PriceFC and ExtendedFC    
       -- 10/07/16 VL added PricePR and ExtendedPR          
       INSERT INTO Plprices (Packlistno, Uniqueln, Descript, Price, Quantity,   
         Extended, Taxable, Flat, Inv_Link, RecordType, Pl_gl_nbr, Plpricelnk, Cog_gl_nbr, PlUniqLnk, PRICEFC, ExtendedFC,  
         PRICEPR, ExtendedPR)  
        VALUES (@lcPacklistno, @SopUniqueln, @SopDescriptio, @SopPrice, @lnShippedQtyThisTime,  
         CASE WHEN @lnShippedQtyThisTime*@SopPrice < 999999999999.99 THEN @lnShippedQtyThisTime*@SopPrice   
          ELSE 999999999999.99 END, @SopTaxable, @SopFlat, @PldetailInv_link, @SopRecordType, @SopPl_gl_nbr, @SopPlPricelnk, @SopCog_gl_nbr,  
          @lcNewUniqNbrPrice, @SopPriceFC,   
          CASE WHEN @lnShippedQtyThisTime*@SopPriceFC < 999999999999.99 THEN @lnShippedQtyThisTime*@SopPriceFC ELSE 999999999999.99 END,  
          @SopPricePR,   
          CASE WHEN @lnShippedQtyThisTime*@SopPricePR < 999999999999.99 THEN @lnShippedQtyThisTime*@SopPricePR ELSE 999999999999.99 END)  
       -- 04/24/15 VL moved the END from upper place to here  
       END  
      END     
     END            
    END  
  END  
 END  
END  
-- Now, check if extra plprices (not in soprices) that need to be removed  
IF (@lnTotalNo2>0)  
BEGIN  
 SET @lnCount2=0;  
 WHILE @lnTotalNo2>@lnCount2  
 BEGIN   
  SET @lnCount2=@lnCount2+1;  
  SELECT @PlpPlpricelnk = PlpriceLnk, @PlpRecordType = RecordType, @PlpAmortFlag = AmortFlag,   
   @PlpUniqueln = Uniqueln, @PlpQuantity = Quantity, @PlpPlUniqLnk = PlUniqlnk  
   FROM @ZPlprices WHERE nrecno = @lnCount2  
     
  IF (@@ROWCOUNT<>0)  
  BEGIN  
   -- Check if can find Plpricelnk in Soprice, if not found, need to delete in Plprices, and update amort if necessary  
   SELECT @chkPlpriceLnk = Plpricelnk   
    FROM Soprices  
    WHERE PlpriceLnk = @PlpPlpricelnk   
  -- 06/25/2020 Shivshankar P : Change the BEGIN END Block if not find Plprices record in Soprices then need to delete   
   SET @lnFoundPlprices = @@ROWCOUNT;  
   IF @lnFoundPlprices = 0 
   BEGIN
    -- Can not find Plprices record in Soprices, need to delete,  
    -- From Sales order Inventory and has amortization chage, need to put qty back to Prichead  
    IF @PlpRecordType = 'P' AND @PlpAmortFlag = 'A'  
    BEGIN  
     UPDATE PRICHEAD  
      SET INVQTY = InvQty + @PlpQuantity  
      WHERE UNIQ_KEY+CATEGORY =   
       (SELECT UNIQ_KEY + CATEGORY   
        FROM SODETAIL   
        WHERE UNIQUELN = @PlpUniqueln)
    END
    IF SUBSTRING(@PlpUniqueln,1,1) <> '*'  
      DELETE FROM PLPRICES WHERE PLUNIQLNK = @PlpPlUniqLnk  
   END
  END		  
 END    
END  
-- Recalculate invoice total  
EXEC sp_Invoice_Total @lcPacklistno  
COMMIT  
  
END  
  
  