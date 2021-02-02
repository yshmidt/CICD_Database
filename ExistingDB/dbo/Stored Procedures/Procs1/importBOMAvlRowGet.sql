-- =============================================      
-- Author:  David Sharp      
-- Create date: 4/16/2012      
-- Description: gets all adjusted values for the selected import record      
-- 05/21/13 YS check if customer is used at all      
-- 06/26/13 YS use new fnKeepAlphaNumeric() function that uses PATINDEX() to keep alpha-numeric charcaters only in place of fn_RemoveSpecialCharacters()      
-- 11/08/13 DS changed the approach to speed system performance also uses InvtMpnClean table      
-- 10/13/14 YS removed invtmfhd table and replaced with 2 new tables      
-- 08/19/15 YS bring only records with is_deleted=0      
-- Vijay G: 07/20/2018: Set bom value as 1 for newAVL, exists & connected and o if exists & not connected      
-- 11/02/2018 Vijay G Fix BOM Check Box Issus Add Column BOM in temp Table and get its Values     
-- 11/21/2018 Vijay G edit button box if MPN and part mfrg is exists    
-- 11/29/2018 Vijay G Revert Changes of 11/21/2018    
-- 03/01/2019 Vijay G Fix the Issue While Changing Part_No if Part is existing then get all its linked mannufacture and Add Paramerter @uniqKey in SP      
-- 04/08/2019 Vijay G modify sp for bring manufacture for selected part no from part no choose pop up    
-- 04/09/2019 Vijay G Fix the Issue for the Cosign Part Prefrence is shows of Internal Parts    
-- 05/15/2019 Vijay G added one new parameter as i.orderprefe for existing manufacturer preference      
-- 02/25/2020 Vijay G added extra parameter to sort by partmfgr then mfgr_pt_no
-- [importBOMAvlRowGet] '2a35478c-9571-43f8-9716-29e4c55e27a5','89d2b666-9275-e911-b7d5-bf76ea91ad0f',''     
-- =============================================      
CREATE PROCEDURE [dbo].[importBOMAvlRowGet]       
 -- Add the parameters for the stored procedure here      
 -- 03/01/2019 Vijay G Fix the Issue While Changing Part_No if Part is existing then get all its linked mannufacture and Add Paramerter @uniqKey in SP      
 @importId uniqueidentifier,@rowId uniqueidentifier,@uniqKey char(10) =''         
AS      
BEGIN      
 -- SET NOCOUNT ON added to prevent extra result sets from      
 -- interfering with SELECT statements.      
 SET NOCOUNT ON;      
 DECLARE @lock varchar(10)='i00lock'      
       
 -- 11/02/2018 Vijay G Fix BOM Check Box Issus Add Column BOM in temp Table and get its Values       
 DECLARE @iTableA TABLE (rowId uniqueidentifier, avlRowId uniqueidentifier,uniqmfgrhd varchar(10),mfg varchar(MAX),cleanmpn varchar(MAX),      
       matlType varchar(MAX),class varchar(MAX),[validation] varchar(MAX),bom bit,mpn varchar(MAX),preference varchar(MAX))      
         
 DECLARE @iTableO TABLE (rowId uniqueidentifier, avlRowId uniqueidentifier,uniqmfgrhd varchar(10),mfg varchar(MAX),cleanmpn varchar(MAX),      
       matlType varchar(MAX),class varchar(MAX),[validation] varchar(MAX),bom bit,mpn varchar(MAX),preference varchar(MAX))       
     
 -- 11/02/2018 Vijay G Fix BOM Check Box Issus Add Column BOM in temp Table and get its Values       
 -- Get the adjusted values pivoted      
