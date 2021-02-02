-- =============================================    
-- Author:  Vijay G    
-- Create date: 03/22/2017    
-- Description: BOM for the given parent    
-- To display bom detail data with total no. of records on UI grid footer,sorting of records.    
-- Modified By: Vijay G 10/27/2017 - Get TotalCount of records. Also added condition to get records in range on the basis of EFF_DT and TERM_DT date.    
-- Modified By: Vijay G 11/01/2017 - Get BOM history as per selction criteria i.e Current, BOM History, Selected Date.    
-- Reason : Shrikant B 12/27/2018 - for getting consign customer of bom components from inventor where customers are same from another assembly with same part no and revision  
-- Modified By: Shrikant B 12/27/2018 - for getting BOMCompnent Data  
-- Modified By: Shrikant B 12/27/2018 - for getting consign data from inventor  
-- Modified By: Shrikant B 12/27/2018 - for Combining result for showing data  
-- Modified By: Shrikant B 12/27/2018 - for select finalRessult Data  
-- Modified By: Shrikant B 01/04/2019 - for If the Assembly is having any consg part which is associted with the BOMCustno of the internal part then its consg part no and revision should get displayed   
-- Modified By: Shrikant B 01/04/2019 - Added self Join For displaying assembly's customer no and customer revison. if assembly having any consg part with same bomcust No  
-- Modified By: Shrikant B 01/10/2019 - Change Join condition from i.BOMCUSTNO = i2.CUSTNO to @custNo = i2.CUSTNO  
-- Modified By: Shrikant B 01/10/2019 - Added column ConsgPartUniqKey for getting consign manufacturer data in AML grid if any consign part exists against bom components  
-- Modified By: Sachin B 03/27/2020 -Removed condtional >= for termination date and only used >  
-- [Bom_Det_View_Data] @gUniq_key='U1DD17KBKL',@isCurrent=1 ,@currentDateTime='2020-03-31' 
-- =============================================    
CREATE PROC [dbo].[Bom_Det_View_Data]    
@gUniq_key AS CHAR(10) = '',    
@startRecord INT = 0,    
@endRecord INT = 0,    
@selectedDate AS nvarchar(19) = '',    
@isCurrent BIT = 0,    
@sortExpression CHAR(1000) = NULL,    
@currentDateTime AS nvarchar(19) = ''    
    
AS    
BEGIN    
DECLARE @SQL NVARCHAR(max)    
  
DECLARE @custNo CHAR(10) = (SELECT BOMCUSTNO FROM INVENTOR where UNIQ_KEY =@gUniq_key)  
  
