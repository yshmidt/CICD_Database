-- =============================================    
-- Author:  Yelena Shmidt    
-- Create date: 03/19/2014    
-- Description: report Bill of Material, Indented with Wk Ctr (VFP BOMRPT6)    
-- Modified:  11/05/2014 DRP:  changed the @lcUniqBomParent to be @lcUniqKey because that is what we are using within the parameters.    
--         added a section of code that will be used to gather the parent Bom information for the results.   Added MbPhSource and Parent info to the results.      
--    02/18/2015 DRP:  Added one more parameter @lcStatus to show only Active parts or not.  needed to add Inventor table and the Status Field to the results so I could make sure that we could filter using the @lcStatus    
--     09/22/15 DRP:  added the @lcDate to the <<INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,1,0,@UserId,@lcDate>> to make sure that it is pulling only the Active items from the BOM    
--    09/08/16 DRP: added @IncludeMakeBuy, @lcExplode , @showIndentation parameters per request to show Make/Buy items on the resulting report. also changed << INSERT INTO @tBom EXEC  [BomIndented]>> to use those new parameters    
--- 03/28/17 YS changed length of the part_no column from 25 to 35    
--   08/14/17 YS added PR values stdcostpr ,funcFcUsed_uniq ,PrFcUsed_uniq   
-- 05/24/2019 Shrikant added column Bom_note for getting assembly note and avoid column count match error  
-- 06/03/19 VL added CutSheet  
-- 02/14/2020 Vijay G: increased size of custname column 
-- rptBOMIndentedWIthWC  '_39P0RLDFH','Active', 1,'Yes',1   
-- =============================================    
CREATE PROCEDURE [dbo].[rptBOMIndentedWIthWC]    
    
     
 --@lcUniqBomParent char(10)=null, --11/05/2014 DRP:  replaced by @lcUniqKey below.     
--declare     
 @lcUniqkey char(10) = ''    
 ,@lcStatus char(8) = 'Active' --02/18/2015 DRP:  Added    
 ,@IncludeMakeBuy bit = 1  --if the value is 1 will explode make/buy parts ; if 0 - will not (default 1) --09/08/16 DRP:  Added     
  ,@lcExplode char (3) = 'Yes'  --if left as No then the BOM will only display top level components.  If Yes, then the report will explode out components down to all sublevles --09/08/16 DRP:  Added    
  ,@showIndentation Bit = 1  --add spaces in front of the PartView value to clearly show indentation (for now 4 spaces if =1, no spaces if =0, can customize later) --09/08/16 DRP:  Added    
 ,@userId uniqueidentifier=null    
     
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
    
    
    
  --The below is used to indicate to take the active BOM as of today's date (computer date) --09/22/15 DRP:  Added    
  declare @lcDate smalldatetime     
  select @lcDate = DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0)    
    
    -- Insert statements for procedure here    
    --- 03/19/14 YS Need to add Buyer column    
 --- 03/28/17 YS changed length of the part_no column from 25 to 35    
 -- 06/03/19 VL added CutSheet varchar(max)   
 declare @tBom table (bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10) ,    
  ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char (10),Dept_id char(8),Item_note varchar(max),Offset numeric(4,0),    
  Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max),U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit,STDBLDQTY numeric(8,0),    
  Phantom_make bit,StdCost numeric(13,5),Make_buy bit,Status char(10),TopQty numeric(10,2),qty numeric(9,2),Level integer,path varchar(max),sort varchar(max)    
  --- 03/28/17 YS changed length of the part_no column from 25 to 35    
  ,UniqBomNo char(10),Buyer char(3),    
  --   08/14/17 YS added PR values     
  stdcostpr numeric(13,5),funcFcUsed_uniq char(10) ,PrFcUsed_uniq char(10),    
  CustPartNo char(35),CustRev char(8),CustUniqKey char(10)  