-- 05/15/2019 Vijay G added one new parameter as i.orderprefe for existing manufacturer preference    
 INSERT INTO @iTableA      
 SELECT rowId, avlRowId, uniqmfgrhd, partMfg, UPPER(dbo.fnKeepAlphaNumeric(mpn))cmpn, matlType,class,[Validation],bom,mpn,preference    
  FROM      
  (    
  SELECT iba.fkRowId AS rowId, iba.avlRowId,iba.uniqmfgrhd, fd.fieldName,iba.adjusted,sub.Class, sub.Validation ,iba.bom      
  FROM importBOMFieldDefinitions fd     
  inner join importBOMAvl iba ON fd.fieldDefId = iba.fkFieldDefId      
  INNER JOIN (SELECT fkimportId,avlRowId,MAX([status]) as Class,MIN([validation]) as [Validation]       
     FROM importBOMAvl WHERE fkImportId=@importId AND fkRowId=@rowId      
     GROUP BY fkImportId,avlRowId) sub ON sub.avlRowId=iba.avlRowId      
     WHERE iba.fkImportId = @importId AND iba.fkRowId=@rowId    
   )st      
  PIVOT      
  (MAX(adjusted) FOR fieldName IN (partMfg,mpn,matlType,preference))AS pvt        
 -- 11/02/2018 Vijay G Fix BOM Check Box Issus Add Column BOM in temp Table and get its Values        
 -- Get the original values pivoted      
 -- 05/15/2019 Vijay G added one new parameter as i.orderprefe for existing manufacturer preference     
 INSERT INTO @iTableO      
 SELECT rowId, avlRowId, uniqmfgrhd, partMfg, UPPER(dbo.fnKeepAlphaNumeric(mpn))cmpn, matlType,Class,[Validation],bom,mpn,preference      
  FROM      
  (    
  SELECT iba.fkRowId AS rowId,iba.avlRowId,iba.uniqmfgrhd, fd.fieldName,iba.original,sub.Class,sub.[Validation] ,iba.bom       
  FROM importBOMFieldDefinitions fd     
  inner join importBOMAvl iba ON fd.fieldDefId = iba.fkFieldDefId      
  INNER JOIN (SELECT fkimportId,avlRowId,MAX([status]) as Class,MIN([validation]) as [Validation]       
        FROM importBOMAvl WHERE fkImportId=@importId AND fkRowId=@rowId      
        GROUP BY fkImportId,avlRowId) sub ON sub.avlRowId=iba.avlRowId      
   WHERE iba.fkImportId = @importId AND iba.fkRowId=@rowId)st      
  PIVOT      
  (MAX(original) FOR fieldName IN (partMfg,mpn,matlType,preference))AS pvt      
 -- 11/29/2018 Vijay G Revert Changes of 11/21/2018       