-- Modified By: Shrikant B 12/27/2018 - for getting BOMCompnent Data  
;WITH BOMCompnent AS (  
  SELECT Item_no, i.Part_sourc  
 ,CASE WHEN i.part_sourc= 'CONSG' THEN i.Custpartno ELSE i.Part_no END  AS ViewPartNo,    
 CASE WHEN i.part_sourc= 'CONSG' THEN i.Custrev ELSE i.Revision END AS ViewRev,    
 i.Part_class, i.Part_type, i.Descript, Qty, i.Part_no, i.Revision,   
-- Modified By: Shrikant B 01/04/2019 - for If the Assembly is having any consg part which is associted with the BOMCustno of the internal part then its consg part no and revision should get displayed  
 CASE WHEN i2.CustPartno IS NOT NULL THEN  i2.CustPartno ELSE i.CustPartno END  AS CustPartno,  
 CASE WHEN i2.Custrev IS NOT NULL  THEN  i2.Custrev ELSE  i.Custrev  END  AS Custrev  
  ,BomParent, b.Uniq_key,    
 Dept_id, Item_note, Offset, Term_dt, Eff_dt, Used_inKit,i.Custno, i.U_of_meas, i.Scrap, i.Setupscrap,    
 UniqBomno, i.Phant_Make, i.StdCost, i.Make_buy, i.[Status],COUNT(1) OVER() AS TotalCount,    
  LeadTime =     
   CASE     
    WHEN i.Part_Sourc = 'PHANTOM' THEN 0000    
    WHEN i.Part_Sourc = 'MAKE' AND i.Make_Buy = 0 THEN     
  CASE     
   WHEN i.Prod_lunit = 'DY' THEN i.Prod_ltime    
   WHEN i.Prod_lunit = 'WK' THEN i.Prod_ltime * 5    
   WHEN i.Prod_lunit = 'MO' THEN i.Prod_ltime * 20    
   ELSE i.Prod_ltime    
  END +    
  CASE     
   WHEN i.Kit_lunit = 'DY' THEN i.Kit_ltime    
   WHEN i.Kit_lunit = 'WK' THEN i.Kit_ltime * 5    
   WHEN i.Kit_lunit = 'MO' THEN i.Kit_ltime * 20    
   ELSE i.Kit_ltime    
  END    
    ELSE    
  CASE    
   WHEN i.Pur_lunit = 'DY' THEN i.Pur_ltime    
   WHEN i.Pur_lunit = 'WK' THEN i.Pur_ltime * 5    
   WHEN i.Pur_lunit = 'MO' THEN i.Pur_ltime * 20    
   ELSE i.Pur_ltime    
  END    
   END, i.INT_UNIQ,  
   -- Modified By: Shrikant B 01/10/2019 - Added column ConsgPartUniqKey for getting consign manufacturer data in AML grid if any consign part exists against bom components  
   CASE WHEN i2.CustPartno IS NOT NULL THEN  i2.UNIQ_KEY ELSE i.UNIQ_KEY END  AS ConsgPartUniqKey  
   FROM Bom_det b  
   INNER JOIN Inventor i on b.UNIQ_KEY = i.Uniq_key  
   -- Modified By: Shrikant B 01/04/2019 - Added self Join For displaying assembly's customer no and customer revison. if assembly having any consg part with same bomcust No  
   -- Modified By: Shrikant B 01/10/2019 - Change Join condition from i.BOMCUSTNO = i2.CUSTNO to @custNo = i2.CUSTNO  
   LEFT  JOIN  Inventor i2  ON ((i.PART_NO = i2.PART_NO) and (i.REVISION = i2.REVISION) and (@custNo = i2.CUSTNO) and i2.PART_SOURC='Consg' )    
   WHERE  b.BOMPARENT = @gUniq_key  
 )  
 -- Modified By: Shrikant B 12/27/2018 - for getting consign data from inventor   
 ,ConsignData As(  
  SELECT Item_no, t.Part_sourc  
  ,CASE WHEN t.part_sourc= 'CONSG' THEN t.Custpartno ELSE t.Part_no END  AS ViewPartNo,    
   CASE WHEN t.part_sourc= 'CONSG' THEN t.Custrev ELSE t.Revision END AS ViewRev,   
  t.Part_class, t.Part_type, t.Descript, Qty, t.Part_no, t.Revision, t.CustPartno, t.Custrev, BomParent,t.Uniq_key,    
  Dept_id, Item_note, Offset, Term_dt, Eff_dt, Used_inKit,t.Custno, t.U_of_meas, t.Scrap, t.Setupscrap,    
  UniqBomno, t.Phant_Make, t.StdCost, t.Make_buy, t.[Status],COUNT(1) OVER() AS TotalCount,    
  LeadTime =CASE     
    WHEN t.Part_Sourc = 'PHANTOM' THEN 0000    
    WHEN t.Part_Sourc = 'MAKE' AND t.Make_Buy = 0 THEN     
  CASE     
   WHEN i.Prod_lunit = 'DY' THEN i.Prod_ltime    
   WHEN i.Prod_lunit = 'WK' THEN i.Prod_ltime * 5    
   WHEN i.Prod_lunit = 'MO' THEN i.Prod_ltime * 20    
   ELSE i.Prod_ltime    
  END +    
  CASE     
   WHEN i.Kit_lunit = 'DY' THEN i.Kit_ltime    
   WHEN i.Kit_lunit = 'WK' THEN i.Kit_ltime * 5    
   WHEN i.Kit_lunit = 'MO' THEN i.Kit_ltime * 20    
   ELSE i.Kit_ltime    
  END    
    ELSE    
  CASE    
   WHEN i.Pur_lunit = 'DY' THEN i.Pur_ltime    
   WHEN i.Pur_lunit = 'WK' THEN i.Pur_ltime * 5    
   WHEN i.Pur_lunit = 'MO' THEN i.Pur_ltime * 20    
   ELSE i.Pur_ltime    
  END    
   END,   
   i.INT_UNIQ,  
   -- Modified By: Shrikant B 01/10/2019 - Added column ConsgPartUniqKey for getting consign manufacturer data in AML grid if any consign part exists against bom components  
   ConsgPartUniqKey  
   FROM BOMCompnent t  
   INNER JOIN INVENTOR i on t.UNIQ_KEY =i.INT_UNIQ AND i.CUSTNO =@custNo and t.part_sourc<> 'CONSG'  
 )  
  
 -- Modified By: Shrikant B 12/27/2018 - for Combining result for showing data  
 ,finalRessult AS(  
    SELECT T.* FROM BOMCompnent t   
    LEFT JOIN ConsignData c ON t.UNIQ_KEY =c.INT_UNIQ  
    WHERE c.UNIQ_KEY IS NULL  
   UNION  
       SELECT * FROM ConsignData  
 )  
  
 -- Modified By: Shrikant B 12/27/2018 - for select finalRessult Data  