-- 05/24/2019 Shrikant added column Bom_note for getting assembly note and avoid column count match error  
  ,Bom_note varchar(max)  
  -- 06/03/19 VL added CutSheet varchar(max)  
  , CutSheet varchar(max), nId int Identity  
  ) ;    
    
  -- 06/03/19 VL added Cut Sheet, so need to list all fields   
  DECLARE @lnTotalCnt int, @lnCnt int, @UniqBomno char(10), @output varchar(max)  
  --INSERT INTO @tBom EXEC  [BomIndented] @lcUniqKey,@IncludeMakeBuy,@ShowIndentation,@UserId =@UserId,@lcDate = @lcDate;    
  INSERT INTO @tBom (bomParent,bomcustno,UNIQ_KEY,item_no,PART_NO,Revision,Part_sourc, ViewPartNo,ViewRevision,Part_class,Part_type,Descript,MatlType,Dept_id,Item_note,Offset,    
    Term_dt,Eff_dt, Used_inKit,custno,Inv_note,U_of_meas, Scrap,SetupScrap,USESETSCRP,STDBLDQTY,Phantom_make,StdCost,Make_buy,Status,TopQty,qty,Level, path,   
    sort,UniqBomNo,Buyer,stdcostpr,funcFcUsed_uniq,PrFcUsed_uniq, CustPartNo,CustRev,CustUniqKey,Bom_note)  
 EXEC  [BomIndented] @lcUniqKey,@IncludeMakeBuy,@ShowIndentation,@UserId =@UserId,@lcDate = @lcDate;  
    
 SELECT @lnTotalCnt = @@ROWCOUNT  
 SELECT @lnCnt = 0  
  
 IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'udtBOM_Details')  
 BEGIN  
  WHILE @lnCnt < @lnTotalCnt  
  BEGIN  
   SELECT @lnCnt = @lnCnt + 1  
   SELECT @UniqBomno = UniqBomno FROM @tBom WHERE nId = @lnCnt  
   EXEC GetBomDetCutSheet @uniqBomno, @output OUTPUT  
   UPDATE @tBom SET CutSheet = @output WHERE nId = @lnCnt  
   
  END  
 END  
 -- 06/03/19 VL End}   
       
/*11/05/2014 DRP:  Added:*/      
--  This table will be used to find the Product, revision and uniq_key for the product entered by the user.  The uniq_key from this table will then be used to pull fwd from the [BomIndented] Yelena had created.     
 --- 03/28/17 YS changed length of the part_no column from 25 to 35    
 -- 02/14/2020 Vijay G: increased size of custname column 
 DECLARE @t TABLE(PART_NO CHAR (35),REVISION CHAR(8),descript char (45),UNIQ_key CHAR (10),matltype char(10),bomcustno char(10),CustName char(50), Bom_Note text)     
      
 INSERT @T select part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,isnull(custname,''), bom_note    
    from inventor     
    left outer join CUSTOMER on inventor.BOMCUSTNO = customer.CUSTNO     
    where inventor.UNIQ_KEY = @lcUniqkey    
    and PART_SOURC <> 'CONSG'    
        
--I am declaring the other parameters that would be needed in order to pull in the [BomIndented] procedure      
 declare @lcBomParent char(10)    
 select  @lcBomParent = t1.uniq_key from @t as t1    
/*11/05/2014 End*/     
    
    
-- select B.*,ISNULL(D.Dept_name,SPACE(25)) as dept_name from @tBom B LEFT OUTER JOIN DEPTS D on b.Dept_id=d.DEPT_ID  order by sort --11/05/2014 DRP:  replaced by the below    
    
  select B.*,ISNULL(D.Dept_name,SPACE(25)) as dept_name    
   ,case when i3.UNIQ_KEY <> @lcBomParent and i3.PART_SOURC = 'MAKE' and i3.PHANT_MAKE = 1 then 'Phantom/Make'    
    when i3.UNIQ_KEY <> @lcBomParent and i3.PART_SOURC = 'MAKE' and i3.MAKE_BUY = 1 then 'Make/Buy' else ''  end as MbPhSource    
   ,t1.PART_NO as Prod,t1.REVISION as ProdRev,t1.uniq_key as PUniq_key,t1.descript as ProdDesc,t1.matltype as ProdMatlType,isnull(t1.CustName,'') as CustName,i3.STATUS    
  from  @tBom B     
   LEFT OUTER JOIN DEPTS D on b.Dept_id=d.DEPT_ID    
   left outer join INVENTOR I3 on B.UNIQ_KEY = i3.UNIQ_KEY    
   left outer join INVENTOR i4 on b.Bomparent = I4.UNIQ_KEY     
   cross join @t as t1    
where  1 = CASE @lcStatus WHEN 'Active' THEN CASE WHEN i3.STATUS = 'Active' THEN 1 ELSE 0 END ELSE 1 END --02/18/2015 DRP:  Added    
  order by sort    
      
END