-- 03/01/2019 Vijay G Fix the Issue While Changing Part_No if Part is existing then get all its linked mannufacture and Add Paramerter @uniqKey in SP      
 -- 04/08/2019 Vijay G modify sp for bring manufacture for selected part no from part no choose pop up    
  ;WITH INTAVL AS (      
  SELECT --b.rowId,m.UNIQ_KEY      
  CASE WHEN @uniqKey<>'' THEN m.UNIQ_KEY       
  ELSE b.UNIQ_KEY END UNIQ_KEY,      
  isnull(c.UNIQ_KEY,SPACE(10)) AS CustUniqKey ,m.custno          
  FROM importBOMHeader h       
  INNER JOIN importBOMFields b ON h.importId=b.fkImportId          
  INNER JOIN INVENTOR m ON ((@uniqKey='' and b.uniq_key=m.UNIQ_KEY  )OR(@uniqKey<>'' and m.UNIQ_KEY =@uniqKey))         
  LEFT OUTER JOIN INVENTOR c ON ((@uniqKey='' and b.uniq_key=c.INT_UNIQ )OR(@uniqKey<>'' and c.INT_UNIQ =@uniqKey))  AND h.CUSTNO=c.CUSTNO          
  WHERE b.rowId=@rowId AND fkFieldDefId='4284549D-0788-E111-B197-1016C92052BC'      
  )      
     
 ---- 11/21/2018 Vijay G edit button box if MPN and part mfrg is exists    
 -- DECLARE  @iTable importBom      
     
 -- INSERT INTO @iTable      
 -- EXEC [dbo].[sp_getImportBOMItems] @importId      
    
 --;with INTAVL AS     
 --(    
 --SELECT m.UNIQ_KEY,isnull(c.UNIQ_KEY,SPACE(10)) AS CustUniqKey ,m.custno      
 --FROM importBOMHeader h     
 --INNER JOIN importBOMFields b ON h.importId=b.fkImportId      
 --Inner join @iTable temp on b.fkImportId=temp.importId     
 --INNER JOIN INVENTOR m ON ( (temp.uniq_key=m.UNIQ_KEY ) OR (m.PART_NO =temp.partno AND m.REVISION =temp.rev AND m.CUSTPARTNO =temp.custPartNo AND m.CUSTREV = temp.crev))    
 --LEFT OUTER JOIN INVENTOR c ON b.uniq_key=c.INT_UNIQ AND h.CUSTNO=c.CUSTNO      
 --WHERE b.rowId=@rowId AND fkFieldDefId='4284549D-0788-E111-B197-1016C92052BC'    
 -- )     
      
 SELECT COALESCE(imp.avlRowId, newid()) avlRowId,COALESCE(imp.Omfg,'')oMfg,COALESCE(imp.mfg,m.PARTMFGR) mfg,COALESCE(imp.Ompn,'')oMpn,      
   COALESCE(imp.mpn,m.MFGR_PT_NO) mpn,      
   COALESCE(imp.OmatlType,'')oMatlType,COALESCE(imp.matltype,m.MATLTYPE) matlType,      
    
  -- 04/09/2019 Vijay G Fix the Issue for the Cosign Part Prefrence is shows of Internal Parts      
   CASE WHEN c.UNIQMFGRHD IS NOT NULL THEN COALESCE(c.ORDERPREF,imp.Opreference)     
                                      ELSE CASE WHEN i.UNIQMFGRHD IS NOT NULL and (a.CUSTNO=''OR a.CUSTNO='000000000~')     
                     THEN COALESCE(i.ORDERPREF, imp.Opreference)     
                     ELSE CASE WHEN imp.Opreference IS NULL THEN i.ORDERPREF ELSE imp.Opreference END END     
           END oPreference,    
   CASE WHEN c.UNIQMFGRHD IS NOT NULL THEN COALESCE(c.ORDERPREF,imp.preference)     
                                      ELSE CASE WHEN i.UNIQMFGRHD IS NOT NULL and (a.CUSTNO=''OR a.CUSTNO='000000000~')     
                     THEN COALESCE(i.ORDERPREF, imp.preference)     
            ELSE CASE WHEN imp.preference IS NULL THEN i.ORDERPREF ELSE imp.preference END END    
           END preference,    
            
   --Vijay G: 07/20/2018: Set bom value as 1 for newAVL, exists & connected and o if exists & not connected      
   --CASE WHEN c.UNIQMFGRHD IS NULL THEN CASE WHEN imp.rowId IS NULL THEN 0 ELSE 1  END ELSE 1 END [bom],     
   -- 11/02/2018 Vijay G Fix BOM Check Box Issus Add Column BOM in temp Table and get its Values      
   CASE When (imp.bom IS NULL) THEN 0 ELSE imp.bom END as [bom],    
   --CASE When (imp.rowId IS NULL) THEN 0 ELSE 1 END [bom],      
   CASE WHEN i.uniqmfgrhd IS NULL THEN 1 ELSE null END [load],      
   CASE WHEN c.UNIQMFGRHD IS NULL THEN       
    CASE WHEN i.UNIQMFGRHD IS NULL THEN null ELSE 0  END ELSE 1 END [cust],      
   CASE WHEN imp.rowId IS NULL THEN @lock ELSE       
    CASE WHEN i.uniqmfgrhd IS NULL THEN imp.class ELSE @lock END END AS class,      
   '01system' [validation],i.UNIQMFGRHD uniqmfgrhd,      
   CASE WHEN NOT imp.rowId IS NULL THEN CASE WHEN i.uniqmfgrhd IS NULL THEN 'newAVL' ELSE 'exists & connected' END ELSE 'exists & not connected' END    
  --10/13/14 YS removed invtmfhd table and replaced with 2 new tables      
  --FROM INTAVL a INNER JOIN INVTMFHD i on a.uniq_key=i.UNIQ_KEY INNER JOIN InvtMpnClean ic ON ic.mfgr_pt_no=i.MFGR_PT_NO AND ic.partMfgr=i.PARTMFGR      
  FROM INTAVL a     
  INNER JOIN InvtMPNLink i on a.uniq_key=i.UNIQ_KEY and i.is_deleted=0      
   -- 08/19/15 YS bring only records with is_deleted=0      
   INNER JOIN MfgrMaster M ON i.mfgrMasterId=M.MfgrMasterId and m.is_deleted=0     
   INNER JOIN InvtMpnClean ic ON ic.mfgr_pt_no=m.MFGR_PT_NO AND ic.partMfgr=m.PARTMFGR      
   OUTER APPLY       
   --10/13/14 YS removed invtmfhd table and replaced with 2 new tables      
   --(select * FROM INVTMFHD i2 WHERE a.CustUniqKey=i2.UNIQ_KEY AND i2.MFGR_PT_NO=i.MFGR_PT_NO AND i2.PARTMFGR=i.PARTMFGR) c      
   -- 08/19/15 YS bring only records with is_deleted=0      
   (    
  select i2.*       
  FROM InvtMPNLink i2     
  INNER JOIN MfgrMaster M2 ON i2.mfgrMasterId=M2.MfgrMasterId       
  WHERE a.CustUniqKey=i2.UNIQ_KEY AND m2.MFGR_PT_NO=m.MFGR_PT_NO AND m2.PARTMFGR=m.PARTMFGR and m2.is_deleted=0 and i2.is_deleted=0    
   ) c      
   FULL OUTER JOIN     
   (     
   SELECT A.rowId,A.avlRowId,A.uniqmfgrhd,o.mfg Omfg,a.mfg,o.mpn Ompn, A.mpn,O.matlType OmatlType,A.matlType, a.cleanmpn, a.class,a.bom,    
   o.preference Opreference,a.preference    
   FROM @iTableA A     
   INNER JOIN @iTableO O ON A.avlRowId=O.avlRowId    
   )imp     
   ON imp.cleanmpn=ic.cleanmpn AND imp.mfg=ic.partMfgr      
   ORDER BY [load] DESC,[bom] DESC,ic.partMfgr,ic.mfgr_pt_no  -- 02/25/2020 Vijay G added extra parameter to sort by partmfgr then mfgr_pt_no    
       
       
       
       
       
       
       
       
       
       
       
       
 --DECLARE @custno varchar(10),@uniq_key varchar(10)      
 ----05/21/13 YS check for NULL or standard price customer that is the same as no customer      
 --SELECT @custno = CASE WHEN Custno IS NULL or custno='000000000~' THEN ' ' ELSE Custno END FROM importBOMHeader WHERE importId = @importId      
       
 --SELECT @uniq_key = uniq_key FROM importBOMFields WHERE fkImportId=@importId AND rowId=@rowId      
       
 --   DECLARE @iTableA TABLE (rowId uniqueidentifier, avlRowId uniqueidentifier,uniqmfgrhd varchar(10),mfg varchar(MAX),mpn varchar(MAX),matlType varchar(MAX))       
 --   DECLARE @iTableO TABLE (rowId uniqueidentifier, avlRowId uniqueidentifier,uniqmfgrhd varchar(10),mfg varchar(MAX),mpn varchar(MAX),matlType varchar(MAX))       
 --DECLARE @itemClass TABLE (avlRowId uniqueidentifier, bom bit, [load] bit, class varchar(MAX), [validation] varchar(MAX),uniqmfgrhd varchar(20))      
 --DECLARE @cAvl TABLE (int_uniq varchar(10),partno varchar(50),rev varchar(4),mpn varchar(50),mfg varchar(100),matlType varchar(20),uniqmfgrhd varchar(20),cust bit)      
       
 ---- Get the adjusted values pivoted      
 --INSERT INTO @iTableA      
 --SELECT rowId, avlRowId, uniqmfgrhd, partMfg, mpn, matlType      
 -- FROM      
 -- (SELECT iba.fkRowId AS rowId, iba.avlRowId,iba.uniqmfgrhd, fd.fieldName,iba.adjusted      
 --  FROM importBOMFieldDefinitions fd inner join importBOMAvl iba ON fd.fieldDefId = iba.fkFieldDefId      
 --  WHERE iba.fkImportId = @importId AND iba.fkRowId=@rowId)st      
 -- PIVOT      
 -- (      
 -- MAX(adjusted)      
 -- FOR fieldName IN       
 -- (partMfg,mpn,matlType)      
 -- )AS pvt      
        
 ---- Get the original values pivoted      
 --INSERT INTO @iTableO      
 --SELECT rowId, avlRowId, uniqmfgrhd, partMfg, mpn, matlType      
 -- FROM      
 -- (SELECT iba.fkRowId AS rowId,iba.avlRowId,iba.uniqmfgrhd, fd.fieldName,iba.original      
 --  FROM importBOMFieldDefinitions fd inner join importBOMAvl iba ON fd.fieldDefId = iba.fkFieldDefId      
 --  WHERE iba.fkImportId = @importId AND iba.fkRowId=@rowId)st      
 -- PIVOT      
 -- (      
 -- MAX(original)      
 -- FOR fieldName IN       
 -- (partMfg,mpn,matlType)      
 -- )AS pvt      
       
 ---- Get the avlRow class, type, bom etc.      
 --INSERT INTO @itemClass      
 --SELECT avlRowId AS rowId,MAX(CAST(bom AS int)),/*CASE WHEN NOT MAX(uniqmfgrhd)IS NULL THEN null /*WHEN MAX(uniqmfgrhd)<>'' THEN null*/ ELSE*/ MAX(CAST([load] AS INT)) /*END*/,MAX(status) AS class, MIN(validation),MIN(uniqmfgrhd)      
 -- FROM importBOMAvl iba      
 -- WHERE iba.fkImportId = @importId AND fkRowId=@rowId      
 -- GROUP BY fkRowId,avlRowId      
       
 --DECLARE @cpartno varchar(25), @ncPartno varchar(25)      
 --SELECT @cpartno = adjusted FROM importBOMFields where fkFieldDefId='2CF7DE74-0688-E111-B197-1016C92052BC' AND fkImportId=@importId AND rowId=@rowId      
 ----SELECT @cpartno = CUSTPARTNO FROM INVENTOR WHERE INT_UNIQ=@uniq_key AND CUSTNO=@custno      
 ----IF @cpartno IS NULL SET @cpartno=@ncPartno      
       
 ---- Get a list of all AVLs tied to the selected internal partnumber and indicate if connected to the import customer AVL      
 --INSERT INTO @cAvl(int_uniq,partno,rev,mfg,mpn,matlType,uniqmfgrhd,cust)       
 --SELECT i.UNIQ_KEY,part_no,revision,h.PARTMFGR,h.MFGR_PT_NO,h.MATLTYPE,h.UNIQMFGRHD,ISNULL(z.cust,CAST(0 as bit))cust      
 -- FROM INVENTOR i INNER JOIN INVTMFHD h ON i.uniq_key = h.uniq_key       
 --    LEFT OUTER JOIN       
 --    (SELECT CAST(1 as bit) AS cust,h1.MFGR_PT_NO, h1.PARTMFGR FROM INVENTOR i INNER JOIN INVTMFHD h1 ON i.uniq_key = h1.uniq_key      
 --     WHERE i.INT_UNIQ=CASE WHEN @custno='' OR @custno='000000000~' OR @custno IS NULL  THEN ' ' ELSE @uniq_key END      
 --     AND i.UNIQ_KEY = CASE WHEN @custno='' OR @custno='000000000~' OR @custno IS NULL  THEN @uniq_key ELSE i.UNIQ_KEY END      
 --     AND i.CUSTNO = CASE WHEN @custno='' OR @custno='000000000~' OR @custno IS NULL  THEN ' ' ELSE @custno END      
 --     and IS_DELETED <> 1 ) Z ON z.MFGR_PT_NO=h.MFGR_PT_NO AND z.PARTMFGR = h.PARTMFGR      
 -- WHERE i.UNIQ_KEY=@uniq_key AND IS_DELETED<>1      
         
      
 ---- Join the results      
 ----AVL added by import, does not exist      
 ---- 06/26/13 YS use new fnKeepAlphaNumeric() function that uses PATINDEX() to keep alpha-numeric charcaters only in place of fn_RemoveSpecialCharacters()      
 --SELECT CAST(a.avlRowId AS varchar(50))avlRowId,o.mfg oMfg,a.mfg,o.mpn oMpn,a.mpn,o.matlType oMatlType,a.matlType, t2.bom,t2.[load] AS [load],CAST(c.cust as bit)cust, t2.class, t2.[validation],c.uniqmfgrhd,'newAVL'       
 --FROM @iTableA a       
 -- INNER JOIN @itemClass t2 ON a.avlRowId = t2.avlRowId       
 -- INNER JOIN @iTableO o ON a.avlRowId=o.avlRowId      
 -- LEFT OUTER JOIN @cAvl c ON a.mfg=c.mfg AND       
 --  dbo.fnKeepAlphaNumeric(a.mpn)=dbo.fnKeepAlphaNumeric(c.mpn)      
 -- WHERE c.mfg IS NULL      
 --UNION ALL      
 ----existing AVLs added to import row      
 --SELECT CAST(a.avlRowId AS varchar(50))avlRowId,o.mfg oMfg,a.mfg,o.mpn oMpn,a.mpn,o.matlType oMatlType,a.matlType, t2.bom,       
 --  null [load],isnull(c.cust,CAST(0 as bit))cust, @lock, t2.[validation],c.uniqmfgrhd,'exist & connected'      
 -- FROM @iTableA a       
 --  INNER JOIN @itemClass t2 ON a.avlRowId = t2.avlRowId       
 --  INNER JOIN @iTableO o ON a.avlRowId=o.avlRowId      
 --  INNER JOIN @cAvl c ON a.mfg=c.mfg AND       
 --   dbo.fnKeepAlphaNumeric(a.mpn)=dbo.fn_RemoveSpecialCharacters(c.mpn)      
 --  WHERE NOT c.mfg IS NULL      
 --UNION ALL      
 ----existing AVL not added to import row      
 --SELECT NEWID(),'',c.mfg,'',c.mpn,'',c.matlType,isnull(c.cust,CAST(0 AS bit)),CAST(null AS bit),c.cust,'i00grey','01system',c.uniqmfgrhd,'exists not connected'      
 -- FROM @cAvl c       
 --  LEFT OUTER JOIN @iTableA a ON c.mfg=a.mfg AND       
 --   dbo.fn_RemoveSpecialCharacters(c.mpn)=dbo.fn_RemoveSpecialCharacters(a.mpn)      
 -- WHERE a.mfg IS NULL      
       
        
        
        
 --SELECT CAST(a.avlRowId AS varchar(50))avlRowId,o.mfg oMfg,a.mfg,o.mpn oMpn,a.mpn,o.matlType oMatlType,a.matlType, t2.bom,t2.[load] AS [load],CAST(c.cust as bit)cust, t2.class, t2.[validation],c.uniqmfgrhd,'newAVL'       
 --FROM @iTableA a       
 -- INNER JOIN @itemClass t2 ON a.avlRowId = t2.avlRowId       
 -- INNER JOIN @iTableO o ON a.avlRowId=o.avlRowId      
 -- LEFT OUTER JOIN @cAvl c ON a.mfg=c.mfg AND       
 --  REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(a.mpn)),' ','')=REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(c.mpn)),' ','')      
 -- WHERE c.mfg IS NULL      
 --UNION ALL      
 ----existing AVLs added to import row      
 --SELECT CAST(a.avlRowId AS varchar(50))avlRowId,o.mfg oMfg,a.mfg,o.mpn oMpn,a.mpn,o.matlType oMatlType,a.matlType, t2.bom,       
 --  null [load],isnull(c.cust,CAST(0 as bit))cust, @lock, t2.[validation],c.uniqmfgrhd,'exist & connected'      
 -- FROM @iTableA a       
 --  INNER JOIN @itemClass t2 ON a.avlRowId = t2.avlRowId       
 --  INNER JOIN @iTableO o ON a.avlRowId=o.avlRowId      
 --  INNER JOIN @cAvl c ON a.mfg=c.mfg AND       
 --   REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(a.mpn)),' ','')=REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(c.mpn)),' ','')      
 --  WHERE NOT c.mfg IS NULL      
 --UNION ALL      
 ----existing AVL not added to import row      
 --SELECT NEWID(),'',c.mfg,'',c.mpn,'',c.matlType,isnull(c.cust,CAST(0 AS bit)),CAST(null AS bit),c.cust,'i00grey','01system',c.uniqmfgrhd,'exists not connected'      
 -- FROM @cAvl c       
 --  LEFT OUTER JOIN @iTableA a ON c.mfg=a.mfg AND       
 --   REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(c.mpn)),' ','')=REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(a.mpn)),' ','')      
 -- WHERE a.mfg IS NULL      
      
      
      
 --SELECT * FROM @itemClass      
 --SELECT CAST(a.avlRowId AS varchar(50))avlRowId,o.mfg oMfg,a.mfg,o.mpn oMpn,a.mpn,o.matlType oMatlType,a.matlType, t2.bom,isnull(t2.[load],CAST(0 as bit))[load],CAST(c.cust as bit)cust, t2.class, t2.[validation],c.uniqmfgrhd       
 --FROM @iTableA a       
 -- INNER JOIN @itemClass t2 ON a.avlRowId = t2.avlRowId       
 -- INNER JOIN @iTableO o ON a.avlRowId=o.avlRowId      
 -- LEFT OUTER JOIN @cAvl c ON a.mfg=c.mfg AND       
 --  REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(a.mpn)),' ','')=REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(c.mpn)),' ','')      
 -- WHERE c.mfg IS NULL      
 --SELECT CAST(a.avlRowId AS varchar(50))avlRowId,o.mfg oMfg,a.mfg,o.mpn oMpn,a.mpn,o.matlType oMatlType,a.matlType, t2.bom,       
 --  null [load],isnull(c.cust,CAST(0 as bit))cust, @lock, t2.[validation],c.uniqmfgrhd       
 -- FROM @iTableA a       
 --  INNER JOIN @itemClass t2 ON a.avlRowId = t2.avlRowId       
 --  INNER JOIN @iTableO o ON a.avlRowId=o.avlRowId      
 --  INNER JOIN @cAvl c ON a.mfg=c.mfg AND       
 --   REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(a.mpn)),' ','')=REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(c.mpn)),' ','')      
 --  WHERE NOT c.mfg IS NULL      
 --SELECT NEWID(),'',c.mfg,'',c.mpn,'',c.matlType,isnull(c.cust,CAST(0 AS bit)),CAST(null AS bit),c.cust,'i00grey','01system',c.uniqmfgrhd      
 -- FROM @cAvl c       
 --  LEFT OUTER JOIN @iTableA a ON c.mfg=a.mfg AND       
 --   REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(c.mpn)),' ','')=REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(a.mpn)),' ','')      
 -- WHERE a.mfg IS NULL      
      
END