SELECT *  INTO #BOMData   
FROM finalRessult  
    
SET @SQL = N'SELECT * FROM #BOMData '    
    
 IF @isCurrent = 1 -- Vijay G:11/01/2017: Get BOM recourds as per current criteria    
 BEGIN    
 -- Modified By: Sachin B 03/27/2020 -Removed condtional >= for termination date and only used >  
 SET @SQL = @SQL  + 'WHERE (EFF_DT IS NULL OR EFF_DT <= ''' + @currentDateTime + ''') AND (TERM_DT IS NULL OR TERM_DT > ''' + @currentDateTime + ''')'    
 END    
 ELSE IF @selectedDate IS NOT NULL AND @selectedDate <> '' -- Vijay G:11/01/2017: Get BOM records as per Selected date criteria    
 BEGIN    
 SET @SQL = @SQL  + 'WHERE (EFF_DT IS NULL OR EFF_DT <= ''' + @selectedDate + ''') AND (TERM_DT IS NULL OR TERM_DT >= ''' + @selectedDate + ''')'    
 END    

 If @sortExpression <> '' AND Convert(VARCHAR,@startRecord) <> 0 AND Convert(VARCHAR,@endRecord) <> 0    
 BEGIN    
  SET @SQL = @SQL+ ' ORDER BY '+ @sortExpression+' OFFSET '+Convert(varchar,@startRecord)+' ROWS    
  FETCH NEXT ('+Convert(VARCHAR,@endRecord)+' - '+Convert(VARCHAR,@startRecord)+') ROWS ONLY'    
 END    
    ELSE IF @sortExpression = '' AND Convert(VARCHAR,@startRecord) <> 0 AND Convert(VARCHAR,@endRecord) <> 0    
 BEGIN    
  SET @SQL = @SQL + ' ORDER BY Item_no OFFSET '+Convert(VARCHAR,@startRecord)+' ROWS    
  FETCH NEXT ('+Convert(VARCHAR,@endRecord)+') ROWS ONLY'    
 END    
   ELSE IF @sortExpression <> '' AND Convert(VARCHAR,@startRecord) = 0 AND Convert(VARCHAR,@endRecord) = 0    
 BEGIN    
  SET @SQL = @SQL+ ' ORDER BY '+ @sortExpression+''    
 END    
   ELSE IF @sortExpression = '' AND Convert(VARCHAR,@startRecord) = 0 AND Convert(VARCHAR,@endRecord) = 0    
 BEGIN    
  SET @SQL = @SQL + ' ORDER BY Item_no'    
 END    
   ELSE IF @sortExpression = '' AND Convert(VARCHAR,@startRecord) = 0 AND Convert(VARCHAR,@endRecord) <> 0    
 BEGIN    
  SET @SQL = @SQL + ' ORDER BY Item_no OFFSET '+Convert(VARCHAR,@startRecord)+' ROWS    
  FETCH NEXT ('+Convert(VARCHAR,@endRecord)+') ROWS ONLY'    
 END    
   ELSE IF @sortExpression <> '' AND Convert(varchar,@startRecord) = 0 AND Convert(varchar,@endRecord) <> 0    
 BEGIN    
  SET @SQL = @SQL + ' ORDER BY '+ @sortExpression+' OFFSET '+Convert(varchar,@startRecord)+' ROWS    
  FETCH NEXT ('+Convert(VARCHAR,@endRecord)+') ROWS ONLY'    
 END    
   EXEC sp_executesql @SQL    
END 