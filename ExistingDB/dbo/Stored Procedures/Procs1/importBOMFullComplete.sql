-- =============================================                                  
-- Author:  David Sharp                                  
-- Create date: 6/26/2012                                  
-- Description: load all the correct parts                                  
-- 05/06/13 YS Finishing up the complete upload                                  
-- 05/21/13 YS check for NULL or standard price customer that is the same as no customer                                  
-- 05/29/13 YS Fixes                                  
-- 05/30/13 need to fetch prior to continue otherwise will be infinite loop                                  
-- 05/30/13 had problem when internal part exists and consign parts did not, new AVLS did not load onto consign parts                                   
-- 06/05/13 YS populate information from parttype table                                  
-- 06/06/13 YS check if the ASSY part exists                                  
-- 06/10/13 YS make sure absence of records in the parttype table is handled                                  
-- 06/26/13 YS use new fnKeepAlphaNumeric() function that uses PATINDEX() to keep alpha-numeric charcaters only in place of fn_RemoveSpecialCharacters()                                  
-- 07/02/13 YS make sure all [load] are in []                                   
-- 11/11/13 DS changed note add using CAST as varchar(100), made @userId dynamic, and added filter to consigned search using @custno                                  
-- 12/09/13 YS added check for the length for units of measure, and check for the error returned after the insert into inventory                                  
-- 02/17/14 YS check if no avl was uploaded for the new part create generic avl                                  
-- 02/19/14 use @tInternalInventor                                  
-- 02/20/14 YS use OUTPUT INTO to get information about missing avls and use it to add default location                                  
-- 06/17/14 DS added errDate to error recording                                  
-- 09/29/14 YS when the same parts with the different item number is loaded the system will try to generate duplicate parts in the inventory and fail.                                   
-- 10/13/14 YS removed invtmfhd table and replaced with 2 new tables                                  
-- 03/06-03/08/15 YS added make buy                                  
-- 07/28/15 Anuj/YS - modified to generate an error if no records loaded into Bom_det. Also clear the error log at the beginning of this procedure for the current importid                                  
 -- 07/31/15 Raviraj Added UseSetScrp and StdBldQty for the Assembly, insert the values in Inventor table for new record and update for existing record                                  
--08/11/15 YS overwrite USESETSCRP and STDBLDQTY only if @stdbldqty<>0, otherwise use the existsing settings.                                   
--If we find ourslevs needing the to be able to re-set  stdbldqty to 0 , we will have to change staructure of the importBomHeader.stdbuild and usesetup to take null values                                  
-- that way we will know that the user did not populate any scrap data. For now will assume that 0 and false is good enough for indication that user did not change                                   
-- anything                                  
-- 11/10/15 YS inventor.inv_note was not populated is the part already in the system                                  
-- 06/01/16 YS update autolocation based on parttype table                                   
--- 10/03/16 YS save stdcost if provided as material cost                                  
-- 12/08/16 YS fix the problem found by paramit , where if existsing part has avl like 'test1' and uploaded part has avl listed as 'test-1' the system will properly identify the existsing avl,                                   
---but will load new avl 'test-1' onto existing consign part. Here we need to use                                   
--- dbo.fnKeepAlphaNumeric(AD.Mfgr_pt_no)=dbo.fnKeepAlphaNumeric(m.Mfgr_pt_no))                         
--12/09/16 YS make sure cost is 0 for consign parts                                  
--- 03/28/17 YS changed length of the part_no column from 25 to 35                                  
--- ---08/16/17 YS check for u_of_m and if like 'EA%' round up                                  
--12/06/17 YS multiple modifications                                  
--   1. Error handling was assigning error parameteres to the variables, but not using them                                  
---  3. Problem if qty had scientific notation                                  
---  4. If part number set to manual and user had the same new part in the different WC, upload failed.                                   
-- 02/22/2018 : Vijay G : IsFlagged & IsSystemNote columns no longer in used                                  
-- 03/04/18: Vijay G: Update the part status and bom_status if InActive then set as Active                                  
-- 03/08/2018 : Vijay G : Insert the bom assembly notes into wmNotes and wmNoteRalationship table.                                  
-- 04/20/18 Vijay G : Moved the Auto Number and Auto Make No setting value from MICSSYS,InvtSetup table to MnxSettingsManagement and wmSettingsManagement table                                  
-- 04/24/2018 : Vijay G : Get bomNote fieldDefId from importBOMFieldDefinitions                                  
-- 04/24/2018 : Vijay G : Get invNote fieldDefId from importBOMFieldDefinitions                                  
-- 04/25/2018: Vijay G: To auto generate internal part with customer prefix check Customer has prefix and UseCustPfx must be set to true.                                  
-- 04/30/18  YS minor modifications to customer prefix; 1. getting customer prefix info moved out of the loop; 2. Add '-' after customer prefix                                   
-- 05/02/2018: Vijay G: Removed the commented line                                  
-- Vijay G: 05/16/18: Set BOM value as 0 all AVL which are exist but not connected to the part.                                  
--- 05/25/18 YS added antiavl if the settings is to disallow auto-adding new avl to the existsing BOMs other than the one loaded                                  
-- 06/01/18 Vijay G : Get the setting value by setting name if exist in wmSettingsManagement otherwise from MnxSettingsManagement                                  
-- 06/08/18 Vijay G : Moved the Disable Automatic BOM AVL Update setting value from InvtSetup table to MnxSettingsManagement and wmSettingsManagement table                                  
-- 07/25/18 Vijay G : Renamed the setting name from "AutomaticBOMAVLUpdate" to "DisableAutoBOMAVLUpdate"                                  
-- 08/20/18 YS add missing antiavl for the existsing consign part if bom assigend to the custno already exists                                  
   --- new avl should not be added                                  
--08/21/18 YS fix use new invtmplink and mfgrmaster tables                             
   --- new avl should not be added                                
-- 09/04/2018 Vijay G Remove And Condition it Will get wrong data to Insert Record in AntiAVL                              
-- 09/04/2018 Vijay G Remove the Use of function fnKeepAlphaNumeric in And Condition for mfgr_pt_no                              
-- 09/10/2018 Vijay G Newly Added MPN are Approved for the other Assembly Where same component is used                              
-- 09/20/18 YS missing change for the part_no length from 25 to 35 charcters                                      
-- 10/12/2018 Vijay G Update the uniq_key of table @tInternalInventor if part match with inventor table with part_no,revision,custpartno                                
-- 10/16/2018 Vijay G Update the uniq_key of table @iTable if part match with inventor table with part_no,revision,custpartno                               
-- 10/16/2018 Vijay G For Now I Just updated the uniq_key and i check why uniq_key is not populating it self I Also Change the positon of Code for update uniq_key                                
-- 10/17/2018 Vijay G To get bom item import level notes to BOM Summary                              
-- 10/22/2018 Vijay G Fix the Issue for the Newly Added MPN are not checked in AVL Fixes Add And Condition BOMPARENT<>@AssyUniqKey                              
-- 10/22/2018 Vijay G : Check for existing notes if exist and then update WmNoteRelationship table record with new noteid                               
-- 10/22/2018 Vijay G : Check for existing notes if exist and remove the notes in edit mode                              
-- 10/26/2018 Vijay G : Fix the Duplicate Inventor Issue no need for and condition AND i.CUSTPARTNO = t.CUSTPARTNO AND i.CUSTREV =t.CustRev and update custno custno if CUSTPARTNO<>''                            
-- 10/26/2018 Vijay G :Delete consign parts from @tInternalInventor Table                            
-- 10/30/2018 Vijay G : insert the Value for useipkey from the match found in the PartClass Table for the Added new Assembly and Components                            
-- 11/20/2018 Vijay G Add group by clause for the insert data in the Antiavl                        
-- 11/29/18 Vijay G Update Assembly cust no if assembly don't have components                        
-- 01/15/2019 Vijay G :Put the Entry of userid in the Modifiedby column of BOM_Det table                            
-- 01/18/2019 : Vijay G : Fix the Issue the BOM_Status is not converted from InActive to Active after Import Data                            
-- 01/25/2019 : Vijay G : Fix the Issue MAKE_BUY Column Inserted with Null Value while Creating Make Part                            
-- 05/07/2019 : Vijay G : Fix the BOM Import Issue string/binary Data Truncated for Partmfgr, mfgrpartno and matlType NVARCHAR(MAX)                           
-- 05/07/2019 : Vijay G : LastChangInit Not Populated for the Newly Added Part                          
-- 05/13/2019 : Vijay G : LASTCHANGEUSERID Not Populated for the Newly Added Part                          
-- 05/15/2019 : Vijay G : Modify sp for add order prefernce for manufacture in invtmpnlink table as preference                           
-- 05/15/2019 : Vijay G : Modify sp for add tow check box as sid and serial part                          
-- 05/15/2019 : Vijay G : modify sp for insert  sid value into inventor if sid is check comment this line 'ISNULL(class.useIpKey,CAST(0 as BIT))'                          
-- 05/15/2019 : Vijay G : modify sp for cast part mfgr to accept only 8 character                          
-- 05/15/2019 : Vijay G : Modify sp for change status from part load to Partialy Loaded in bom screen                          
-- 05/21/2019 Vijay G: If description is null of empty then we use part_no as desciption                          
-- 05/21/2019 Vijay G: In the Completed by Column Add Userid insted of initials                          
-- 06/06/2019 Vijay G: Insert default 99 if Prefrence value is null for the prviously added templates                          
-- 07/17/2019 Vijay G: Use class Default warehouse if it have value otherwise setup default                          
-- 08/29/2019: Vijay G: Fetch those records where the Part_sourc='BUY'                          
-- 08/29/2019: Vijay G: Comment the code which not in use now                        
-- 08/29/2019: Vijay G: Update records where Part_sourc='BUY'                        
-- 08/29/2019: Vijay G: Added new block with cursor to use auto numbering setting for partsource is in "MAKE,PHANTOM"                       
-- 12/04/2019 Vijay G : Added default MGFR "GENR" if user not added any mfgr with component                    
-- 02/14/2020 Nitesh B : Insert AspnetBuyer from PartClass table if PartClass having default buyer                        
-- 02/19/2020 Rajendra K : Insert Blank value into Package Column of Inventor table            
-- 02/26/2020 Vijay G : Added avls with customer part which associated with its internal part                
--02/27/2020 Vijay G :Removed code of part number setting              
--02/27/2020 Vijay G: Added block of code to genrating part number base part class number setup              
--02/27/2020 Vijay G: Made some changes to see SP in proper format               
--04/07/2020 Sachin B:Commeneted old code of inventor note and add new block           
--04/15/2020 Sachin B:Update condition to for prefix fix    
--04/17/2020 Sachin B: Added trim function And removed '-' from thenext of type prefix      
--05/14/2020 Sachin B: Set the empty uniq_ky column 
--05/14/2020 Sachin B: Select user name intead of initials
--09/24/2020 Sachin B: Part Master Note Data Copy Issue
-- 10/08/2020 Sachin B Fix the Consign Part AVL Attach Issue
-- 12/24/2020 : Sachin B : Fix the Note Record Duplication Issue WMNotes BOM_Header and Inventor
-- 01/06/2021 : Sachin B : Add the location column for the import
--01/13/21 YS added distinct in the source part of the Merge to avoid multiple records result in the source and fail to merge  
-- =============================================                          
CREATE PROCEDURE [dbo].[importBOMFullComplete]                                   
 -- Add the parameters for the stored procedure here                                  
 --declare                                  
 @importId uniqueIdentifier=null,                                  
 @userId uniqueIdentifier=null                                  
AS                                  
BEGIN                                  
 -- SET NOCOUNT ON added to prevent extra result sets from                                  
 -- interfering with SELECT statements.                                  
 SET NOCOUNT ON;                                         
                                   
    /* Get user initials for the header */                        
	--05/14/2020 Sachin B: Select user name intead of initials                        
    DECLARE @userInit varchar(256)                                    
    SELECT @userInit = COALESCE(UserName,'') FROM aspnet_Users WHERE userId = @userId                                    
    --02/27/2020 Vijay G :Removed code of part number setting              
    --DECLARE @AutoNumber bit,@AutoMakeNo bit                                    
    --05/13/13 YS check if auto number for regular and make parts                                  
 -- 04/20/18 Vijay G : Moved the Auto Number and Auto Make No setting value from MICSSYS,InvtSetup table to MnxSettingsManagement and wmSettingsManagement table                                  
    --SELECT @AutoNumber =MicsSys.XxPtNoSys FROM MICSSYS                                  
 -- 04/20/18 Vijay G : Check Auto Number setting value from wmSettingsManagement                      
 -- 06/01/18 Vijay G : Get the AutoPartNumber setting value by setting name if exist in wmSettingsManagement otherwise from MnxSettingsManagement                                  
 --02/27/2020 Vijay G :Removed code of part number setting              
 --SELECT @AutoNumber= isnull(w.settingValue,m.settingValue)                                       
 -- FROM MnxSettingsManagement M left outer join wmSettingsManagement W on m.settingId=w.settingId                                    
 -- WHERE settingName ='AutoPartNumber'                                  
                             
 -- 04/20/18 Vijay G : Check Auto Make Number setting value from wmSettingsManagement                                  
 -- 06/01/18 Vijay G : Get the AutoMakeNo setting value by setting name if exist in wmSettingsManagement otherwise from MnxSettingsManagement                                  
    -- SELECT @AutoMakeNo =InvtSetup.lAutoMakeNo FROM InvtSetup                                  
 --02/27/2020 Vijay G :Removed code of part number setting              
 --SELECT @AutoMakeNo= isnull(w.settingValue,m.settingValue)                                       
 -- FROM MnxSettingsManagement M left outer join wmSettingsManagement W on m.settingId=w.settingId                                    
 -- WHERE settingName ='AutoMakePartNumber'                                  
    -- 12/11/13 YS added varibales to hold error information                                  
 DECLARE @ERRORNUMBER Int= 0                                  
 ,@ERRORSEVERITY int=0                                  
 ,@ERRORPROCEDURE varchar(max)=''                                  
 ,@ERRORLINE int =0                                  
 ,@ERRORMESSAGE varchar(max)=' '                                  
    -- 07/28/15 YS clear all the errors for the current importid                                  
 delete FROM importBOMErrors where importId=@importId                                  
 /*Run the code to convert the import records to item master records*/                                  
 /* 1 - Gather current import parts */                         
 -- 04/24/13 YS use importBom udf table type to identify iTable                                  
 -- 04/26/13 YS use tImportBomInventor udf table type to id inventory fields only                                  
 -- 02/20/14 YS added new variable @defaultUniqwh                         
 -- 07/31/15 Raviraj Added UseSetScrp and StdBldQty                                  
 --- 03/28/17 YS changed length of the part_no column from 25 to 35                                  
 DECLARE @custno char(10),@AssySource char(10),@AssyUniqKey char(10),@AssyNum char(35),@AssyRev char(8),@AssyDesc char(45),                                  
 @AssyClass char(8),@Assytype char(8),@AssyMfgrHd char(10),@AssyUniqWh char(10),@defaultUniqWh char(10), @useSetUp bit, @stdBldQty numeric(8,0)                                  
                                   
                                   
 --05/21/13 YS check for NULL or standard price customer that is the same as no customer                                  
 -- 07/31/15 Raviraj Added UseSetScrp           
 SELECT @custno=CASE WHEN Custno IS NULL or rtrim(custno)='000000000~' THEN ' ' ELSE rtrim(custNo) END ,                                  
 @AssySource= rtrim(H.Source),                                   
 @AssyUniqKey=rtrim(H.Uniq_key),                                  
 @AssyNum =rtrim(H.assyNum),                                  
 @AssyRev =rtrim(H.assyRev) ,                                  
 @AssyDesc=rtrim(H.assyDesc)  ,                           
 @AssyClass =rtrim(H.partClass) ,                                  
 @Assytype =rtrim(H.partType),                                  
 @useSetUp = H.useSetUp,                                  
 @stdBldQty = H.stdBldQty                                    
 FROM importBOMHeader H WHERE importId=@importId                                  
                                   
 -- 07/17/2019 Vijay G :Use class Default warehouse if it have value otherwise setup default                          
 --Get Default warehouse of class                          
 SELECT  @AssyUniqWh=Uniqwh                                
 FROM PartClass WHERE part_class = @AssyClass                           
                          
 --if it is empty then use setup default warehouse                          
 IF(RTRIM(LTRIM(@AssyUniqWh))='')                        
 BEGIN                           
     SELECT @AssyUniqWh=Uniqwh                                
     FROM Warehous WHERE Warehous.[Default]=1                           
 END                          
                          
 --02/20/14 YS get default warehouse                                 
 SELECT @defaultUniqWh=Uniqwh                            
 FROM Warehous WHERE Warehous.[Default]=1                                   
                                 
 DECLARE  @iTable importBom                                  
 DECLARE @tInventor tImportBomInventor                                  
                                    
 DECLARE @tAvlAll tImportBomAvl , @tAvl tImportBomAvl                            
 -- 05/07/2019 : Vijay G : Fix the BOM Import Issue string/binary Data Truncated for Partmfgr, mfgrpartno and matlType NVARCHAR(MAX)  
 -- 01/06/2021 : Sachin B : Add the location column for the import                             
 DECLARE @tAvlDynamic TABLE (rowid uniqueidentifier,avlRowId uniqueidentifier,uniq_key char(10),CustUniq char(10),partmfgr NVARCHAR(MAX),mfgr_pt_no NVARCHAR(MAX),
                             matlType NVARCHAR(MAX),bom bit,[load] bit,cust bit,class varchar(10),[validation] varchar(10),uniqmfgrhd char(10),UniqWh char(10),
							 comments varchar(30),preference varchar(5),location NVARCHAR(MAX))               
 DECLARE @tAntiAvl TABLE (Bomparent char(10),uniq_key char(10),partmfgr NVARCHAR(MAX),mfgr_pt_no NVARCHAR(MAX),uniqanti char(10))                                  
                                   
                                   
 -- will keep new records for consign and buy inventory                                     
 DECLARE @tConsgignInventor tImportBomInventor                                  
 DECLARE @tInternalInventor tImportBomInventor                           
                                     
 INSERT INTO @iTable                                  
 EXEC [dbo].[sp_getImportBOMItems] @importId                                  
 INSERT INTO @tInventor                                  
 EXEC [dbo].[sp_getImportBOMItems] @importId,1,'Inventor'                                  
                            
 -- 10/16/2018 Vijay G For Now I Just updated the uniq_key and i check why uniq_key is not populating it self I Also Change the positon of Code for update uniq_key                                
 -- 10/12/2018 Vijay G Update the uniq_key of table @tInternalInventor if part match with inventor table with part_no,revision,custpartno                                 
 -- 10/26/2018 Vijay G : Fix the Duplicate Inventor Issue no need for and condition AND i.CUSTPARTNO = t.CUSTPARTNO AND i.CUSTREV =t.CustRev and update custno                             
 --                      custno if CUSTPARTNO<>''                            
 --05/14/2020 Sachin B: Set the empty uniq_ky column  
 Update @tInventor set uniq_key =''   
 update @iTable set uniq_key =''                      
 UPDATE t SET t.uniq_key = i.UNIQ_KEY                              
 FROM @tInventor t                                 
 INNER JOIN INVENTOR i ON i.PART_NO =t.Part_no AND i.REVISION = t.Revision AND i.CUSTNO = ISNULL(t.CUSTNO,'')  --AND i.CUSTPARTNO = t.CUSTPARTNO AND i.CUSTREV =t.CustRev                            
                                
 ---- 10/16/2018 Vijay G Update the uniq_key of table @iTable if part match with inventor table with part_no,revision,custpartno                              
 UPDATE t SET t.uniq_key = i.UNIQ_KEY                              
                               
 FROM @iTable t                                 
 INNER JOIN INVENTOR i ON i.PART_NO =t.partno AND i.REVISION = t.rev AND i.CUSTNO = ISNULL(t.CUSTNO,'')  --AND i.CUSTPARTNO = t.CUSTPARTNO AND i.CUSTREV =t.crev                            
                               
 UPDATE @iTable SET custno =@custno WHERE CUSTPARTNO<>''                            
                   
 UPDATE @tInventor SET custno =@custno WHERE CUSTPARTNO<>''                            
                                             
 --05/16/13 YS need to mark record class red when AVL is red for that record                                  
 INSERT INTO @tAvlAll exec [dbo].ImportBomGetAvlToComplete @importId                                  
 -- Find Existsing AVLs and analyze                                  
 DECLARE @cAvl TABLE (rowid uniqueidentifier,uniq_key char(10),Custuniq char(10),mfgr_pt_no varchar(50),partmfgr varchar(100),                                  
      matlType varchar(20),uniqmfgrhd varchar(20),Part_sourc char(10),XlPartSource char(10),is_deleted bit, cust bit)                                  
                                   
                                   
 --05/29/13 YS update class red if VAL is red                                  
 UPDATE @iTable SET class='i05red' WHERE class<>'i05red' AND rowId IN (SELECT rowId from @tAvlAll where class='i05red')                                  
 UPDATE @tInventor SET class='i05red' WHERE class<>'i05red' AND rowId IN (SELECT rowId from @tAvlAll where class='i05red')                                   
 -- 05/29/13 YS remove class red                                        
 -- for now remove deleted records                                   
 -- 05/29/13 YS remove class red                                                      
 --10/13/14 YS removed invtmfhd table and replaced with 2 new tables                                  
                                  
 INSERT INTO @cAvl(rowid,uniq_key,Custuniq,mfgr_pt_no ,partmfgr,matlType,uniqmfgrhd,Part_sourc,XlPartSource,is_deleted,cust )                                   
 SELECT tI.RowId,i.UNIQ_KEY,ISNULL(ch.uniq_key,space(10)) as int_uniq,h.MFGR_PT_NO,h.PARTMFGR,h.MATLTYPE,l.UNIQMFGRHD,i.Part_sourc,ti.Part_sourc,                                  
  H.IS_DELETED ,ISNULL(Ch.cust,CAST(0 as bit))cust                                  
  --10/13/14 YS removed invtmfhd table and replaced with 2 new tables                                  
  --FROM INVENTOR i INNER JOIN INVTMFHD h ON i.uniq_key = h.uniq_key                                   
  FROM INVENTOR i                           
  INNER JOIN InvtMPNLink L ON i.uniq_key = l.uniq_key                                
  INNER JOIN MfgrMaster H ON l.mfgrMasterId=h.MfgrMasterId                                   
  INNER JOIN @tInventor tI ON ti.uniq_key=I.UNIQ_KEY   --- always find internal part, even if BOM ask for consign                                  
  LEFT OUTER JOIN                                   
   (                        
     SELECT CAST(1 as bit) AS cust,h1.MFGR_PT_NO, h1.PARTMFGR ,i.UNIQ_KEY,i.Int_uniq                                
     FROM INVENTOR i                                   
     --10/13/14 YS removed invtmfhd table and replaced with 2 new tables                                  
      --INNER JOIN INVTMFHD h1 ON i.uniq_key = h1.uniq_key,                                  
      INNER JOIN InvtMPNLink L ON i.uniq_key = l.uniq_key                                  
      INNER JOIN MfgrMaster h1 on l.mfgrMasterId=h1.MfgrMasterId,                                  
      @tInventor tI                                  
      WHERE i.INT_UNIQ=CASE WHEN @custno=' ' OR tI.CustPartNo =' ' THEN ' ' ELSE tI.uniq_key END                                  
      AND i.UNIQ_KEY = CASE WHEN @custno='' OR tI.CustPartNo =' '  THEN tI.uniq_key ELSE i.UNIQ_KEY END                                  
      AND i.CUSTNO = CASE WHEN @custno='' OR tI.CustPartNo =' '  THEN ' ' ELSE @custno END                                  
      and l.is_deleted = 0                            
   ) ch ON I.UNIQ_KEY = CASE WHEN @custno=' ' OR tI.CustPartNo =' ' THEN ch.UNIQ_KEY ELSE ch.INT_UNIQ end and H.PARTMFGR =ch.PARTMFGR and h.MFGR_PT_NO =ch.MFGR_PT_NO                                 
   WHERE l.IS_DELETED=0 and  tI.Class <>'i05red'                                      
                                     
 --05/29/13 YS move these 2 lines up to update class red if VAL is red                            
 --UPDATE @iTable SET class='i05red' WHERE class<>'i05red' AND rowId IN (SELECT rowId from @tAvlAll where class='i05red')                                  
 --UPDATE @tInventor SET class='i05red' WHERE class<>'i05red' AND rowId IN (SELECT rowId from @tAvlAll where class='i05red')                                                   
 UPDATE @tAvlAll SET UniqWH =W.UniqWh FROM 
 ( select rowId,fkFieldDefId,adjusted,ibd.fieldName,ibd.sourceFieldName,warehous.uniqwh                                    
   FROM importBOMFields ib 
   INNER JOIN importBOMFieldDefinitions ibd on ib.fkFieldDefId =ibd.fieldDefId                                   
   INNER JOIN warehous on adjusted =warehous.warehouse                                  
   WHERE ib.fkImportId =@ImportId and ibd.sourceTableName='Invtmfgr' and ibd.fieldName ='warehouse'
 ) W INNER JOIN @tAvlAll t ON W.rowid=t.rowid    
 
 -- 01/06/2021 : Sachin B : Add the location column for the import
 UPDATE @tAvlAll SET [location] = W.adjusted FROM 
 ( select rowId,fkFieldDefId,adjusted,ibd.fieldName,ibd.sourceFieldName                                 
   FROM importBOMFields ib 
   INNER JOIN importBOMFieldDefinitions ibd on ib.fkFieldDefId =ibd.fieldDefId                                                                      
   WHERE ib.fkImportId =@ImportId and ibd.sourceTableName='Invtmfgr' and ibd.fieldName ='location'
 ) W INNER JOIN @tAvlAll t ON W.rowid=t.rowid                               
                                   
 -- don't do that                           
 --update @tAvl set uniq_key =II.Uniq_key from (select i.Uniq_key from @tInternalInventor I inner join @tavl t on t.rowid=I.rowid) II                                  
 -- do this                                  
 update @tAvlALl set uniq_key =I.Uniq_key from @tInventor I INNER JOIN @tAVlAll t ON t.rowid=I.rowid                                  
                                   
 --05/29/13 YS remove red avls                                  
 -- 06/26/13 YS use new fnKeepAlphaNumeric() function that uses PATINDEX() to keep alpha-numeric charcaters only in place of fn_RemoveSpecialCharacters()                                  
 -- 05/15/2019 : Vijay G : Modify sp for add order prefernce for manufacture in invtmpnlink table as preference                            
 INSERT INTO @tAvlDynamic (rowid ,avlRowId,Uniq_key,CustUniq,partmfgr ,mfgr_pt_no ,matlType ,bom ,[load],cust ,class ,[validation] ,uniqmfgrhd ,comments,preference )                                 
 SELECT a.rowid,a.avlRowId,a.uniq_key,SPACE(10) as CustUniq, a.partmfgr,LEFT(RTRIM(a.mfgr_pt_no),30) as mfgr_pt_no,                                  
  a.matlType,a.bom,a.[load],CAST(c.cust as bit) cust, a.class, a.[validation],c.uniqmfgrhd,'newAVL',a.preference                                    
 FROM @tAvlAll a                                   
 LEFT OUTER JOIN @cAvl c ON a.Uniq_key= c.Uniq_key                                  
  AND a.partmfgr=c.partmfgr                                   
    --09/04/2018 vijay G Remove the Use of function fnKeepAlphaNumeric in And Condition for mfgr_pt_no                              
  AND a.mfgr_pt_no  =c.mfgr_pt_no                                
  --AND dbo.fnKeepAlphaNumeric(a.mfgr_pt_no)=dbo.fnKeepAlphaNumeric(c.mfgr_pt_no)                                 
 WHERE a.class<>'i05red' and c.mfgr_pt_no IS NULL                                  
 UNION ALL                                  
 --existing AVLs added to import row                                  
 SELECT a.rowID,a.avlRowId,a.uniq_key,c.CustUniq,a.partmfgr,LEFT(RTRIM(a.mfgr_pt_no),30) as mfgr_pt_no,                                  
  a.matlType,a.bom,cast(0 as bit) as [Load],isnull(c.cust,CAST(0 as bit))cust, a.class, a.[validation],c.uniqmfgrhd,'exist & connected',a.preference                                   
 FROM @tAvlAll a                                   
  INNER JOIN  @cAvl c  ON a.Uniq_key= c.Uniq_key                                   
  AND a.partmfgr=c.partmfgr                                   
    --09/04/2018 vijay G Remove the Use of function fnKeepAlphaNumeric in And Condition for mfgr_pt_no                              
  AND a.mfgr_pt_no  =c.mfgr_pt_no                                
  --AND dbo.fnKeepAlphaNumeric(a.mfgr_pt_no)=dbo.fnKeepAlphaNumeric(c.mfgr_pt_no)                                  
  WHERE a.class<>'i05red'                                  
 UNION ALL                                  
 --existing AVL not added to import row                                  
 -- Vijay G: 05/16/18: Set BOM value as 0 all AVL which are exist but not connected to the part.           
 SELECT c.rowid,NEWID(),c.Uniq_key,c.CustUniq,c.partmfgr,c.mfgr_pt_no,c.matlType,CAST(0 AS bit) as Bom,                                  
   CAST(0 AS bit) as [Load],ISNULL(c.cust,cast(0 as bit)) as cust,'i00grey' as class,'01system' as [vaildation],c.uniqmfgrhd,'exists not connected',a.preference                                   
 FROM @cAvl c                                   
  LEFT OUTER JOIN @tAvlAll a ON c.Uniq_key=a.Uniq_key                                  
   AND c.partmfgr=a.partmfgr                                   
   --09/04/2018 vijay G Remove the Use of function fnKeepAlphaNumeric in And Condition for mfgr_pt_no                              
  AND a.mfgr_pt_no  =c.mfgr_pt_no                                
--AND dbo.fnKeepAlphaNumeric(a.mfgr_pt_no)=dbo.fnKeepAlphaNumeric(c.mfgr_pt_no)                                  
   AND a.class <>'i05red'                                  
 WHERE a.partmfgr IS NULL                                  
 ORDER BY Rowid                                   
                               
 --- popultae new uiq_key for internal parts w/o uniq_key                                  
 INSERT INTO @tInternalInventor SELECT * FROM @tInventor WHERE uniq_key=' ' AND class<>'i05red'                                  
 -- for the new internal create consign if custpartno is not empty and custno is not empty                                   
 -- 12/05/17 YS Need to populate the same uniq_key if manual part_no and part_no/revision is the same. At least that will fix manual parts                                  
 --09/20/18 YS part number changed to 35 characters                           
 --02/27/2020 Vijay G :Removed code of part number setting              
 --if @AutoNumber=0                                  
 --BEGIN                                  
 -- declare @distinctparts table (uniq_key char(10),part_no char(35),revision char(8))                                  
                                    
 -- insert into @distinctparts (part_no,Revision)                                  
 --  select distinct part_no,Revision from @tInternalInventor                                  
             
 -- update @distinctparts set uniq_key =  dbo.fn_GenerateUniqueNumber()                                   
 -- ---test only                                  
 -- ---select * from @distinctparts                                  
                          
 -- UPDATE i                              
 --  set Uniq_key=newuniqkey.uniq_key,int_uniq=' ',part_sourc=CASE WHEN part_sourc='CONSG' THEN 'BUY' ELSE part_sourc END                               
 --  FROM @tInternalInventor i INNER JOIN @distinctparts as newuniqkey ON i.part_no=newuniqkey.Part_no                  
 --  INNER JOIN PartClass p ON p.part_class=i.Part_class                  
 --   AND  i.Revision=newuniqkey.Revision  AND p.numberGenerator='Auto'                          
                    
 --END --- if @AutoNumber=0                                  
 --ELSE ---- if @AutoNumber=0                                  
 --BEGIN                                  
 -- update @tInternalInventor set Uniq_key=dbo.fn_GenerateUniqueNumber(),int_uniq=' ',part_sourc=CASE WHEN part_sourc='CONSG' THEN 'BUY' ELSE part_sourc END                                   
 --END--- else if @AutoNumber=0                                 
                    
 --02/27/2020 Vijay G: Added block of code to genrating part number base part class number setup              
 DECLARE @distinctparts TABLE (uniq_key CHAR(10),part_no CHAR(35),revision CHAR(8))                                  
            
 INSERT INTO @distinctparts (part_no,Revision)                                  
 SELECT DISTINCT part_no,Revision FROM @tInternalInventor                                  
                                    
 UPDATE @distinctparts SET uniq_key =  dbo.fn_GenerateUniqueNumber()                       
                     
                  
 UPDATE  i                  
 set Uniq_key= CASE WHEN p.numberGenerator='Auto' THEN dbo.fn_GenerateUniqueNumber() ELSE newuniqkey.uniq_key END              
               ,int_uniq=' ',part_sourc=CASE WHEN part_sourc='CONSG' THEN 'BUY' ELSE part_sourc END                                 
 FROM @tInternalInventor i                    
 INNER JOIN @distinctparts as newuniqkey ON i.part_no=newuniqkey.Part_no AND  i.Revision=newuniqkey.Revision                    
 INNER JOIN PartClass p ON p.part_class=i.Part_class                         
                       
 -- populate part number if auto part number                                  
 -- 04/25/2018: Vijay G: To auto generate internal part with customer prefix check Customer has prefix and UseCustPfx must be set to true.                               
 --02/27/2020 Vijay G: Added block of code to genrating part number base part class number setup              
 DECLARE @part_sourc CHAR(10), @part_class CHAR(8),@part_type CHAR(8),@uniq_key CHAR(10),@part_no VARCHAR(15),@Prefix VARCHAR(20)='',                    
    @useCustPFX BIT, @custPFX VARCHAR(4)='',@classPFX VARCHAR(3) ,@numberGenrator VARCHAR(20) ,@partPrfix VARCHAR(19)=''                           
                             
 --04/30/18 YS moved the code to get customer prefix outside of the loop. Only one customer can be assigned to the upload                                  
 -- 04/25/2018: Vijay G: Get the customer prefix depending upon the customer associated with current imported bom.                                       
 SELECT @custPFX = ISNULL(CUSTPFX,'') FROM CUSTOMER WHERE CUSTNO =(SELECT CUSTNO FROM importBOMHeader WHERE importId=@importId)                            
                               
 DECLARE PartsCurosr CURSOR LOCAL FAST_FORWARD FOR                          
 -- 04/25/2018: Vijay G: Fetch UseCustPFX value                         
 --08/29/2019: Vijay G: Fetch those records where the Part_sourc='BUY'                                         
 --   SELECT Uniq_key,SUBSTRING(part_class,1,8),SUBSTRING(Part_type,1,8),SUBSTRING(part_sourc,1,10),UseCustPFX                    
 --   FROM @tInternalInventor  where Part_sourc='BUY'                                     
 --OPEN PartsCurosr;                         
    SELECT Uniq_key,SUBSTRING(part_class,1,8),SUBSTRING(Part_type,1,8),SUBSTRING(part_sourc,1,10),UseCustPFX                                  
 FROM @tInternalInventor                                    
 OPEN PartsCurosr;                       
 -- 04/25/2018: Vijay G: Fetch UseCustPFX value                                             
    FETCH NEXT FROM PartsCurosr INTO @uniq_key,@part_class,@part_type,@part_sourc,@useCustPFX;                                  
    WHILE @@FETCH_STATUS = 0                                     
 BEGIN                          
  --08/29/2019: Vijay G: Comment the code which not in use now                        
  --IF @part_sourc='MAKE' and @AutoMakeNo=0                                  
  -- BEGIN                                  
  -- -- do nothing                                  
  -- --05/30/13 need to fetch prior to continue otherwise will be infinite loop                                  
  -- -- 04/25/2018: Vijay G: Fetch UseCustPFX value                                  
  -- FETCH NEXT FROM MakePartsCurosr INTO @uniq_key,@part_class,@part_typeMk,@part_sourcMk,@useCustPFXMk;                                  
  -- CONTINUE                                  
  --END --IF @part_sourc='MAKE' and @AutoMakeNo=0                      
        SELECT @numberGenrator= numberGenerator FROM PartClass WHERE part_class=@part_class                       
  IF(@numberGenrator='Auto')                     
  BEGIN                    
   EXECUTE [GetNextInvtPartNo] @pcNextNumber = @part_no OUTPUT                      
                         
   -- find prefix if any                                  
   ----06/07/13 YS If no part type supplied @Prefix will get assigned NULL even though I had the code like that @Prefix=ISNULL(PartType.Prefix,'') (see commented code) must be because it was not null but empty?                                  
   --SELECT @Prefix=PartType.Prefix FROm PartType where PartType.part_class=@part_class and parttype.part_type=@part_type                                     
   --UPDATE @tInternalInventor set part_no=dbo.padr(RTRIM(ISNULL(@Prefix,'')) + RTRIM(@Part_No),25,' ') where uniq_key=@uniq_key                                  
   ----06/07/13 YS assign default value to @prefix as '' to avoid NULL values                  
   SET  @Prefix=''              
   SET @classPFX=''                
   IF(@part_type<>'' AND @part_type IS NOT NULL)                   
   BEGIN                      
    SELECT @Prefix=ISNULL(PartType.Prefix,'') FROM PartType WHERE PartType.part_class=@part_class and parttype.part_type=@part_type            
   END                  
   SELECT @classPFX= ISNULL(PartClass.classPrefix,'') FROM PartClass WHERE PartClass.part_class=@part_class               
   --04/15/2020 Sachin B:Update condition to for prefix fix       
   --04/17/2020 Sachin B: Added trim function And removed '-' from thenext of type prefix  
   SET @partPrfix=CASE WHEN (@classPFX<>'') AND ( @Prefix <>'' ) THEN LTRIM(RTRIM(@classPFX))+ LTRIM(RTRIM(@Prefix))       
        ELSE CASE WHEN ( @classPFX<>'') AND (@Prefix='' ) THEN  LTRIM(RTRIM(@classPFX))+'-'       
        ELSE CASE WHEN (@Prefix<>'' ) AND ( @classPFX='') THEN LTRIM(RTRIM(@Prefix))        
        ELSE '' END END END       
                                        
   -- 04/25/2018: Vijay G: Check if customer has prefix and usecustpfx value true then create new part with cust prefix, type prefix and last part no                                   
   --04/30/18 need a dash after @custPFX, prefix from parttype has dash included                         
   --08/29/2019: Vijay G: Update records where Part_sourc='BUY'                                    
   IF (@useCustPFX = 1 and @custPFX IS NOT NULL and @custPFX <> '' )                                  
   BEGIN                                  
    UPDATE @tInternalInventor SET part_no=dbo.padr(LTRIM(RTRIM(@custPFX))+'-' + LTRIM(RTRIM(@partPrfix)) + LTRIM(RTRIM(@Part_No)),35,'') WHERE uniq_key=@uniq_key               
   END                                  
   ELSE                                  
   BEGIN                                 
    UPDATE @tInternalInventor SET part_no=dbo.padr(LTRIM(RTRIM(@partPrfix)) + LTRIM(RTRIM(@Part_No)),35,'') WHERE uniq_key=@uniq_key                                  
   END     
  END                      
                       
  IF(@numberGenrator='ManualPrfx')                     
  BEGIN                    
   -- find prefix if any                                  
   ----06/07/13 YS If no part type supplied @Prefix will get assigned NULL even though I had the code like that @Prefix=ISNULL(PartType.Prefix,'') (see commented code) must be because it was not null but empty?                                  
   --SELECT @Prefix=PartType.Prefix FROm PartType where PartType.part_class=@part_class and parttype.part_type=@part_type                     
   --UPDATE @tInternalInventor set part_no=dbo.padr(RTRIM(ISNULL(@Prefix,'')) + RTRIM(@Part_No),25,' ') where uniq_key=@uniq_key                                  
   ----06/07/13 YS assign default value to @prefix as '' to avoid NULL values                    
   SET  @Prefix=''              
SET @classPFX=''                
   IF(@part_type<>'' AND @part_type IS NOT NULL)                   
   BEGIN                              
   SELECT @Prefix=ISNULL(PartType.Prefix,'') FROM PartType WHERE PartType.part_class=@part_class and parttype.part_type=@part_type               
   END                    
              
   SELECT @classPFX= ISNULL(PartClass.classPrefix,'') FROM PartClass WHERE PartClass.part_class=@part_class               
   --04/15/2020 Sachin B:Update condition to for prefix fix    
   --04/17/2020 Sachin B: Added trim function And removed '-' from thenext of type prefix    
   SET @partPrfix=CASE WHEN @classPFX<>'' AND @Prefix <>'' THEN LTRIM(RTRIM(@classPFX))+ LTRIM(RTRIM(@Prefix))       
       ELSE CASE WHEN ( @classPFX<>'') AND (@Prefix='' ) THEN  LTRIM(RTRIM(@classPFX))+'-'       
       ELSE CASE WHEN (@Prefix<>'' ) AND ( @classPFX='') THEN LTRIM(RTRIM(@Prefix))       
       ELSE '' END END END                                   
   -- 04/25/2018: Vijay G: Check if customer has prefix and usecustpfx value true then create new part with cust prefix, type prefix and last part no                                   
   --04/30/18 need a dash after @custPFX, prefix from parttype has dash included                         
   --08/29/2019: Vijay G: Update records where Part_sourc='BUY'                                    
   IF (@useCustPFX = 1 and @custPFX IS NOT NULL and @custPFX <> '' )                                  
   BEGIN                       
    UPDATE @tInternalInventor SET part_no=dbo.padr(LTRIM(RTRIM(@custPFX))+'-' + LTRIM(RTRIM(@partPrfix)) + LTRIM(RTRIM(part_no)),35,'') WHERE uniq_key=@uniq_key                               
   END                                  
   ELSE                                  
   BEGIN                                  
    UPDATE @tInternalInventor SET part_no=dbo.padr(LTRIM(RTRIM(@partPrfix)) + LTRIM(RTRIM(part_no)),35,'') WHERE uniq_key=@uniq_key                
   END                       
  END                
                
  IF(@numberGenrator='CustPNasIPN')                     
  BEGIN                                                         
   IF (@useCustPFX = 1 and @custPFX IS NOT NULL and @custPFX <> '' )                                  
   BEGIN                                  
    UPDATE @tInternalInventor SET part_no=dbo.padr(RTRIM(@custPFX)+'-' + RTRIM(CustPartNo),35,' ') WHERE uniq_key=@uniq_key                               
   END                                  
   ELSE                                  
   BEGIN                                  
    UPDATE @tInternalInventor SET part_no=dbo.padr(RTRIM(CustPartNo),35,' ') WHERE uniq_key=@uniq_key                
   END                       
  END                          
 -- 04/25/2018: Vijay G: Fetch UseCustPFX value                                          
    FETCH NEXT FROM PartsCurosr INTO @uniq_key,@part_class,@part_type,@part_sourc,@useCustPFX;                                  
    END -- WHILE @@FETCH_STATUS = 0                                  
 CLOSE PartsCurosr;                                  
 DEALLOCATE PartsCurosr;                                  
 -- IF @AutoNumber=1                         
                          
 --08/29/2019: Vijay G: Added new block with cursor to use auto numbering setting for partsource is in "MAKE,PHANTOM"                        
 --IF @AutoMakeNo =1                                
 --BEGIN                              
 --   SELECT @custPFX = ISNULL(CUSTPFX,'') FROM CUSTOMER WHERE CUSTNO =(SELECT CUSTNO FROM importBOMHeader WHERE importId=@importId)                                  
 --   DECLARE MakePartsCurosr CURSOR LOCAL FAST_FORWARD FOR                              
 --   SELECT Uniq_key,SUBSTRING(part_class,1,8),SUBSTRING(Part_type,1,8),SUBSTRING(part_sourc,1,10),UseCustPFX                                  
 --   FROM @tInternalInventor where Part_sourc IN('MAKE','PHANTOM')                            
 --OPEN MakePartsCurosr;                                  
                                   
 --   FETCH NEXT FROM MakePartsCurosr INTO @uniq_key,@part_class,@part_type,@part_sourc,@useCustPFX;                                  
 --WHILE @@FETCH_STATUS = 0                                  
 --BEGIN                                           
 -- EXECUTE [GetNextInvtPartNo] @pcNextNumber = @part_no OUTPUT                                   
 -- SELECT @Prefix=ISNULL(PartType.Prefix,'') FROM PartType WHERE PartType.part_class=@part_class and parttype.part_type=@part_type                                            
 -- IF (@useCustPFX = 1 and @custPFX IS NOT NULL and @custPFX <> '' )                                  
 -- BEGIN                                  
 --  UPDATE @tInternalInventor SET part_no=dbo.padr(RTRIM(@custPFX)+'-' + RTRIM(@Prefix) + RTRIM(@Part_No),35,' ')                         
 --         WHERE uniq_key=@uniq_key   and Part_sourc IN ('MAKE','PHANTOM')                                
 -- END                       
 -- ELSE                                  
 -- BEGIN                                  
 --  UPDATE @tInternalInventor SET part_no=dbo.padr(RTRIM(@Prefix) + RTRIM(@Part_No),35,' ')                         
 --         WHERE uniq_key=@uniq_key and Part_sourc IN ('MAKE','PHANTOM')                                  
 -- END                                           
 -- FETCH NEXT FROM MakePartsCurosr INTO @uniq_key,@part_class,@part_type,@part_sourc,@useCustPFX;                                  
 -- END -- WHILE @@FETCH_STATUS = 0                                  
 -- CLOSE MakePartsCurosr;                                  
 -- DEALLOCATE MakePartsCurosr;                                  
 --END  -- IF @@AutoMakeNo=1                                         
 -- generate consign parts if needed                                          
 -- check if custpartno entered           
 --05/21/13 YS check if empty or null or standard price custno when assigning from importBomHeader.                                   
 IF @custno<>' '                                  
 BEGIN                                  
  -- for the parts whith empty uiq-key and not empty custpartno generate consign part                                  
  --select * from @tInternalInventor                                  
  --12/06/17 YS make sure not to create second uniq_key from the same consign parts if the same internal part is added multiple times                                  
  -- 05/15/2019 : Vijay G : Modify sp for add tow check box as sid and serial part                          
  ;With                                  
  findFirstPart                                  
  as                                  
  (select ROW_NUMBER() over(partition by uniq_key order by rowid) as n ,* from @tInternalInventor)                                  
                                        
  INSERT INTO @tConsgignInventor (                                  
   [importId] ,                                  
   [rowId] ,            
   [uniq_key],                                  
   [class] ,                                  
   [validation] ,                                  
   [Custno] ,                                  
   [CustPartNo] ,                                  
   [CustRev] ,                                  
   [Descript],                                  
   [Int_uniq] ,                                  
   [Inv_note] ,                                  
   [make_buy] ,                                  
   [Part_class] ,                                  
   [Part_no] ,                                  
   [Part_sourc] ,                                  
   [Part_type] ,                                  
   [Revision] ,                                  
   [StdCost] ,                                  
   [U_of_meas] ,                             
   [Serialyes],                          
   [Useipkey]                              
   )                                  
                                     
   SELECT [importId] ,                                  
   [rowId] ,                                  
   [uniq_key],                                  
   [class] ,                                  
   [validation] ,                                  
   [Custno] ,                                  
   [CustPartNo] ,                                  
   [CustRev] ,                               
   [Descript],                                  
   [Int_uniq] ,                                  
   [Inv_note] ,                                  
   [make_buy] ,                                  
   [Part_class] ,                                  
   [Part_no] ,                                  
   [Part_sourc] ,                            
   [Part_type] ,                                  
   [Revision] ,                                  
   [StdCost] ,                                  
   [U_of_meas],                          
   [Serialyes],                          
   [Useipkey]                                  
   FROM findFirstPart WHERE custpartno<>' ' and n=1                                   
                                    
  -- now update int_uniq                                   
  UPDATE  @tConsgignInventor SET Int_uniq=Uniq_key,Uniq_key=dbo.fn_GenerateUniqueNumber() ,                                  
    custno=@custno ,part_sourc='CONSG'                                  
  --end  -- test remove later                                     
  -- 05/29/13 YS move this code outside of IF @custno<>' '                                  
  --update  @tInternalInventor SET Custpartno=' ', custrev=' ' where rowid IN (SELECT Rowid from @tConsgignInventor)                       
  --update @tInternalInventor set Custno=' ' where Custno is null                                  
                                    
  -- now find all that had part_no and uniq_key populated but custpartno+custrev is not exists                                  
  --SELECT * FROM @tInventor t WHERE uniq_key <>' ' and uniq_key+@custno NOT IN (SELECT int_uniq+custno from INVENTOR)                                  
  -- 11/11/13 Ds added @custno filter                                  
  DECLARE @AddConsign table (importid uniqueidentifier,rowid uniqueidentifier,uniq_key char(10),int_uniq char(10),part_sourc char(10),custno char(10))                                   
  --09/29/14 YS sometimes the same part is entered twice with a different work center. This will try to generate 2 identical consign parts for the same internal part                                  
  --- with different uniq_key. I will first identify the duplicate parts and update identical records with the same uniq_key                                  
  --INSERT INTO @AddConsign SELECT importid,rowid, dbo.fn_GenerateUniqueNumber() as Uniq_key,uniq_key as int_uniq, 'CONSG' as Part_sourc,@custno as Custno                                   
  --   FROM @tInventor t                                   
  --   WHERE uniq_key <>' ' and custPartno<>' ' and uniq_key+@custno NOT IN (SELECT int_uniq+custno from INVENTOR WHERE CUSTNO=@custno)                                  
  INSERT INTO @AddConsign SELECT importid,rowid, ' ' as uniq_key,uniq_key as int_uniq, 'CONSG' as Part_sourc,@custno as Custno                                   
   FROM @tInventor t                                   
   WHERE uniq_key <>' ' and custPartno<>' ' and uniq_key+@custno NOT IN (SELECT int_uniq+custno from INVENTOR WHERE CUSTNO=@custno)                                  
                          
  --select * from @AddConsign order by int_uniq                                  
  declare @UniqCustPart table (newuniqkey char(10),uniq_key char(10),custno char(10))                                  
  INSERT INTO @UniqCustPart                           
  SELECT dbo.fn_GenerateUniqueNumber() as newuniqkey,uniq_key,custno FROM                                  
  (SELECT distinct uniq_key,@custno as custno,custpartno,custrev                                   
   from @tInventor WHERE uniq_key <>' ' and custPartno<>' ' and uniq_key+@custno NOT IN (SELECT int_uniq+custno from INVENTOR WHERE CUSTNO=@custno)                                  
  ) D                                                     
  UPDATE @AddConsign set Uniq_key= u.newuniqkey from @UniqCustPart u INNER JOIN @AddConsign a ON u.uniq_key=a.int_uniq and u.custno=a.custno                                  
  --select * from @AddConsign order by int_uniq                                  
                                  
  INSERT INTO @tConsgignInventor               
  SELECT * FROM @tInventor t               
  WHERE uniq_key <>' ' and custPartno<>' ' and uniq_key+@custno NOT IN (SELECT int_uniq+custno from INVENTOR)                                  
  --select * from @tConsgignInventor                                  
  --end -- for test only remove            
                                   
  UPDATE @tConsgignInventor SET uniq_key= A.Uniq_key,Int_uniq = A.int_uniq,Part_sourc=A.Part_sourc,Custno=A.Custno                                   
  FROM @AddConsign A INNER JOIN @tConsgignInventor t ON  A.rowid=t.rowid                                  
  --  select * from @tConsgignInventor order by uniq_key                                  
 END --- NOT @custno IS NULL and @custno<>' '                                     
                          
 -- 10/26/2018 Vijay G :Delete consign parts from @tInternalInventor Table                            
 --DELETE from @tInternalInventor  where Custno<>''                            
                              
 -- 05/29/13 YS move this code outside of IF @custno<>' '                                  
 --06/10/13 ys remove all customer information from internal inventory records                                  
                                   
 UPDATE  @tInternalInventor SET Custpartno=' ', custrev=' ' ,Custno=' '                                  
                                   
 --update  @tInternalInventor SET Custpartno=' ', custrev=' ' where rowid IN (SELECT Rowid from @tConsgignInventor)                                  
 --update @tInternalInventor set Custno=' ' where Custno is null                                  
                                                       
 --- find new AVLs for new parts                                  
 UPDATE @tAvlDynamic SET PartMfgr='GENR' WHERE PartMFGR IS NULL                          
 UPDATE @tAvlDynamic SET UniqWH =W.UniqWh FROM
  (
        select rowId,fkFieldDefId,adjusted,ibd.fieldName,ibd.sourceFieldName,warehous.uniqwh                                  
        from importBOMFields ib
		inner join importBOMFieldDefinitions ibd on ib.fkFieldDefId =ibd.fieldDefId                                   
        inner join warehous on adjusted =warehous.warehouse                                  
        where ib.fkImportId =@ImportId and ibd.sourceTableName='Invtmfgr' AND ibd.fieldName='warehouse' 
  ) W INNER JOIN @tAvlDynamic t ON W.rowid=t.rowid                                  
  -- 01/06/2021 : Sachin B : Add the location column for the import
  UPDATE @tAvlDynamic SET [location] =W.adjusted FROM
  (
        select rowId,fkFieldDefId,adjusted,ibd.fieldName,ibd.sourceFieldName                                  
        from importBOMFields ib
		inner join importBOMFieldDefinitions ibd on ib.fkFieldDefId =ibd.fieldDefId                                                                        
        where ib.fkImportId =@ImportId and ibd.sourceTableName='Invtmfgr' AND ibd.fieldName='location' 
  ) W INNER JOIN @tAvlDynamic t ON W.rowid=t.rowid                                     
                               
 -- POPULATE @tAvl with the to Upload into invtmfgr for new Parts                                  
                                   
 --09/29/14 YS update uniqmfgrhd based on the unique combination of uniq_key,partmfgr,mfgr_pt_no                                  
                                  
 --INSERT INTO @tAvl (ImportId,RowId,AvlRowId,[Uniq_key],[UniqWh],MatlType,Mfgr_pt_no,PartMfgr,Uniqmfgrhd,Bom,[Load])                                   
 --  SELECT @importId,AD.RowId,AD.AvlRowId,tI.Uniq_key,AD.UniqWh,AD.MatlType,AD.Mfgr_pt_no,AD.PartMfgr,                                  
 --  dbo.fn_GenerateUniqueNumber() as Uniqmfgrhd,AD.Bom,AD.[Load]                                  
 --  FROM @tAvlDynamic AD INNER JOIN @tInternalInventor tI ON AD.rowid=tI.Rowid WHERE AD.[Load]=1 AND Ad.Class <> 'i05red'                                   
 -- 05/15/2019 : Vijay G : Modify sp for add order prefernce for manufacture in invtmpnlink table as preference
 -- 01/06/2021 : Sachin B : Add the location column for the import                            
 INSERT INTO @tAvl (ImportId,RowId,AvlRowId,[Uniq_key],[UniqWh],MatlType,Mfgr_pt_no,PartMfgr,Bom,[Load],preference,location)                                 
 SELECT @importId,AD.RowId,AD.AvlRowId,tI.Uniq_key,AD.UniqWh,AD.MatlType,AD.Mfgr_pt_no,AD.PartMfgr,                       
 AD.Bom,AD.[Load],AD.preference,location                                  
 FROM @tAvlDynamic AD                           
 INNER JOIN @tInternalInventor tI ON AD.rowid=tI.Rowid WHERE AD.[Load]=1 AND Ad.Class <> 'i05red'                                 
                           
 -- 05/07/2019 : Vijay G : Fix the BOM Import Issue string/binary Data Truncated for Partmfgr, mfgrpartno and matlType NVARCHAR(MAX)                                   
 DECLARE @tAvlDistinct Table (uniq_key char(10),partmfgr VARCHAR(MAX),mfgr_pt_no VARCHAR(MAX),uniqmfgrhd char(10))                                   
 INSERT INTO @tAvlDistinct (uniq_key ,partmfgr ,mfgr_pt_no ,uniqmfgrhd )                                  
 SELECT  uniq_key ,partmfgr ,mfgr_pt_no ,dbo.fn_GenerateUniqueNumber() as uniqmfgrhd                                  
 FROM 
 (
	SELECT distinct  uniq_key ,partmfgr ,mfgr_pt_no FROM @tAvl WHERE uniqmfgrhd =' ' or uniqmfgrhd IS NULL              
 ) D                
                                 
 UPDATE @tAvl SET UniqMfgrhd=d.uniqmfgrhd FROM @tAvlDistinct d 
 INNER JOIN @tavl t ON d.uniq_key=t.Uniq_key AND d.partmfgr=t.PartMfgr AND d.mfgr_pt_no=t.Mfgr_pt_no WHERE                                  
 t.UniqMfgrhd=' ' or t.uniqmfgrhd IS NULL                                  
 -- 09/29/14 YS clear @tAvlDistinct to use later                                  
 DELETE FROM @tAvlDistinct                                  
                                      
 --05/30/13 YS run this code first to get a list of the new avls before the next step adding new avls for the new consign parts                                   
 -- Add new AVl for existing parts                                  
 -- 09/29/14 YS do not update uniqmfgrhd untill unique values are selected                                  
 --INSERT INTO @tAvl (ImportId,RowId,AvlRowId,[Uniq_key],[UniqWh],MatlType,Mfgr_pt_no,PartMfgr,Uniqmfgrhd,Bom,[Load])                                   
 --  SELECT @importId,AD.RowId,AD.AvlRowId,tI.Uniq_key,AD.UniqWh,AD.MatlType,AD.Mfgr_pt_no,AD.PartMfgr,                                  
 --  dbo.fn_GenerateUniqueNumber() as Uniqmfgrhd,AD.Bom,AD.[Load]                                  
 --  FROM @tAvlDynamic AD INNER JOIN @tInventor tI ON AD.rowid=tI.Rowid                                   
 --  WHERE AD.[Load]=1                                   
 --  AND tI.Class <> 'i05red'                                   
 --  AND AD.Uniq_key=Ti.Uniq_key                                   
 --  and Ad.Uniq_key<>' '             
 --  and Ad.comments='newAVL'                                  
 -- 05/15/2019 : Vijay G : Modify sp for add order prefernce for manufacture in invtmpnlink table as preference                             
 INSERT INTO @tAvl (ImportId,RowId,AvlRowId,[Uniq_key],[UniqWh],MatlType,Mfgr_pt_no,PartMfgr,Bom,[Load],preference,location)                                 
 SELECT @importId,AD.RowId,AD.AvlRowId,tI.Uniq_key,AD.UniqWh,AD.MatlType,AD.Mfgr_pt_no,AD.PartMfgr,                                  
 AD.Bom,AD.[Load],AD.preference,location                                
 FROM @tAvlDynamic AD 
 INNER JOIN @tInventor tI ON AD.rowid=tI.Rowid                                   
 WHERE AD.[Load]=1                                   
 AND tI.Class <> 'i05red'                                   
 AND AD.Uniq_key=Ti.Uniq_key                                   
 and Ad.Uniq_key<>' '                                  
 and Ad.comments='newAVL'                                  
               
 INSERT INTO @tAvlDistinct (uniq_key ,partmfgr ,mfgr_pt_no ,uniqmfgrhd )                                  
 SELECT  uniq_key ,partmfgr ,mfgr_pt_no ,dbo.fn_GenerateUniqueNumber() as uniqmfgrhd                                  
  FROM                                  
   (SELECT distinct  uniq_key ,partmfgr ,mfgr_pt_no                                   
    from @tAvl where uniqmfgrhd =' ' or uniqmfgrhd is null                                   
   ) D                  
                                 
 UPDATE @tAvl SET UniqMfgrhd=d.uniqmfgrhd from @tAvlDistinct d inner join @tavl t on d.uniq_key=t.Uniq_key and d.partmfgr=t.PartMfgr and d.mfgr_pt_no=t.Mfgr_pt_no where                                  
 t.UniqMfgrhd=' ' or t.uniqmfgrhd is null                                  
 -- 09/29/14 YS clear @tAvlDistinct to use later                                  
 DELETE FROM @tAvlDistinct                                  
 -- add new avl for new consign parts only if BOM=1                                  
 -- 09/29/14 YS do not update uniqmfgrhd , find unique avl and then update                                  
 --INSERT INTO @tAvl (ImportId,RowId,AvlRowId,[Uniq_key],[UniqWh],MatlType,Mfgr_pt_no,PartMfgr,Uniqmfgrhd,Bom,[Load])                                  
 -- SELECT t.ImportId,t.RowId,t.AvlRowId,C.[Uniq_key],t.[UniqWh],t.MatlTYpe,t.[Mfgr_pt_no],t.[PartMfgr] ,dbo.fn_GenerateUniqueNumber() as Uniqmfgrhd,Bom,[Load]                                  
 -- FROM @tAvl t INNER JOIN @tConsgignInventor c ON t.rowid=c.rowid WHERE t.BOM=1                                  
 -- 05/15/2019 : Vijay G : Modify sp for add order prefernce for manufacture in invtmpnlink table as preference                              
 INSERT INTO @tAvl (ImportId,RowId,AvlRowId,[Uniq_key],[UniqWh],MatlType,Mfgr_pt_no,PartMfgr,Bom,[Load],preference,location)                                
 SELECT t.ImportId,t.RowId,t.AvlRowId,C.[Uniq_key],t.[UniqWh],t.MatlTYpe,t.[Mfgr_pt_no],t.[PartMfgr], Bom,[Load],t.preference,location                                    
 FROM @tAvl t                           
 INNER JOIN @tConsgignInventor c ON t.rowid=c.rowid WHERE t.BOM=1  
                               
 INSERT INTO @tAvlDistinct (uniq_key ,partmfgr ,mfgr_pt_no ,uniqmfgrhd )                                  
 SELECT  uniq_key ,partmfgr ,mfgr_pt_no ,dbo.fn_GenerateUniqueNumber() as uniqmfgrhd                                  
  FROM                                  
  (
    SELECT distinct  uniq_key ,partmfgr ,mfgr_pt_no                                   
    from @tAvl where uniqmfgrhd =' ' or uniqmfgrhd is null                                   
  ) D                
                                   
 UPDATE @tAvl SET UniqMfgrhd=d.uniqmfgrhd from @tAvlDistinct d inner join @tavl t on d.uniq_key=t.Uniq_key and d.partmfgr=t.PartMfgr and d.mfgr_pt_no=t.Mfgr_pt_no where                                  
 t.UniqMfgrhd=' ' or t.uniqmfgrhd is null                                  
 -- 09/29/14 YS clear @tAvlDistinct to use later                                  
 DELETE FROM @tAvlDistinct                                  
                                  
 -- 05/30/13 YS AVLs that existed for the existing internal part will say load=0 and will not load to the consign part w/o this code                                   
 --09/29/14 YS do not update uniqmfgrhd . find unique avl and then update                                  
 --INSERT INTO @tAvl (ImportId,RowId,AvlRowId,[Uniq_key],[UniqWh],MatlType,Mfgr_pt_no,PartMfgr,Uniqmfgrhd,Bom,[Load])                                  
 -- SELECT c.ImportId,t.RowId,t.AvlRowId,C.[Uniq_key],t.[UniqWh],t.MatlTYpe,t.[Mfgr_pt_no],t.[PartMfgr] ,dbo.fn_GenerateUniqueNumber() as Uniqmfgrhd,Bom,[Load]                                  
 -- FROM @tAvlDynamic t INNER JOIN @tConsgignInventor c ON t.rowid=c.rowid                                   
 -- WHERE t.BOM=1                                    
 -- AND t.Uniq_key<>' ' and t.Uniq_key=c.int_uniq                                  
 -- AND t.Class <> 'i05red'                                  
 -- and t.comments='exist & connected'                                  
 -- 05/15/2019 : Vijay G : Modify sp for add order prefernce for manufacture in invtmpnlink table as preference                            
 INSERT INTO @tAvl (ImportId,RowId,AvlRowId,[Uniq_key],[UniqWh],MatlType,Mfgr_pt_no,PartMfgr,Bom,[Load],preference,location)                                
 SELECT c.ImportId,t.RowId,t.AvlRowId,C.[Uniq_key],t.[UniqWh],t.MatlTYpe,t.[Mfgr_pt_no],t.[PartMfgr] ,Bom,[Load],preference,location                                  
 FROM @tAvlDynamic t 
 INNER JOIN @tConsgignInventor c ON t.rowid=c.rowid                                   
 WHERE t.BOM=1                                    
 AND t.Uniq_key<>' ' and t.Uniq_key=c.int_uniq                                  
 AND t.Class <> 'i05red'                    
 AND t.comments='exist & connected'                                  
                                    
 INSERT INTO @tAvlDistinct (uniq_key ,partmfgr ,mfgr_pt_no ,uniqmfgrhd )                                  
 SELECT  uniq_key ,partmfgr ,mfgr_pt_no ,dbo.fn_GenerateUniqueNumber() as uniqmfgrhd                                  
  FROM                                  
   (SELECT distinct  uniq_key ,partmfgr ,mfgr_pt_no                                   
    from @tAvl where uniqmfgrhd =' ' or uniqmfgrhd is null                                   
   ) D                  
                                 
 UPDATE @tAvl SET UniqMfgrhd=d.uniqmfgrhd from @tAvlDistinct d inner join @tavl t on d.uniq_key=t.Uniq_key and d.partmfgr=t.PartMfgr and d.mfgr_pt_no=t.Mfgr_pt_no where                                  
 t.UniqMfgrhd=' ' or t.uniqmfgrhd is null                                  
 -- 09/29/14 YS clear @tAvlDistinct to use later                                  
 DELETE FROM @tAvlDistinct                                  
                                   
                                   
 -- 09/29/14 YS do not update uniqmfgrhd , first find unique avl                                  
 -- check if need to add to a customer part, which is already in the system, if not exists should have been created by @tConsgignInventor                                  
 --INSERT INTO @tAvl (ImportId,RowId,AvlRowId,[Uniq_key],[UniqWh],MatlType,Mfgr_pt_no,PartMfgr,Uniqmfgrhd,Bom,[Load])                                   
 --  SELECT @importId,AD.RowId,AD.AvlRowId,C.Uniq_key,AD.UniqWh,AD.MatlType,AD.Mfgr_pt_no,AD.PartMfgr,                                  
 --  dbo.fn_GenerateUniqueNumber() as Uniqmfgrhd,AD.Bom,AD.[Load]                                  
 --  FROM @tAvlDynamic AD INNER JOIN @tInventor tI ON AD.rowid=tI.Rowid                                   
 --  INNER JOIN Inventor C ON C.INT_UNIQ=AD.Uniq_key and C.Custno=@Custno                                  
 --  WHERE AD.BOM=1                                  
 --  AND tI.Class <> 'i05red'                                   
 --  AND AD.Uniq_key=Ti.Uniq_key                                   
 --  and Ad.Uniq_key<>' '                                  
 --  AND (Ad.comments='newAVL' or Ad.comments='exist & connected')                                  
 --  AND  NOT EXISTS (SELECT Uniq_key,PartMfgr,Mfgr_pt_no FROM Invtmfhd WHERE c.Uniq_key=Invtmfhd.Uniq_key AND AD.PartMfgr=Invtmfhd.PartMfgr and AD.Mfgr_pt_no=Invtmfhd.Mfgr_pt_no)                                  
 --10/13/14 YS removed invtmfhd table and replaced with 2 new tables                                   
                                   
 -- 12/08/16 YS fix the problem found by paramit , where if existsing part has avl like 'test1' and uploaded part has avl listed as 'test-1' the system will properly identify the existsing avl,                                   
 ---but will load new avl 'test-1' onto existing consign part. Here we need to use                                   
 --- dbo.fnKeepAlphaNumeric(AD.Mfgr_pt_no)=dbo.fnKeepAlphaNumeric(m.Mfgr_pt_no))                                   
 --- 08/20/18 YS if consign part exists but it is new avl for it, need to make sure to check when generating antiavl records for the existing BOM                                   
 --- attached to the consignparts                                  
 DECLARE @tConsignExistsAvlAdded table ( importId uniqueidentifier,RowId uniqueidentifier,AvlRowId uniqueidentifier,custUniq_key char(10),                                  
 uniq_key char(10),UniqWh char(10),MatlType char(10),Mfgr_pt_no char(30),PartMfgr char(30),                                  
   Bom bit,[Load] bit,location NVARCHAR(MAX) NULL)                                  
 --08/21/18 YS fix use new invtmplink and mfgrmaster tables                                  
 INSERT INTO @tConsignExistsAvlAdded                                  
 SELECT @importId,AD.RowId,AD.AvlRowId,C.Uniq_key,ad.uniq_key,AD.UniqWh,AD.MatlType,AD.Mfgr_pt_no,AD.PartMfgr,                                  
   AD.Bom,AD.[Load],AD.location                                  
   FROM @tAvlDynamic AD 
   INNER JOIN @tInventor tI ON AD.rowid=tI.Rowid                                   
   INNER JOIN Inventor C ON C.INT_UNIQ=AD.Uniq_key and C.Custno=@Custno                                  
   WHERE AD.BOM=1                                  
   AND tI.Class <> 'i05red'                                   
   AND AD.Uniq_key=Ti.Uniq_key                                   
   and Ad.Uniq_key<>' '                                  
   AND (Ad.comments='newAVL' or Ad.comments='exist & connected')                                  
   AND  NOT EXISTS                           
   (                          
		SELECT Uniq_key,PartMfgr,Mfgr_pt_no                                 
		FROM InvtMPNLink L 
		inner join MfgrMAster M on l.MfgrMasterId=m.MfgrMasterId                                   
		WHERE c.Uniq_key=L.Uniq_key                                   
		AND AD.PartMfgr=M.PartMfgr                
		--and AD.Mfgr_pt_no=Invtmfhd.Mfgr_pt_no                                  
		and dbo.fnKeepAlphaNumeric(AD.Mfgr_pt_no)=dbo.fnKeepAlphaNumeric(M.Mfgr_pt_no)                                  
    )                                  
                                   
 -- 05/15/2019 : Vijay G : Modify sp for add order prefernce for manufacture in invtmpnlink table as preference  
 -- 01/06/2021 : Sachin B : Add the location column for the import                           
 INSERT INTO @tAvl (ImportId,RowId,AvlRowId,[Uniq_key],[UniqWh],MatlType,Mfgr_pt_no,PartMfgr,Bom,[Load],preference,location)                                 
 SELECT @importId,AD.RowId,AD.AvlRowId,C.Uniq_key,AD.UniqWh,AD.MatlType,AD.Mfgr_pt_no,AD.PartMfgr,                                  
 AD.Bom,AD.[Load],AD.preference,location                                 
 FROM @tAvlDynamic AD                          
 INNER JOIN @tInventor tI ON AD.rowid=tI.Rowid                                 
 INNER JOIN Inventor C ON C.INT_UNIQ=AD.Uniq_key and C.Custno=@Custno                                  
 WHERE AD.BOM=1 AND tI.Class <> 'i05red' AND AD.Uniq_key=Ti.Uniq_key                                   
 and Ad.Uniq_key<>' ' AND (Ad.comments='newAVL' or Ad.comments='exist & connected')                                  
 AND  NOT EXISTS (                          
  SELECT Uniq_key,PartMfgr,Mfgr_pt_no                                 
  --10/13/14 YS removed invtmfhd table and replaced with 2 new tables                                  
  --FROM Invtmfhd WHERE c.Uniq_key=Invtmfhd.Uniq_key AND AD.PartMfgr=Invtmfhd.PartMfgr and AD.Mfgr_pt_no=Invtmfhd.Mfgr_pt_no)                                  
  FROM InvtMPNLink L                           
  INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId                                 
  WHERE c.Uniq_key=l.Uniq_key AND AD.PartMfgr=m.PartMfgr                                   
  --and AD.Mfgr_pt_no=m.Mfgr_pt_no                                  
  and dbo.fnKeepAlphaNumeric(AD.Mfgr_pt_no)=dbo.fnKeepAlphaNumeric(m.Mfgr_pt_no))                                  
                                   
                                  
 INSERT INTO @tAvlDistinct (uniq_key ,partmfgr ,mfgr_pt_no ,uniqmfgrhd )                                  
                                   
 SELECT  uniq_key ,partmfgr ,mfgr_pt_no ,dbo.fn_GenerateUniqueNumber() as uniqmfgrhd                                  
 FROM                                  
  (SELECT distinct  uniq_key ,partmfgr ,mfgr_pt_no                                   
  from @tAvl where uniqmfgrhd =' ' or uniqmfgrhd is null                                   
  ) D                   
               
 UPDATE @tAvl SET UniqMfgrhd=d.uniqmfgrhd 
 from @tAvlDistinct d 
 inner join @tavl t on d.uniq_key=t.Uniq_key and d.partmfgr=t.PartMfgr and d.mfgr_pt_no=t.Mfgr_pt_no where                                  
 t.UniqMfgrhd=' ' or t.uniqmfgrhd is null                                  
 -- 09/29/14 YS clear @tAvlDistinct to use later         delete from @tAvlDistinct                                      
                                   
 -- !!!uncomment when ready to update inventory                                  
                                   
 -- 05/16/2013 YS attempt to make sure that the values are not longer than the structure allows                                  
 DECLARE @tStructureI Table (ColumnName varchar(50),Max_length int)                                  
 -- get only inventory fields that are used in the upload                                  
 DECLARE @FieldNameI varchar(max)                                  
                                   
 SELECT @FieldNameI ='[Uniq_key]'+              
 (SELECT  ',[' +  F.sourceFieldName  + ']'                                  
  FROM importBOMFieldDefinitions F                                    
  WHERE sourceTableName='Inventor'                                
  ORDER BY F.sourceFieldName                                   
  FOR XML PATH(''))                 
                                 
 INSERT INTO @tStructureI SELECT sc.NAME AS columnName, sc.max_length from sys.columns sc where sc.object_id=object_id('inventor') and CHARINDEX(sc.name,@FieldNameI)<>0                                  
                                   
 --Will use @tStructureI to check the max_length                                                     
 --05/15/2013 Added status for the items                                  
 BEGIN TRANSACTION                                  
                                   
 -- 05/23/13 YS remove Bom_note, it is Item_note for Bom_det table and check for null in the inv_note      
 -- populate fields from parttype                                  
                                   
 -- 06/05/13 YS popultae default from parttype. !!! Need better way to check if already populated in the import fields                                  
 -- 06/12/13 YS update BOm_STATUS and BomCustNo if component is  a "make" part                                    
 --- 12/09/13 add uom restriction                                  
 -- 07/31/15 Raviraj Added UseSetScrp and StdBldQty for the Assembly, insert the values in Inventor table                                  
 BEGIN TRY                                  
 --09/29/14 YS added distinct                                  
 -- 03/06/15 YS added make_buy                                   
 -- 05/15/2019 : Vijay G : Modify sp for add tow check box as sid and serial part                                  
 INSERT INTO Inventor ([Uniq_key],[Custno],[CustPartNo],[CustRev],[Descript],[Int_uniq],[Inv_note],[Part_class],[Part_no],                                  
   [Part_sourc],[Part_type],[Revision],[StdCost],[U_of_meas],ImportId,[Status],[Bom_Status],BomCustNo                                  
   ,[ORD_POLICY]                                 
   ,[PACKAGE]                                  
   ,[BUYER_TYPE]                           
   ,[REORDPOINT]                                  
   ,[MINORD]                                  
   ,[ORDMULT]                                  
   ,[ABC]                                  
   ,[REORDERQTY]                                  
   ,[INSP_REQ]                                  
   ,[CERT_REQ]                                  
   ,[CERT_TYPE]                                  
   ,[SCRAP]                                  
   ,[SETUPSCRAP]                                  
   ,[LOC_TYPE]                     
   ,[PUR_LTIME]                                  
   ,[PUR_LUNIT]                                  
   ,[KIT_LTIME]                                  
   ,[KIT_LUNIT]                                  
   ,[PROD_LTIME]                                  
   ,[PROD_LUNIT]             
   ,[PULL_IN]                                  
   ,[PUSH_OUT]                                  
   ,[DAY]                                  
   ,[DAYOFMO]                                  
   ,[DAYOFMO2]                                  
   ,[MATL_COST]                                  
   ,[LABORCOST]                                  
   ,[OTHER_COST]                                  
   ,[OVERHEAD]                                  
   ,[MRC]                                  
   ,[OTHERCOST2]                                  
   ,[TARGETPRICE]                                  
   ,[PUR_UOFM]                                  
   ,[make_buy]                            
   ,useipkey                          
   ,[SERIALYES]                           
   -- 05/07/2019 : Vijay G : LastChangInit Not Populated for the Newly Added Part                          
   ,LASTCHANGEINIT                          
   -- 05/13/2019 : Vijay G : LASTCHANGEUSERID Not Populated for the Newly Added Part                          
   ,LASTCHANGEUSERID                    
   -- 02/14/2020 Nitesh B : Insert AspnetBuyer from PartClass table if PartClass having default buyer                    
   ,AspnetBuyer)                                  
   SELECT DISTINCT [Uniq_key],rtrim([Custno]),SUBSTRING(rtrim([CustPartNo]),1,CP.CustP_length),                                  
   SUBSTRING(rtrim([CustRev]),1,CR.CustR_length),SUBSTRING(rtrim([Descript]),1,DS.Descr_length),                                  
   rtrim([Int_uniq]),ISNULL([Inv_note],' '),rtrim(I.[Part_class]),                                  
   SUBSTRING(rtrim([Part_no]),1,PN.PartMax_Length),                        
   rtrim([Part_sourc]),rtrim(I.[Part_type]),                                  
   SUBSTRING(rtrim([Revision]),1,PR.PartRev_length),                                  
   CASE WHEN ISNUMERIC(I.StdCost)=1 THEN cast(I.[StdCost] as numeric(13,5))      
    ELSE ISNULL(P.STDCOST ,cast(0.00 as numeric(13,5))) END as StdCost,                                  
   SUBSTRING(CASE WHEN I.[U_OF_MEAS]<>'' THEN  RTRIM(I.[U_OF_MEAS]) ELSE ISNULL(P.U_OF_MEAS,CAST('' as CHAR(4))) END,1,UOM.UOM_length) as U_OF_MEAS,                                  
   @importID,'Active',CASE WHEN I.Part_sourc='MAKE' THEN 'Active' ELSE ' ' END as BOM_STATUS,@Custno as BOMCUSTNO,                                  
   ISNULL(P.[ORD_POLICY],CAST('' as CHAR(12))) as ORD_POLICY,                                  
   '' as Package,  --ISNULL([PACKAGE],CAST('' as CHAR(15))) as Package,    -- 02/19/2020 Rajendra K : Insert Blank value into Package Column of Inventor table                 
   ISNULL([BUYER_TYPE],CAST('' as CHAR(3))) as Buyer_type,                                  
   ISNULL([REORDPOINT],CAST(0 as numeric(7))) as [REORDPOINT],                                  
   ISNULL([MINORD],CAST(0 as numeric(7))) as [MINORD],                                  
   ISNULL([ORDMULT],CAST(0 as numeric(7,0))) as [ORDMULT],                                  
   ISNULL([ABC],CAST('' as CHAR(1))) as [ABC],                                   
   ISNULL([REORDERQTY],CAST(0 as numeric(7,0))) as  [REORDERQTY],                                  
   ISNULL([INSP_REQ],CAST(0 as bit)) as  [INSP_REQ],                                  
   ISNULL([CERT_REQ],CAST(0 as bit)) as  [CERT_REQ],                                  
   ISNULL([CERT_TYPE],CAST('' as CHAR(10))) as [CERT_TYPE],                                  
   ISNULL([SCRAP],CAST(0 as numeric(6,2))) as [SCRAP],                                   
   ISNULL([SETUPSCRAP],CAST(0 as numeric(4,0))) as  [SETUPSCRAP],                                  
   ISNULL([LOC_TYPE],CAST('' as CHAR(10))) as [LOC_TYPE],                                   
   ISNULL([PUR_LTIME],CAST(0 as numeric(3,0))) as  [PUR_LTIME],                                   
   ISNULL([PUR_LUNIT],CAST('' as CHAR(2))) as [PUR_LUNIT],                                  
   ISNULL([KIT_LTIME],CAST(0 as numeric(3,0))) as  [KIT_LTIME],                                  
   ISNULL([KIT_LUNIT],CAST('' as CHAR(2))) as [KIT_LUNIT],             
   ISNULL([PROD_LTIME],CAST(0 as numeric(3,0))) as [PROD_LTIME],                                  
   ISNULL([PROD_LUNIT],CAST('' as CHAR(2))) as [PROD_LUNIT],                                  
   ISNULL([PULL_IN],CAST(0 as numeric(3,0))) as [PULL_IN],                                  
   ISNULL([PUSH_OUT],CAST(0 as numeric(3,0))) as [PUSH_OUT],                                  
   ISNULL([DAY],CAST(0 as numeric(1))) as [DAY],                                   
   ISNULL([DAYOFMO],CAST(0 as numeric(2))) as [DAYOFMO],                                   
   ISNULL([DAYOFMO2],CAST(0 as numeric(2))) as [DAYOFMO2],                                  
   --ISNULL([MATL_COST],CAST(0 as numeric(13,5))) as [MATL_COST],        --- 10/03/16 YS save stdcost if provided as material cost                                  
   CASE WHEN ISNUMERIC(I.StdCost)=1 THEN cast(I.StdCost as numeric(13,5))                                   
    ELSE ISNULL(P.[MATL_COST] ,cast(0.00 as numeric(13,5))) END as [MATL_COST],                                  
   ISNULL([LABORCOST],CAST(0 as numeric(13,5))) as [LABORCOST],                                  
   ISNULL([OTHER_COST],CAST(0 as numeric(13,5))) as [OTHER_COST],                                  
      ISNULL([OVERHEAD],CAST(0 as numeric(13,5))) as [OVERHEAD],                                  
   ISNULL([MRC],CAST('' as CHAR(15))) as [MRC],                                  
   ISNULL([OTHERCOST2],CAST(0 as numeric(13,5))) as [OTHERCOST2],                                  
   ISNULL([TARGETPRICE],CAST(0 as numeric(13,5))) as [TARGETPRICE],                                  
   SUBSTRING(CASE WHEN I.U_of_meas =P.PUR_UOFM OR P.PUR_UOFM ='' THEN I.U_of_meas                                   
   WHEN CU.[FROM] IS NULL THEN I.U_of_meas ELSE p.PUR_UOFM END,1,UOM.UOM_length) as PUR_UOFM  ,           
   -- 01/25/2019 : Vijay G : Fix the Issue MAKE_BUY Column Inserted with Null Value while Creating Make Part                                  
   CASE WHEN PART_SOURC<>'MAKE' THEN 0                            
   WHEN PART_SOURC ='MAKE' AND I.Make_buy IS NULL THEN 0                            
   ELSE I.Make_buy END As make_buy,                            
   -- 10/30/2018 Vijay G : insert the Value for useipkey from the match found in the PartClass Table for the Added new Assembly and Components                            
   -- 05/15/2019 : Vijay G : modify sp for insert  sid value into inventor if sid is check comment this line 'ISNULL(class.useIpKey,CAST(0 as BIT))'                          
    ISNULL(i.Useipkey,CAST(0 as BIT)),                          
   --ISNULL(class.useIpKey,CAST(0 as BIT)),                          
   ISNULL(SERIALYES,CAST(0 as BIT)),                            
   @userInit,                          
   @userId,                    
   ISNULL(class.aspnetBuyer, '00000000-0000-0000-0000-000000000000') AS AspnetBuyer  -- 02/14/2020 Nitesh B : Insert AspnetBuyer from PartClass table if PartClass having default buyer                                  
   FROM @tInternalInventor I                             
   LEFT OUTER JOIN PartType P on I.Part_class= P.PART_CLASS AND I.Part_type=P.PART_TYPE                            
   INNER JOIN PartClass class on I.Part_class= class.PART_CLASS                                    
 OUTER APPLY ( SELECT Unit.[FROM] ,Unit.[To] FROM Unit WHERE (Unit.[From]=p.PUR_UOFM and Unit.[To]=I.U_OF_MEAS) OR (Unit.[From]=I.U_OF_MEAS and Unit.[To]=p.PUR_UOFM)) CU                                   
 CROSS APPLY (SELECT Max_Length as PartMax_length from @tStructureI where columnname='Part_no') PN                                   
 CROSS APPLY (SELECT Max_Length as PartRev_length from @tStructureI where columnname='Revision') PR                                 
 CROSS APPLY (SELECT Max_Length as CustP_length from @tStructureI where columnname='Custpartno') CP                                  
 CROSS APPLY (SELECT Max_Length as CustR_length from @tStructureI where columnname='CustRev') CR                                  
 CROSS APPLY (SELECT Max_Length as Descr_length from @tStructureI where columnname='Descript') DS                                  
 --- 12/09/13 add uom restriction                                  
 CROSS APPLY (SELECT Max_Length as UOM_length from @tStructureI where ColumnName='U_OF_MEAS') UOM                                  
 END TRY                                  
 BEGIN CATCH                                   
 -- 12/09/13 YS check fr errors prior to proceeding                                  
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
  ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
  ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                 
  IF @@TRANCOUNT>0                                  
   ROLLBACK TRANSACTION                                   
   -- 12/10/13 YS inser into importBOMErrors                                  
   --12/06/17 YS change error handling to use variable                                  
   INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
   SELECT DISTINCT @importId,@ERRORNUMBER                                  
   ,@ERRORSEVERITY                                   
   ,@ERRORPROCEDURE                                  
   ,@ERRORLINE                                   
   ,@ERRORMESSAGE                                   
   ,GETDATE()                                  
   return -1                                                      
 END CATCH                                  
                       
 --05/29/13 YS need to update importBomFields with the uniq_key                                  
 BEGIN TRY                                  
  UPDATE importBomFields                                   
  SET Uniq_key=N.Uniq_key                        
  FROM @tInternalInventor N                                   
  WHERE N.importId=importBOMFields.fkImportId and N.RowId=ImportBomFields.RowId                                  
                                    
  DECLARE @partid UNIQUEIDENTIFIER,@revid UNIQUEIDENTIFIER                                  
  SELECT @partid=F.FieldDefId FROM importBOMFieldDefinitions F WHERE SourceFieldName='Part_no'                                  
  SELECT @revid=F.FieldDefId FROM importBOMFieldDefinitions F WHERE SourceFieldName='Revision'                                  
  UPDATE importBomFields                                   
   SET adjusted=N.Part_no                                   
   FROM @tInternalInventor N                                   
   WHERE N.importId=importBOMFields.fkImportId and N.RowId=ImportBomFields.RowId and FkFieldDefId=@partid                                  
               
  UPDATE importBomFields                                   
   SET adjusted=N.Revision                                   
   FROM @tInternalInventor N                                   
   WHERE N.importId=importBOMFields.fkImportId and N.RowId=ImportBomFields.RowId and FkFieldDefId=@revid                                  
 END TRY                                  
 BEGIN CATCH                                   
  -- 12/09/13 YS check fr errors prior to proceeding                                  
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
  ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
  ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
  IF @@TRANCOUNT>0                                  
   ROLLBACK TRANSACTION                                   
   -- 12/10/13 YS inser into importBOMErrors                                  
   --12/06/17 YS change error handling to use variable                                  
   INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
   SELECT DISTINCT @importId,@ERRORNUMBER                                  
   ,@ERRORSEVERITY                                   
   ,@ERRORPROCEDURE                                  
   ,@ERRORLINE                                   
   ,@ERRORMESSAGE                       
   ,GETDATE()                                  
   return -1                                                     
 END CATCH                                  
                                   
 ---- consign                           
 -- fort test display data                                   
 --select * from @tConsgignInventor                                  
 --05/15/2013 Added status for the items                                  
 --03/06/15 YS added make_buy                                  
 BEGIN TRY                                  
 INSERT INTO Inventor ([Uniq_key],[Custno],[CustPartNo],[CustRev],[Descript],[Int_uniq],[Inv_note],[Part_class],[Part_no],                                  
    [Part_sourc],[Part_type],[Revision],[StdCost],[U_of_meas],ImportId,[Status]                                  
    ,[ORD_POLICY]                                  
    ,[PACKAGE]                                  
    ,[BUYER_TYPE]                                  
    ,[REORDPOINT]                                  
    ,[MINORD]                                  
    ,[ORDMULT]                                  
    ,[ABC]                                  
    ,[REORDERQTY]                                  
    ,[INSP_REQ]                                  
    ,[CERT_REQ]                                  
    ,[CERT_TYPE]                                  
    ,[SCRAP]                                  
    ,[SETUPSCRAP]                                  
    ,[LOC_TYPE]                                  
    ,[PUR_LTIME]                                  
    ,[PUR_LUNIT]                                  
    ,[KIT_LTIME]                                  
    ,[KIT_LUNIT]                                  
    ,[PROD_LTIME]                                  
    ,[PROD_LUNIT]                      
    ,[PULL_IN]                                  
    ,[PUSH_OUT]                                  
    ,[DAY]                                  
    ,[DAYOFMO]                                  
    ,[DAYOFMO2]                                  
    ,[MATL_COST]                                  
    ,[LABORCOST]                                  
    ,[OTHER_COST]                                  
    ,[OVERHEAD]                                  
    ,[MRC]                                  
    ,[OTHERCOST2]                                  
    ,[TARGETPRICE]                          
    ,[PUR_UOFM]                                  
    ,[MAKE_BUY]                            
   ,useipkey                          
   ,SERIALYES                          
 -- 05/07/2019 : Vijay G : LastChangInit Not Populated for the Newly Added Part                          
 ,LASTCHANGEINIT                          
 -- 05/13/2019 : Vijay G : LASTCHANGEUSERID Not Populated for the Newly Added Part                          
   ,LASTCHANGEUSERID                    
   -- 02/14/2020 Nitesh B : Insert AspnetBuyer from PartClass table if PartClass having default buyer                    
   ,AspnetBuyer)                                  
  SELECT DISTINCT [Uniq_key],rtrim([Custno]),SUBSTRING(rtrim([CustPartNo]),1,CP.CustP_length),                                  
    SUBSTRING(rtrim([CustRev]),1,CR.CustR_length),SUBSTRING(rtrim([Descript]),1,DS.Descr_length),                                  
    rtrim([Int_uniq]),ISNULL([Inv_note],' '),rtrim(C.[Part_class]),                                  
    SUBSTRING(rtrim([Part_no]),1,PN.PartMax_Length),                                  
  rtrim([Part_sourc]),rtrim(C.[Part_type]),                                  
    SUBSTRING(rtrim([Revision]),1,PR.PartRev_length),                                  
    --12/09/16 YS consign parts will have 0 standard cost                                  
    --CASE WHEN ISNUMERIC(C.StdCost)=1 THEN cast(C.[StdCost] as numeric(13,5))                                   
    --ELSE ISNULL(P.STDCOST ,cast(0.00 as numeric(13,5))) END as StdCost,                                  
    cast(0.00 as numeric(13,5)) as StdCost,                                         
  SUBSTRING(CASE WHEN C.[U_OF_MEAS]<>'' THEN  RTRIM(C.[U_OF_MEAS]) ELSE ISNULL(P.U_OF_MEAS,CAST('' as CHAR(4))) END,1,UOM.UOM_length) as U_OF_MEAS,                                      
    @ImportId ,'Active',                                  
    ISNULL(P.[ORD_POLICY],CAST('' as CHAR(12))) as ORD_POLICY,                                  
     '' as Package,  --ISNULL([PACKAGE],CAST('' as CHAR(15))) as Package,    -- 02/19/2020 Rajendra K : Insert Blank value into Package Column of Inventor table                     
    ISNULL([BUYER_TYPE],CAST('' as CHAR(3))) as Buyer_type,                                  
    ISNULL([REORDPOINT],CAST(0 as numeric(7))) as [REORDPOINT],                                  
    ISNULL([MINORD],CAST(0 as numeric(7))) as [MINORD],                                  
    ISNULL([ORDMULT],CAST(0 as numeric(7,0))) as [ORDMULT],                                  
    ISNULL([ABC],CAST('' as CHAR(1))) as [ABC],                    
    ISNULL([REORDERQTY],CAST(0 as numeric(7,0))) as  [REORDERQTY],                                  
    ISNULL([INSP_REQ],CAST(0 as bit)) as  [INSP_REQ],                                  
    ISNULL([CERT_REQ],CAST(0 as bit)) as  [CERT_REQ],                                  
    ISNULL([CERT_TYPE],CAST('' as CHAR(10))) as [CERT_TYPE],                                  
    ISNULL([SCRAP],CAST(0 as numeric(6,2))) as [SCRAP],                                   
    ISNULL([SETUPSCRAP],CAST(0 as numeric(4,0))) as  [SETUPSCRAP],                                  
    ISNULL([LOC_TYPE],CAST('' as CHAR(10))) as [LOC_TYPE],                                   
    ISNULL([PUR_LTIME],CAST(0 as numeric(3,0))) as  [PUR_LTIME],                                   
    ISNULL([PUR_LUNIT],CAST('' as CHAR(2))) as [PUR_LUNIT],                                  
    ISNULL([KIT_LTIME],CAST(0 as numeric(3,0))) as  [KIT_LTIME],                                  
    ISNULL([KIT_LUNIT],CAST('' as CHAR(2))) as [KIT_LUNIT],                        
    ISNULL([PROD_LTIME],CAST(0 as numeric(3,0))) as [PROD_LTIME],                                  
    ISNULL([PROD_LUNIT],CAST('' as CHAR(2))) as [PROD_LUNIT],                                  
    ISNULL([PULL_IN],CAST(0 as numeric(3,0))) as [PULL_IN],                                  
    ISNULL([PUSH_OUT],CAST(0 as numeric(3,0))) as [PUSH_OUT],                                  
    ISNULL([DAY],CAST(0 as numeric(1))) as [DAY],                                   
    ISNULL([DAYOFMO],CAST(0 as numeric(2))) as [DAYOFMO],                                   
    ISNULL([DAYOFMO2],CAST(0 as numeric(2))) as [DAYOFMO2],                                  
    --12/09/16 YS consign parts will have 0  cost                                  
    CAST(0 as numeric(13,5)) as [MATL_COST],                                   
    CAST(0 as numeric(13,5)) as [LABORCOST],                                  
    CAST(0 as numeric(13,5)) as [OTHER_COST],                                  
    CAST(0 as numeric(13,5)) as [OVERHEAD],                                  
    ISNULL([MRC],CAST('' as CHAR(15))) as [MRC],                                  
    CAST(0 as numeric(13,5)) as [OTHERCOST2],                                  
    CAST(0 as numeric(13,5)) as [TARGETPRICE],                                  
    SUBSTRING(CASE WHEN C.U_of_meas =P.PUR_UOFM OR P.PUR_UOFM ='' THEN C.U_of_meas                                   
    WHEN CU.[FROM] IS NULL THEN C.U_of_meas ELSE p.PUR_UOFM END,1,UOM.UOM_length) as PUR_UOFM  ,                                  
    0 AS MAKE_BUY,                            
  -- 10/30/2018 Vijay G : insert the Value for useipkey from the match found in the PartClass Table for the Added new Assembly and Components                            
  -- 05/15/2019 : Vijay G : modify sp for insert  sid value into inventor                           
  -- 05/15/2019 : Vijay G : modify sp for insert  sid value into inventor if sid is check comment this line 'ISNULL(class.useIpKey,CAST(0 as BIT))'                          
  --ISNULL(class.useIpKey,CAST(0 as BIT))                            
  ISNULL(C.Useipkey,CAST(0 as BIT)),                            
  ISNULL(C.Serialyes,CAST(0 as BIT)),                           
  @userInit ,                          
  @userId,                    
  ISNULL(class.aspnetBuyer, '00000000-0000-0000-0000-000000000000') AS AspnetBuyer  -- 02/14/2020 Nitesh B : Insert AspnetBuyer from PartClass table if PartClass having default buyer                                   
  FROM @tConsgignInventor C                             
  LEFT OUTER JOIN PartType P on C.Part_class= P.PART_CLASS AND C.Part_type=P.PART_TYPE                             
  INNER JOIN PartClass class on C.Part_class= class.PART_CLASS                                   
  OUTER APPLY ( SELECT Unit.[FROM] ,Unit.[To] FROM Unit WHERE (Unit.[From]=p.PUR_UOFM and Unit.[To]=C.U_OF_MEAS) OR (Unit.[From]=C.U_OF_MEAS and Unit.[To]=p.PUR_UOFM)) CU                                   
  CROSS APPLY (SELECT Max_Length as PartMax_length from @tStructureI where columnname='Part_no') PN                                   
  CROSS APPLY (SELECT Max_Length as PartRev_length from @tStructureI where columnname='Revision') PR                                  
  CROSS APPLY (SELECT Max_Length as CustP_length from @tStructureI where columnname='Custpartno') CP             
  CROSS APPLY (SELECT Max_Length as CustR_length from @tStructureI where columnname='CustRev') CR                                  
  CROSS APPLY (SELECT Max_Length as Descr_length from @tStructureI where columnname='Descript') DS                                  
  --- 12/09/13 add uom restriction                                  
  CROSS APPLY (SELECT Max_Length as UOM_length from @tStructureI where ColumnName='U_OF_MEAS') UOM                                  
 END TRY                                  
 -- 12/09/13 YS check fr errors prior to proceeding                                  
 BEGIN CATCH                                   
  -- 12/09/13 YS check fr errors prior to proceeding                                  
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
  ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
  ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
  IF @@TRANCOUNT>0                                  
  ROLLBACK TRANSACTION                                   
  -- 12/10/13 YS inser into importBOMErrors                                  
  --12/06/17 YS change error handling to use variable                                  
  INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
  SELECT DISTINCT @importId,@ERRORNUMBER                                  
  ,@ERRORSEVERITY                                   
  ,@ERRORPROCEDURE                                  
  ,@ERRORLINE                
  ,@ERRORMESSAGE                                   
  ,GETDATE()                                  
  return -1                                                     
 END CATCH                                  
 ---11/10/15 YS update inv_note from upload file if entered                                  
 -- 03/04/18: Vijay G: Update the part status and bom_status if InActive then set as Active                                  
 BEGIN TRY                                  
  UPDATE Inventor SET Inv_note=CASE WHEN T.inv_note is not NULL and T.inv_note<>'' THEN t.inv_note else inventor.inv_note end,                                  
        [Status]= CASE WHEN [Status] ='InActive' THEN 'Active' ELSE [Status] END,                                   
  [Bom_Status]=CASE WHEN [Status] ='InActive' THEN 'Active' ELSE [Bom_Status] END                                   
  FROM @tInventor t                                   
  WHERE t.Uniq_key<>' '                                   
  AND Inventor.uniq_key=t.Uniq_key                                                   
 END TRY                                   
 BEGIN CATCH                                   
  -- 12/09/13 YS check fr errors prior to proceeding                                  
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
  ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
  ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
  IF @@TRANCOUNT>0                                  
  ROLLBACK TRANSACTION                                   
  -- 12/10/13 YS inser into importBOMErrors                                  
  --12/06/17 YS change error handling to use variable                
  INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
  SELECT DISTINCT @importId,@ERRORNUMBER                                  
  ,@ERRORSEVERITY                                 
  ,@ERRORPROCEDURE                                  
  ,@ERRORLINE                                   
  ,@ERRORMESSAGE                      
  ,GETDATE()                                  
  return -1                                  
 END CATCH                                  
                                   
 -- end 11/10/15 YS                                  
 -- 05/26/13 YS added code to check if a consign part for @custno exists but the custpartno is different than provided                                  
 -- we decided that we will overwrite the custpartno and custrev with the new information                                  
 -- user should see the worning in the front end of the app                                  
 --SELECT * FROM @tInventor                                  
 BEGIN TRY                                  
 UPDATE Inventor SET CustPartno=left(N.CustPartNo,25),CustRev=N.CustRev ,                                  
   --11/10/15 update inv_note from the uploaded file if any                                  
   inv_note=CASE WHEN N.inv_note is not NULL and N.inv_note<>'' THEN N.inv_note else inventor.inv_note end                                  
   FROM @tInventor N                                   
   WHERE N.Uniq_key<>' ' and N.custPartno<>' ' and @custNo<>' '                                   
   AND Inventor.Int_uniq=N.Uniq_key and Inventor.Custno=@Custno                                  
   AND Inventor.Part_sourc='CONSG' and (Inventor.CustPartNo<>N.CustPartNo OR Inventor.CustRev<>N.CustRev)                                  
 END TRY                                    
 BEGIN CATCH           -- 12/09/13 YS check fr errors prior to proceeding                                  
   SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
   ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
   ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
   ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
   ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
   IF @@TRANCOUNT>0                                  
    ROLLBACK TRANSACTION                                   
    -- 12/10/13 YS inser into importBOMErrors                    
    --12/06/17 YS change error handling to use variable                                  
    INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
    SELECT DISTINCT @importId,@ERRORNUMBER                                  
    ,@ERRORSEVERITY                                   
    ,@ERRORPROCEDURE                                  
    ,@ERRORLINE                                   
    ,@ERRORMESSAGE                                   
    ,GETDATE()                                  
    return -1           
  END CATCH                                  
                                   
 ---!!! Need to update autolocation if parttype table for the class/type allow to have it on auto Prefer to add the field maybe into the importBomFieldDefrinitions                                   
 BEGIN TRY                                  
  --09/29/4 YS select distinct from @tavl                                  
  --10/13/14 YS removed invtmfhd table and replaced with 2 new tables                                  
  -- 06/01/16 YS update autolocation based on parttype table                                  
  DECLARE @KeyUpdated TABLE (Uniq_key char(10),Mfgrmasterid bigint,Uniqmfgrhd char(10))                                   
  -- 10/13/14 added new table variable to save new Mfgrmasterid                                  
  -- find all new PartMfgr/MPN and Insert into MfgrMaster                                  
  -- Update deleted flag if found the match                                  
  -- Insert reocrds into @MfgrmasterKey to get new and existsing MfgrMasterId                                  
  -- 05/15/2019 : Vijay G : modify sp for cast part mfgr to accept only 8 character                              
  DECLARE @MfgrmasterKey TABLE (PartMfgr char(8),Mfgr_pt_no char(30),MfgrMasterId bigint)                                   
  MERGE MfgrMaster T                                  
  USING (SELECT Distinct SUBSTRING(Mfgr_pt_no,1,30) as mfgr_pt_no,CAST(rtrim(PartMfgr) as char(8)) as PartMfgr,                                  
      CAST(rtrim(ISNULL(MatlType,'Unk')) as char(10)) as MatlType FROM @tAvl) as S                                  
  ON (s.PartMfgr=T.PartMfgr AND S.Mfgr_pt_no=T.Mfgr_pt_no)                                  
  WHEN MATCHED  THEN UPDATE SET T.is_deleted=0                                  
  WHEN NOT MATCHED BY TARGET THEN                                   
  INSERT (Partmfgr,mfgr_pt_no,MatlType) VALUES (CAST(rtrim(S.PartMfgr) as char(8)),S.mfgr_pt_no,S.MatlType)                                
  OUTPUT CAST(rtrim(Inserted.PartMfgr) as char(8)),Inserted.mfgr_pt_no,Inserted.MfgrmasterId into @MfgrmasterKey;                                
                                  
                                   
  -- 10/13/14 YS replace invtmfhd with Invtmpnlink and mfgrmaster                                  
               
  MERGE InvtmpnLink As T                                  
   USING                          (                          
   SELECT distinct t.Uniq_key,M.Mfgr_pt_no,M.PartMfgr,t.Uniqmfgrhd,m.mfgrmasterid,t.preference                                  
   FROM @tAvl T                           
   INNER JOIN @MfgrmasterKey M                  
   ON m.partmfgr=CAST(rtrim(t.PartMfgr) as char(8)) and m.mfgr_pt_no=SUBSTRING(t.Mfgr_pt_no,1,30)                          
   ) as S ON (S.Uniq_key=T.Uniq_key AND S.mfgrmasterid=T.mfgrmasterid )                                
   WHEN MATCHED THEN UPDATE SET T.IS_DELETED=0                                  
   WHEN NOT MATCHED BY TARGET THEN                           
   -- 06/06/2019 Vijay G: Insert default 99 if Prefrence value is null for the prviously added templates                                  
   INSERT ([Uniq_key],mfgrmasterid,Uniqmfgrhd,orderpref) VALUES (S.Uniq_key,S.MfgrMasterId,S.UniqMfgrhd,ISNULL(preference,'99'))                                 
   OUTPUT Inserted.Uniq_key,Inserted.MfgrMasterId,Inserted.UniqMfgrhd into @KeyUpdated;                                  
                                     
   -- 06/01/16 YS update autolocation based on parttype table                                   
   UPDATE MfgrMaster SET Autolocation = ISNULL(p.autolocation,0) from inventor I inner join                                   
   @KeyUpdated K on i.uniq_key=k.Uniq_key                
   inner join parttype p on i.part_class=p.part_class and i.part_type=p.Part_type                                  
   where k.mfgrmasterid=MfgrMaster.mfgrmasterid                                  
                                   
                                   
  -- update uniqmfgrhd in @tavl                                  
  --10/14/14 YS use @MfgrmasterKey to join                                  
   UPDATE @tAVl SET Uniqmfgrhd=k.UniqMfgrhd                                   
   FROM @KeyUpdated K 
   INNER JOIN @MfgrmasterKey M ON K.Mfgrmasterid=M.MfgrMasterId                                  
   INNER JOIN  @tAVl T ON K.Uniq_key=T.Uniq_key AND M.PartMfgr=T.PartMfgr AND M.Mfgr_pt_no=T.Mfgr_pt_no                                     
  --02/17/14 YS check if no avl was uploaded for the new part create generic avl                                  
  -- 02/19/14 YS use @tInternalInventor                                  
  --10/14/14 YS remove Invtmfhd and replace with Invtmpnlink                                  
  --10/14/14 YS added mfgrMasterid to @GenrAvl                                  
  DECLARE @GenrAvl TABLE (Uniq_key char(10),Uniqmfgrhd char(10),MfgrMasterId bigint)                                   
  declare @GenrMaster TABLE (PartMfgr char(8),mfgr_pt_no char(30),MfgrMasterId bigint)                                   
  --10/14/14 YS create table variable to keep missingAvl                                  
  -- 05/15/2019 : Vijay G : Modify sp for add order prefernce for manufacture in invtmpnlink table as preference                            
  DECLARE @MissingAvl TABLE (Uniq_key char(10),preference char(5))                
                            
  INSERT INTO @MissingAvl (Uniq_key,preference)                                
  --;WITH                                  
  --MissingAvl                                  
  --as(                                  
    SELECT distinct  TI.Uniq_key,AD.preference                           
   FROM @tInternalInventor TI                                  
    Inner join @tAvlDynamic AD  ON AD.rowid=TI.Rowid WHERE AD.[Load]=1 AND Ad.Class <> 'i05red'                                  
   -- 10/14/14 YS use not exists                                  
    AND NOT EXISTS (SELECT 1 from @tAvl TA WHERE TA.Uniq_key=TI.uniq_key)                                
   --10/14/14 YS remove Invtmfhd and replace with Invtmpnlink                                  
   --and uniq_key not in (SELECT uniq_key FROM INVTMFHD)                                   
   -- 10/14/14 YS use not exists                                  
    AND NOT EXISTS (SELECT 1 FROM Invtmpnlink L WHERE l.uniq_key=TI.uniq_key)                                 
  UNION                                   
   SELECT distinct TC.Uniq_key,AD.preference                           
  FROM @tConsgignInventor TC                       
   Inner join @tAvlDynamic AD  ON AD.rowid=TC.Rowid WHERE AD.[Load]=1 AND Ad.Class <> 'i05red'                                   
   -- 10/14/14 YS use not exists               
    AND NOT EXISTS (SELECT 1 from @tAvl TA WHERE TA.Uniq_key=TC.uniq_key)                                
   --10/14/14 YS remove Invtmfhd and replace with Invtmpnlink                                  
   --and uniq_key not in (SELECT uniq_key FROM INVTMFHD)                                   
   -- 10/14/14 YS use not exists                                   
    AND NOT EXISTS (SELECT 1 FROM Invtmpnlink L WHERE L.uniq_key=TC.uniq_key)                                 
                                   
  --)                                  
  --02/20/14 YS use OUTPUT INTO to get information about missing avls and use it to add default location                                  
  --10/14/14 YS removed Invtmfhd table and replaced with 2 new tables                                  
  --10/14/14 YS first check if mfgrMaster table has record for the 'GENR' with empty mfgr_pt_no                                  
                                  
  MERGE MfgrMaster T                                  
  USING (SELECT 'GENR' as PartMfgr, SPACE(30) as Mfgr_pt_no)  as S                                  
  ON (s.PartMfgr=T.PartMfgr AND S.Mfgr_pt_no=T.Mfgr_pt_no)                                  
  WHEN MATCHED  THEN UPDATE SET T.is_deleted=0                                  
  WHEN NOT MATCHED BY TARGET THEN                                   
   -- 05/15/2019 : Vijay G : modify sp for cast part mfgr to accept only 8 character                              
  INSERT (Partmfgr,mfgr_pt_no,MatlType) VALUES (CAST(rtrim(S.PartMfgr) as char(8)),S.mfgr_pt_no,'Unk')                                
  OUTPUT CAST(rtrim(Inserted.PartMfgr) as char(8)),Inserted.mfgr_pt_no,Inserted.MfgrmasterId into @GenrMaster;                                
                                    
  -- 10/14/14 YS Now update or insert into Invtmpnlink                                  
                                    
  -- 05/15/2019 : Vijay G : Modify sp for add order prefernce for manufacture in invtmpnlink table as preference                              
  INSERT INTO INVTMPNLINK ([Uniq_key],Uniqmfgrhd,mfgrMasterId,orderpref)                                 
  OUTPUT Inserted.Uniq_key,Inserted.Uniqmfgrhd,Inserted.mfgrMasterId INTO @GenrAvl                          
  -- 06/06/2019 Vijay G: Insert default 99 if Prefrence value is null for the prviously added templates                                    
  Select ma.Uniq_key,dbo.fn_GenerateUniqueNumber() as UniqMfgrHd,m.MfgrMasterId,ISNULL(MA.preference,'99')                                
  FROM @MissingAvl MA outer apply @GenrMaster M                                   
                                   
  -- 06/01/16 YS update autolocation based on parttype table                                   
  UPDATE MfgrMaster SET Autolocation = ISNULL(p.autolocation,0) from inventor I inner join                                   
   @GenrAvl K on i.uniq_key=k.Uniq_key                              
  inner join parttype p on i.part_class=p.part_class and i.part_type=p.Part_type                                  
  where k.MfgrMasterId=MfgrMaster.MfgrMasterId                                  
                                   
  -- 02/20/14 YS add default location to added GENR avl                                  
  INSERT INTO Invtmfgr ([Uniq_key],Uniqmfgrhd,Uniqwh,W_key,NETABLE)                                   
  SELECT Uniq_key,UniqMfgrhd,@defaultUniqWh,dbo.fn_GenerateUniqueNumber(),1                                  
       FROM @GenrAvl                          
                                   
  -- 12/04/2019 Vijay G Added default MGFR "GENR" if user not added any mfgr with component                       
  DECLARE @UniqKeys TABLE(Uniq_Key varchar(10))                      
  DEClare @tun_KEy VARCHAR(10)                      
  INSERT INTO @UniqKeys                      
  SELECT UNIQ_KEY FROM @tInternalInventor                                 
  WHILE EXISTS(SELECT 1 FROM @UniqKeys)                      
  BEGIN                       
    SELECT TOP 1 @tun_KEy =  Uniq_Key FROM @UniqKeys                      
    IF NOT EXISTS(SELECT * FROM @MissingAvl) AND NOT EXISTS(SELECT 1 FROM InvtMPNLink WHERE uniq_key=@tun_KEy)                       
    BEGIN                      
   delete FROM @GenrAvl                      
   INSERT INTO InvtMPNLink([Uniq_key],Uniqmfgrhd,mfgrMasterId,orderpref)                      
   OUTPUT Inserted.Uniq_key,Inserted.Uniqmfgrhd,Inserted.mfgrMasterId INTO @GenrAvl                       
   SELECT @tun_KEy,dbo.fn_GenerateUniqueNumber() as UniqMfgrHd,m.MfgrMasterId,99                      
   FROM @GenrMaster M                      
                                     
   UPDATE MfgrMaster SET Autolocation = ISNULL(p.autolocation,0) from inventor I inner join                                   
   @GenrAvl K on i.uniq_key=k.Uniq_key                                  
   inner join parttype p on i.part_class=p.part_class and i.part_type=p.Part_type                                  
   where k.MfgrMasterId=MfgrMaster.MfgrMasterId                                  
                                     
   INSERT INTO Invtmfgr ([Uniq_key],Uniqmfgrhd,Uniqwh,W_key,NETABLE)                                   
   SELECT Uniq_key,UniqMfgrhd,@defaultUniqWh,dbo.fn_GenerateUniqueNumber(),1                                  
   FROM @GenrAvl                        
   END                      
   DELETE FROM @UniqKeys WHERE uniq_key=@tun_KEy                      
  END              
 END TRY                                                   
 BEGIN CATCH                                   
  -- 12/09/13 YS check fr errors prior to proceeding                                  
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                 
  ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
  ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
  IF @@TRANCOUNT>0                                  
   ROLLBACK TRANSACTION                                   
   -- 12/10/13 YS inser into importBOMErrors                                  
   --12/06/17 YS change error handling to use variable                                  
   INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)           
   SELECT DISTINCT @importId,@ERRORNUMBER                                  
   ,@ERRORSEVERITY                                   
   ,@ERRORPROCEDURE                                  
   ,@ERRORLINE                                   
   ,@ERRORMESSAGE                                   
   ,GETDATE()                                  
   return -1                              
 END CATCH                                  
                                   
 -- use merge again in case some of the records are there but removed                                  
 BEGIN TRY                                  
  ---09/29/14 YS select distinct first prior to creating w_key                                  
  DECLARE @KeyW TABLE (Uniq_key char(10),Uniqmfgrhd char(10),UniqWH char(10),W_key char(10))                
  --MERGE InvtMfgr As T                                  
  -- USING (SELECT Uniq_key,Uniqmfgrhd,UniqWh,dbo.fn_GenerateUniqueNumber() as W_key,CAST(1 as bit) Netable FROM @tAvl) as S                                  
  -- ON (S.Uniq_key=T.Uniq_key AND S.Uniqmfgrhd=T.UniqMfgrhd )                                  
  -- WHEN MATCHED THEN UPDATE SET T.IS_DELETED=0,T.Netable=1                                  
  -- WHEN NOT MATCHED BY TARGET THEN                                   
  -- INSERT ([Uniq_key],Uniqmfgrhd,UniqWh,W_key,Netable) VALUES (S.Uniq_key,S.Uniqmfgrhd,S.UniqWh,S.W_key,S.Netable) ;                                  
  -- 01/06/2021 : Sachin B : Add the location column for the import                                
  MERGE InvtMfgr As T                                  
   USING (SELECT distinct Uniq_key,Uniqmfgrhd,UniqWh,CAST(1 as bit) Netable,location FROM @tAvl) as S                                  
   ON (S.Uniq_key=T.Uniq_key AND S.Uniqmfgrhd=T.UniqMfgrhd )                                  
   WHEN MATCHED THEN UPDATE SET T.IS_DELETED=0,T.Netable=1                                  
   WHEN NOT MATCHED BY TARGET THEN                                   
   INSERT ([Uniq_key],Uniqmfgrhd,UniqWh,W_key,Netable,location) VALUES (S.Uniq_key,S.Uniqmfgrhd,S.UniqWh,dbo.fn_GenerateUniqueNumber(),S.Netable,ISNULL(location,'')) ;                                  
 END TRY                                                       
 BEGIN CATCH                                   
  -- 12/09/13 YS check fr errors prior to proceeding                                  
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
  ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
  ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                      
  IF @@TRANCOUNT>0                                  
  ROLLBACK TRANSACTION                                   
  -- 12/10/13 YS inser into importBOMErrors                                  
  --12/06/17 YS change error handling to use variable                                  
  INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
  SELECT DISTINCT @importId,@ERRORNUMBER                      
  ,@ERRORSEVERITY                                   
  ,@ERRORPROCEDURE                                  
  ,@ERRORLINE                                   
  ,@ERRORMESSAGE                                   
  ,GETDATE()                                  
  return -1                             
 END CATCH                                  
                                   
 -- create new record for assy if it is a new assy                                  
 -- 06/06/13 YS check if part is already exists                                  
                                   
 IF @AssyUniqKey=' '                                   
 BEGIN                                   
  -- check if part exists                                  
  SELECT @AssyUniqKey = Inventor.UNIQ_KEY from INVENTOR where PART_NO=@AssyNum and REVISION=@AssyRev and CUSTNO=' '                                  
  IF @AssyUniqKey<>' '                                  
  BEGIN                                  
  -- part exists                                  
  -- 06/12/13 YS overwrite bomcustno                                  
  BEGIN TRY                                  
   --08/11/15 YS overwrite USESETSCRP and STDBLDQTY only if @stdbldqty<>0, otherwise use the existsing settings                                   
   UPDATE Inventor SET @importid=@importId,                                   
       USESETSCRP =  CASE WHEN @useSetUp=1 THEN @useSetUp ELSE  USESETSCRP END,                                   
       STDBLDQTY = CASE WHEN @stdBldQty<>0 THEN @stdBldQty ELSE STDBLDQTY END ,                                  
       [Status]= 'Active',[Bom_Status]='Active',BomCustno=CASE WHEN @custno='' THEN BomCustno ELSE @Custno END                                   
       where UNIQ_KEY=@AssyUniqKey                              
                              
   -- 11/29/18 Vijay G Update Assembly cust no if assembly don't have components                            
   IF NOT EXISTS(SELECT 1 FROM BOM_DET WHERE BOMPARENT = @AssyUniqKey)                            
   BEGIN                            
        UPDATE Inventor SET  BOMCUSTNO = @custno WHERE UNIQ_KEY=@AssyUniqKey                                                 
   END                                  
                                  
  END TRY                                  
  BEGIN CATCH                                   
   -- 12/09/13 YS check fr errors prior to proceeding                                  
   SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
   ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
   ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
   ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
   ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
   IF @@TRANCOUNT>0                           
    ROLLBACK TRANSACTION                                   
    -- 12/10/13 YS inser into importBOMErrors                                  
    --12/06/17 YS change error handling to use variable                                  
    INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
    SELECT DISTINCT @importId,@ERRORNUMBER                                  
    ,@ERRORSEVERITY                                   
    ,@ERRORPROCEDURE                                  
    ,@ERRORLINE                                   
    ,@ERRORMESSAGE                                   
    ,GETDATE()                                  
    return -1                                  
  END CATCH                                  
 END --IF @AssyUniqKey<>' ' (Found part already in the inventory                             
  ELSE --IF @AssyUniqKey<>' ' (Found part already in the inventory                                  
  BEGIN                                  
   -- still not exists                                  
   -- 06/05/13 YS populate fields from parttype table                                  
   -- 06/10/13 YS if parttype table has no records for @Assytype and @Assyclass will have 0 records inserted into inventory                                  
   -- will insert first values from variables and then update                                  
   -- 07/31/15 Raviraj Added UseSetScrp and StdBldQty for the Assembly, insert the values in Inventor table                                  
   BEGIN TRY                                  
   SELECT @AssyUniqKey=dbo.fn_GenerateUniqueNumber()                                  
   INSERT INTO Inventor (BomCustNo,Part_sourc,Uniq_key,Part_no,Revision,Descript,Part_class,Part_type,USESETSCRP,STDBLDQTY,ImportId,[Status],[Bom_status]                                  
    ,[ORD_POLICY]                                  
    ,[PACKAGE]                                  
    ,[BUYER_TYPE]                                  
    ,[REORDPOINT]                                  
    ,[MINORD]                                  
    ,[ORDMULT]                    
    ,[ABC]                                  
    ,[REORDERQTY]                                  
    ,[INSP_REQ]                           
    ,[CERT_REQ]                                  
    ,[CERT_TYPE]                                  
    ,[SCRAP]                                  
    ,[SETUPSCRAP]                                  
    ,[LOC_TYPE]                                  
    ,[PUR_LTIME]                                  
    ,[PUR_LUNIT]                                  
    ,[KIT_LTIME]                                  
    ,[KIT_LUNIT]                                  
    ,[PROD_LTIME]                                  
    ,[PROD_LUNIT]                                  
    ,[PULL_IN]                                  
    ,[PUSH_OUT]                                  
    ,[DAY]                                  
    ,[DAYOFMO]                                  
    ,[DAYOFMO2]                                  
    ,[MATL_COST]                                  
    ,[LABORCOST]                                  
    ,[OTHER_COST]                                  
    ,[OVERHEAD]                                  
    ,[MRC]                                  
    ,[OTHERCOST2]                                  
    ,[TARGETPRICE]                                  
    ,[PUR_UOFM]                                  
    ,[U_OF_MEAS]                            
 ,useipkey                         
 -- 05/07/2019 : Vijay G : LastChangInit Not Populated for the Newly Added Part                          
 ,LASTCHANGEINIT                          
 -- 05/13/2019 : Vijay G : LASTCHANGEUSERID Not Populated for the Newly Added Part                          
 ,LASTCHANGEUSERID                                 
 -- 02/14/2020 Nitesh B : Insert AspnetBuyer from PartClass table if PartClass having default buyer                             
    ,AspnetBuyer)                           
   SELECT Custno,Part_sourc,Uniq_key,Part_no,Revision,                          
   -- 05/21/2019 Vijay G: If description is null of empty then we use part_no as desciption                          
   CASE WHEN Descript IS NULL OR Descript ='' THEN Part_no                          
   ELSE Descript END,                          
   B.Part_class,B.Part_Type,USESETSCRP,STDBLDQTY,ImportId,[Status],Bom_status,                                  
    ISNULL(P.[ORD_POLICY],CAST('' as CHAR(12))) as ORD_POLICY,                                  
   '' as Package,  --ISNULL([PACKAGE],CAST('' as CHAR(15))) as Package,    -- 02/19/2020 Rajendra K : Insert Blank value into Package Column of Inventor table                      
    ISNULL([BUYER_TYPE],CAST('' as CHAR(3))) as Buyer_type,                                  
    ISNULL([REORDPOINT],CAST(0 as numeric(7))) as [REORDPOINT],                                  
    ISNULL([MINORD],CAST(0 as numeric(7))) as [MINORD],                                  
    ISNULL([ORDMULT],CAST(0 as numeric(7,0))) as [ORDMULT],                                  
    ISNULL([ABC],CAST('' as CHAR(1))) as [ABC],                                   
    ISNULL([REORDERQTY],CAST(0 as numeric(7,0))) as  [REORDERQTY],                                  
    ISNULL([INSP_REQ],CAST(0 as bit)) as  [INSP_REQ],                                  
    ISNULL([CERT_REQ],CAST(0 as bit)) as  [CERT_REQ],                                  
    ISNULL([CERT_TYPE],CAST('' as CHAR(10))) as [CERT_TYPE],                                  
    ISNULL([SCRAP],CAST(0 as numeric(6,2))) as [SCRAP],                                   
    ISNULL([SETUPSCRAP],CAST(0 as numeric(4,0))) as  [SETUPSCRAP],                                  
    ISNULL([LOC_TYPE],CAST('' as CHAR(10))) as [LOC_TYPE],                                   
    ISNULL([PUR_LTIME],CAST(0 as numeric(3,0))) as  [PUR_LTIME],                                   
    ISNULL([PUR_LUNIT],CAST('' as CHAR(2))) as [PUR_LUNIT],                                  
    ISNULL([KIT_LTIME],CAST(0 as numeric(3,0))) as  [KIT_LTIME],                                  
    ISNULL([KIT_LUNIT],CAST('' as CHAR(2))) as [KIT_LUNIT],                                  
    ISNULL([PROD_LTIME],CAST(0 as numeric(3,0))) as [PROD_LTIME],                                  
    ISNULL([PROD_LUNIT],CAST('' as CHAR(2))) as [PROD_LUNIT],                                  
    ISNULL([PULL_IN],CAST(0 as numeric(3,0))) as [PULL_IN],                                  
    ISNULL([PUSH_OUT],CAST(0 as numeric(3,0))) as [PUSH_OUT],                                  
    ISNULL([DAY],CAST(0 as numeric(1))) as [DAY],                                   
    ISNULL([DAYOFMO],CAST(0 as numeric(2))) as [DAYOFMO],                                   
    ISNULL([DAYOFMO2],CAST(0 as numeric(2))) as [DAYOFMO2],                                  
    ISNULL([MATL_COST],CAST(0 as numeric(13,5))) as [MATL_COST],                                   
    ISNULL([LABORCOST],CAST(0 as numeric(13,5))) as [LABORCOST],                                  
    ISNULL([OTHER_COST],CAST(0 as numeric(13,5))) as [OTHER_COST],                                  
    ISNULL([OVERHEAD],CAST(0 as numeric(13,5))) as [OVERHEAD],                                  
    ISNULL([MRC],CAST('' as CHAR(15))) as [MRC],                                  
    ISNULL([OTHERCOST2],CAST(0 as numeric(13,5))) as [OTHERCOST2],                                  
    ISNULL([TARGETPRICE],CAST(0 as numeric(13,5))) as [TARGETPRICE],                                  
    ISNULL([PUR_UOFM],CAST('' as CHAR(4))) as [PUR_UOFM],                                  
    ISNULL([U_OF_MEAS] ,CAST('' as CHAR(4))) as [U_OF_MEAS],                            
 -- 10/30/2018 Vijay G : insert the Value for useipkey from the match found in the PartClass Table for the Added new Assembly and Components                            
 ISNULL(class.useIpKey ,CAST(0 as BIT)),                          
   @userInit,@userId,                    
   ISNULL(class.aspnetBuyer, '00000000-0000-0000-0000-000000000000') AS AspnetBuyer  -- 02/14/2020 Nitesh B : Insert AspnetBuyer from PartClass table if PartClass having default buyer                                      
 FROM                             
 (                            
  SELECT @custno as custno,@AssySource as part_sourc,@AssyUniqKey as Uniq_key,@AssyNum as part_no,@AssyRev as revision,                                  
  @AssyDesc as Descript,@AssyClass as Part_class,@Assytype as Part_type, @useSetUp as USESETSCRP, @stdBldQty as STDBLDQTY,@importId as ImportId,'Active' as [Status],                            
  'Active' as [Bom_Status]                            
 ) as B                                   
    LEFT OUTER JOIN PARTTYPE P ON B.Part_class =P.PART_CLASS AND B.Part_type=P.Part_type                              
 INNER JOIN PartClass class on B.Part_class= class.PART_CLASS                                  
                                     
   END TRY                                  
   -- code here                                  
   BEGIN CATCH                                   
    -- 12/09/13 YS check fr errors prior to proceeding                                 
    SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
    ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
    ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
    ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
    ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
    IF @@TRANCOUNT>0                                  
     ROLLBACK TRANSACTION                                   
     -- 12/10/13 YS inser into importBOMErrors                                  
    --12/06/17 YS change error handling to use variable                                  
     INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
     SELECT DISTINCT @importId,@ERRORNUMBER                                  
     ,@ERRORSEVERITY                                   
     ,@ERRORPROCEDURE                                  
     ,@ERRORLINE                                   
     ,@ERRORMESSAGE                                   
     ,GETDATE()                                  
     return -1                                  
                                    
   END CATCH                                  
   BEGIN TRY                                  
   SELECT @AssyMfgrHd=dbo.fn_GenerateUniqueNumber()                                  
                                     
   --10/14/14 YS first check if mfgrmaster table has record for this mfgr                                  
   -- remove all prior records from   @GenrMaster and@GenrAvl                                   
   DELETE FROM @GenrMaster                                  
   delete FROM @GenrAvl                                   
                                  
   MERGE MfgrMaster T                                  
   USING (SELECT 'GENR' as PartMfgr, SUBSTRING(@AssyNum,1,30) as Mfgr_pt_no)  as S                                  
   ON (s.PartMfgr=T.PartMfgr AND S.Mfgr_pt_no=T.Mfgr_pt_no)                                  
   WHEN MATCHED  THEN UPDATE SET T.is_deleted=0                                  
   WHEN NOT MATCHED BY TARGET THEN                          
   INSERT (Partmfgr,mfgr_pt_no,MatlType) VALUES (CAST(rtrim(S.PartMfgr) as char(8)),S.mfgr_pt_no,'Unk')                                
   OUTPUT CAST(rtrim(Inserted.PartMfgr) as char(8)),Inserted.Mfgr_pt_no,Inserted.MfgrmasterId into @GenrMaster;                                
                    
   -- 10/14/14 YS Now update or insert into Invtmpnlink                                
   --INSERT INTO Invtmfhd ([Uniq_key],MatlType,Mfgr_pt_no,PartMfgr,Uniqmfgrhd)                                   
   --   VALUES (@AssyUniqKey,'Unk',SUBSTRING(@AssyNum,1,30),'GENR',@AssyMfgrHd)                                  
                                     
   INSERT INTO INVTMPNLINK ([Uniq_key],Uniqmfgrhd,mfgrMasterId)                                 
    OUTPUT Inserted.Uniq_key,Inserted.Uniqmfgrhd,Inserted.mfgrMasterId INTO @GenrAvl                                    
   Select @AssyUniqKey,@AssyMfgrHd,m.MfgrMasterId                                  
   FROM @GenrMaster M                                   
                                  
   -- 06/01/16 YS update autolocation based on parttype table                                   
   UPDATE MfgrMaster SET Autolocation = ISNULL(p.autolocation,0) from inventor I inner join                                   
    @GenrAvl K on i.uniq_key=k.Uniq_key                                  
   inner join parttype p on i.part_class=p.part_class and i.part_type=p.Part_type                                  
   where k.MfgrMasterId=MfgrMaster.MfgrMasterId                                  
                                  
   END TRY                                     
   BEGIN CATCH                                   
   -- 12/09/13 YS check fr errors prior to proceeding                                  
   SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
   ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
   ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
   ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
   ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
   IF @@TRANCOUNT>0                                  
    ROLLBACK TRANSACTION                                   
    -- 12/10/13 YS inser into importBOMErrors                                  
    --12/06/17 YS change error handling to use variable                                  
    INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)   
    SELECT DISTINCT @importId,@ERRORNUMBER                                  
    ,@ERRORSEVERITY                                   
    ,@ERRORPROCEDURE                                  
    ,@ERRORLINE                                   
    ,@ERRORMESSAGE                                   
    ,GETDATE()                                  
    return -1                                  
                                    
   END CATCH                                  
                                     
   --- !!! UniqWh for Assy?                                  
   BEGIN TRY                                  
   ----02/20/14 YS move this up top to use it to create a location for the GENR avl if no avl were entered.                                  
   ---- e-name variable to be defaultUniqWh                                  
   --SELECT @AssyUniqWh=Uniqwh FROM Warehous WHERE Warehous.[Default]=1                                  
                                       
   INSERT INTO Invtmfgr ([Uniq_key],Uniqmfgrhd,Uniqwh,W_key,NETABLE)                                   
      VALUES (@AssyUniqKey,@AssyMfgrHd,@AssyUniqWh,dbo.fn_GenerateUniqueNumber(),1)                                     
   END TRY                      
   BEGIN CATCH                                   
    -- 12/09/13 YS check fr errors prior to proceeding                                  
    SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
    ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
    ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
    ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
    IF @@TRANCOUNT>0                                  
     ROLLBACK TRANSACTION                                   
     -- 12/10/13 YS inser into importBOMErrors                                  
     --12/06/17 YS change error handling to use variable                                  
     INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
     SELECT DISTINCT @importId,@ERRORNUMBER                                  
     ,@ERRORSEVERITY                       
     ,@ERRORPROCEDURE                                  
     ,@ERRORLINE                                   
     ,@ERRORMESSAGE                                   
     ,GETDATE()                  
     return -1                           
                                    
   END CATCH                                  
                                    
END  --ELSE IF @AssyUniqKey<>' ' (Found part already in the inventory                                  
 END -- IF @AssyUniqKey=' '                                  
 ELSE -- If @AssyUniqKey <> '' then update the UseSetup and StdBldQty for the assembly                                  
 BEGIN                                  
  -- 07/31/15 Raviraj Added UseSetScrp and StdBldQty for the Assembly, for existing AssyUniqKey update the values                                  
  --08/11/15 YS overwrite USESETSCRP and STDBLDQTY only if @stdbldqty<>0, otherwise use the existsing settings                                   
  -- 03/04/18: Vijay G: Update the part status and bom_status if InActive then set as Active                            
  UPDATE Inventor SET                                   
  USESETSCRP =  CASE WHEN @useSetUp=1 THEN @useSetUp ELSE  USESETSCRP END,                                   
  STDBLDQTY = CASE WHEN @stdBldQty<>0 THEN @stdBldQty ELSE STDBLDQTY END,         
  [Status]= CASE WHEN [Status] ='InActive' THEN 'Active' ELSE [Status] END,                             
  -- 01/18/2019 : Vijay G : Fix the Issue the BOM_Status is not converted from InActive to Active after Import Data                                  
  [Bom_Status]=CASE WHEN [Bom_Status] ='InActive' THEN 'Active' ELSE [Bom_Status] END          
  where UNIQ_KEY=@AssyUniqKey                              
                             
  -- 11/29/18 Vijay G Update Assembly cust no if assembly don't have components                            
  IF NOT EXISTS(SELECT 1 FROM BOM_DET WHERE BOMPARENT = @AssyUniqKey)                            
  BEGIN                            
   UPDATE Inventor SET  BOMCUSTNO = @custno WHERE UNIQ_KEY=@AssyUniqKey                                                 
  END                                                  
 END                                  
 IF @@TRANCOUNT>0                                  
 COMMIT TRANSACTION                                                   
 -- !!!end uncomment when ready to update inventory                                  
 -- now create BOM                                  
 --!!! Will have to check if BOM exists and update according to rules. See David about the rules                                  
 -- for now create new BOM                                  
 -- Get ready for Bom_det                                  
 BEGIN TRANSACTION                                   
 -- 05/26/13 !!! for now just remove records form BOM later have to check if BOM is locked and /or maybe create a log for a BOM, also should we check for the OPEN orders and stop from updating the BOM?                                  
 -- using Vicky's procedure to remove all BOM records for the given BOM                                  
 BEGIN TRY                                  
  EXEC sp_DeleteBom4Uniq_key @AssyUniqKey                                  
 END TRY                                  
 BEGIN CATCH                                   
  -- 12/09/13 YS check fr errors prior to proceeding                                  
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
  ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
  ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
  IF @@TRANCOUNT>0                                  
   ROLLBACK TRANSACTION                                   
   -- 12/10/13 YS inser into importBOMErrors                                  
   --12/06/17 YS change error handling to use variable                                  
   INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
   SELECT DISTINCT @importId,@ERRORNUMBER                                  
   ,@ERRORSEVERITY                                   
   ,@ERRORPROCEDURE                                  
   ,@ERRORLINE                                   
   ,@ERRORMESSAGE                 
   ,GETDATE()                                  
   return -1                                                    
  END CATCH                                  
 -- 05/23/13 YS added bom_det.item_note (BomNote in the field definition table)                                  
 BEGIN TRY                                  
 DECLARE @BomDet Table (rowid uniqueidentifier,bomparent char(10),uniqbomno char(10),uniq_key char(10),Qty Numeric(9,2),Item_no Numeric(4,0),Used_inkit Char(1),dept_id char(4),Item_note varchar(max),ROW int)                                
 ; WITH BomDetail AS                                  
 (                                  
  select rowId,rtrim(uniq_key) as Uniq_key,                                  
  ---08/16/17 YS check for u_of_m and if like 'EA%' round up                                  
  --CASE WHEN ISNUMERIC(qty)=1 and U_of_m like 'EA%' THEN CAST(CEILING(Qty) as Numeric(9,2))              
  -- WHEN ISNUMERIC(qty)=1 and U_of_m not like 'EA%'THEN CAST(Qty as Numeric(9,2)) ELSE CAST(0.0 as Numeric(9,2)) END AS Qty,                                  
  ---12/06/17 YS convert to float will conver even if the data has scintific notation (e.g. E-3)               
  CASE WHEN  U_of_m like 'EA%' THEN CEILING(CONVERT(FLOAT(53),QTY)) ELSE CONVERT(FLOAT(53),QTY) END AS Qty,                                  
  CASE WHEN ISNUMERIC(Itemno)=1 THEN CAST(Itemno as numeric (4,0)) ELSE  CAST(0.0 as numeric (4,0)) END as Item_no,                                  
  CASE WHEN Used IS NULL THEN 'Y' ELSE RTRIM(Used) END AS Used_inKit,                                  
  CASE WHEN workCenter IS NULL THEN '    ' ELSE CAST(rtrim(workcenter) as char(4)) END as dept_id,                                  
  ISNULL(BomNote,cast(' ' as varchar(max))) as Item_note                                  
   from @iTable                                  
  WHERE class<>'i05red'                            
  AND uniq_key<>' '  -- part exists                                  
  and partsource<>'CONSG' -- not a consign part                                  
 UNION                                  
  select B.rowId,Inventor.uniq_key,                                  
  ---08/16/17 YS check for u_of_m and if like 'EA%' round up                                  
  --CASE WHEN ISNUMERIC(B.qty)=1 and B.U_of_m like 'EA%' THEN CAST(CEILING(B.Qty) as Numeric(9,2))                                  
  -- WHEN ISNUMERIC(B.qty)=1 and B.U_of_m not like 'EA%'THEN CAST(b.Qty as Numeric(9,2)) ELSE CAST(0.0 as Numeric(9,2)) END AS Qty,                                  
  ---12/06/17 YS convert to float will conver even if the data has scintific notation (e.g. E-3)                                  
  CASE WHEN  U_of_m like 'EA%' THEN CEILING(CONVERT(FLOAT(53),b.QTY)) ELSE CONVERT(FLOAT(53),b.QTY) END AS Qty,                                  
  CASE WHEN ISNUMERIC(B.Itemno)=1 THEN CAST(B.Itemno as numeric (4,0)) ELSE  CAST(0.0 as numeric (4,0)) END as Item_no,                   
  CASE WHEN Used IS NULL THEN 'Y' ELSE RTRIM(Used) END AS Used_inKit,                                  
  CASE WHEN B.workCenter IS NULL THEN '    ' ELSE CAST(rtrim(B.workcenter) as char(4)) END as dept_id,                                  
  ISNULL(B.BomNote,cast(' ' as varchar(max))) as Item_note                                  
  from @iTable B INNER JOIN INVENTOR ON B.uniq_key=Inventor.INT_UNIQ and Inventor.CUSTNO=@custno                                  
  WHERE class<>'i05red'                                  
  AND B.uniq_key<>' '  -- part exists                                  
  AND Partsource='CONSG' -- consgn part need to find uniq_key for consign part David said all uniq_key are for internal part                                   
 UNION                                  
  SELECT B.rowId,rtrim(C.uniq_key) as Uniq_key,                                  
  ---08/16/17 YS check for u_of_m and if like 'EA%' round up                                  
  --CASE WHEN ISNUMERIC(B.qty)=1 and B.U_of_m like 'EA%' THEN CAST(CEILING(B.Qty) as Numeric(9,2))                                  
  -- WHEN ISNUMERIC(B.qty)=1 and B.U_of_m not like 'EA%'THEN CAST(b.Qty as Numeric(9,2)) ELSE CAST(0.0 as Numeric(9,2)) END AS Qty,                               
  ---12/06/17 YS convert to float will conver even if the data has scintific notation (e.g. E-3)                                  
  CASE WHEN  U_of_m like 'EA%' THEN CEILING(CONVERT(FLOAT(53),b.QTY)) ELSE CONVERT(FLOAT(53),b.QTY) END AS Qty,                                  
  CASE WHEN ISNUMERIC(B.Itemno)=1 THEN CAST(B.Itemno as numeric (4,0)) ELSE  CAST(0.0 as numeric (4,0)) END as Item_no,                                 
  CASE WHEN Used IS NULL THEN 'Y' ELSE RTRIM(Used) END AS Used_inKit,                                  
  CASE WHEN B.workCenter IS NULL THEN ' ' ELSE CAST(rtrim(B.workcenter) as char(4)) END as dept_id,                                  
  ISNULL(B.BomNote,cast(' ' as varchar(max))) as Item_note                   
  from @iTable B INNER JOIN @tConsgignInventor C ON B.rowid=C.rowid                                   
  WHERE B.class<>'i05red'                                  
  AND B.uniq_key=' '  -- new part                   
  AND Partsource='CONSG' -- consgn part                                   
 UNION                                  
  SELECT B.rowId,rtrim(I.uniq_key) as Uniq_key,                                  
  ---08/16/17 YS check for u_of_m and if like 'EA%' round up                                  
  --CASE WHEN ISNUMERIC(B.qty)=1 and B.U_of_m like 'EA%' THEN CAST(CEILING(B.Qty) as Numeric(9,2))                                  
  -- WHEN ISNUMERIC(B.qty)=1 and B.U_of_m not like 'EA%'THEN CAST(b.Qty as Numeric(9,2)) ELSE CAST(0.0 as Numeric(9,2)) END AS Qty,                                  
  ---12/06/17 YS convert to float will conver even if the data has scintific notation (e.g. E-3)                         
  CASE WHEN  U_of_m like 'EA%' THEN CEILING(CONVERT(FLOAT(53),b.QTY)) ELSE CONVERT(FLOAT(53),b.QTY) END AS Qty,                                  
  CASE WHEN ISNUMERIC(B.Itemno)=1 THEN CAST(B.Itemno as numeric (4,0)) ELSE  CAST(0.0 as numeric (4,0)) END as Item_no,                                  
  CASE WHEN Used IS NULL THEN 'Y' ELSE RTRIM(Used) END AS Used_inKit,                                  
  CASE WHEN B.workCenter IS NULL THEN '    ' ELSE CAST(rtrim(B.workcenter) as char(4)) END as dept_id,                                  
  ISNULL(B.BomNote,cast(' ' as varchar(max))) as Item_note                                  
  from @iTable B INNER JOIN @tInternalInventor I ON B.rowid=I.rowid                                   
  WHERE B.class<>'i05red'                                  
  AND B.uniq_key=' '  -- new part                                   
  AND Partsource<>'CONSG' -- not consgn part                                    
 )                                  
               
 INSERT INTO @BomDet (rowid,bomparent,uniqbomno,uniq_key,Qty,Item_no,Used_inKit,Dept_id ,item_note,ROW)                                
  SELECT rowid,@AssyUniqKey,dbo.fn_GenerateUniqueNumber(),uniq_key,Qty,Item_no,Used_inkit,Dept_id ,Item_note                              
  ,ROW_NUMBER() OVER(ORDER BY rowid DESC) AS ROW   -- 10/17/2018 Vijay G To get bom item import level notes to BOM Summary                              
   FROM BomDetail                                
                                   
 --07/28/15 Anuj added check for any records inserted into @bomdet, if none generate an error                                  
 IF (exists (select 1 from @BomDet))                                  
 BEGIN                                
  -- 01/15/2019 Vijay G :Put the Entry of userid in the Modifiedby column of BOM_Det table                              
  INSERT INTO BOM_DET (bomparent,uniqbomno,uniq_key,Qty,Item_no,Used_inKit,Dept_id,ModifiedBy)                                   
  SELECT bomparent,uniqbomno,uniq_key,Qty,Item_no,Used_inKit,Dept_id,@userId FROM @BomDet                                  
                              
  -- 10/17/2018 Vijay G To get bom item import level notes to BOM Summary                              
  DECLARE @totalRecords INT, @Count INT = 1;                              
  SELECT @totalRecords =  COUNT(*) FROM @BomDet;                              
                              
  -- 10/17/2018 Vijay G Check notes for first time import based on rowid will update recordid in Wmnotes table                  
  WHILE (@Count <= @totalRecords)                              
  BEGIN                               
   IF EXISTS(SELECT 1 FROM wmNotes WHERE RecordType='importBOMItemNote' AND RecordId = (SELECT CAST(rowId AS varchar(100)) from @BomDet where ROW = @Count))                              
   BEGIN                              
    UPDATE WmNotes SET RecordType='BOM_DET',RecordId = (SELECT uniqbomno FROM @BomDet WHERE WmNotes.RecordId = CAST(rowId AS varchar(100)) AND  ROW = @Count)                               
    WHERE RecordType='importBOMItemNote' AND RecordId = (SELECT CAST(rowId AS varchar(100)) from @BomDet where ROW = @Count)                               
   END                                  
   SELECT @Count = @Count + 1;                              
  END                              
  END                                
 ELSE   -- IF (exists (select 1 from @BomDet))                                  
 BEGIN                     
  IF @@TRANCOUNT>0                                  
  ROLLBACK TRANSACTION                                   
  -- 07/28/15 YS inser into importBOMErrors                                 
  INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
  SELECT DISTINCT @importId,0                                   
  ,11                                   
  ,'Insert into @Bom_det'                                  
  ,0                                   
  ,'No Records available to insert into Bom_det. Fix all the ''red'' flags and re-load'                                    
  ,GETDATE()                                  
  return -1                                  
 END --- IF (exists (select 1 from @BomDet))                                  
 END TRY                                   
 -- get bom ref information                                   
 BEGIN CATCH                                
  -- 12/09/13 YS check fr errors prior to proceeding                                  
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
  ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
  ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
  IF @@TRANCOUNT>0                                  
  ROLLBACK TRANSACTION                                   
  -- 12/10/13 YS inser into importBOMErrors                                  
  --12/06/17 YS change error handling to use variable                                  
  INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
  SELECT DISTINCT @importId,@ERRORNUMBER                                  
  ,@ERRORSEVERITY                                   
  ,@ERRORPROCEDURE                                  
  ,@ERRORLINE                                   
  ,@ERRORMESSAGE                                   
  ,GETDATE()                                  
  return -1                                                       
 END CATCH                         
                        
 BEGIN TRY                                  
  ;WITH Bomref                                  
  AS(                                  
  SELECT r.fkrowid,bd.Uniqbomno,refdesg as ref_des,refOrd,bd.Qty,ROW_NUMBER() OVER(PARTITION BY fkrowid ORDER BY refOrd) as Nbr ,dbo.fn_GenerateUniqueNumber() as Uniqueref                                  
    FROM importBomRefDesg R INNER JOIN @bomDet BD ON R.fkrowid=BD.rowid                                  
   where fkimportid=@importid and status<>'i05red'                                  
  )                                  
  -- make sure the number of reference designators is not bigger than the qty per                                  
  INSERT INTO Bom_ref (Uniqbomno,Ref_des,Nbr,Uniqueref) SELECT Uniqbomno,RIGHT(Ref_des, 50),Nbr,Uniqueref FROm BomRef WHERE Nbr<=Qty                                  
 END TRY                                  
 BEGIN CATCH                                   
  -- 12/09/13 YS check fr errors prior to proceeding                                  
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
  ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
  ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
  IF @@TRANCOUNT>0                                  
   ROLLBACK TRANSACTION                            
   -- 12/10/13 YS inser into importBOMErrors                                  
   --12/06/17 YS change error handling to use variable                                  
   INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
   SELECT DISTINCT @importId,@ERRORNUMBER                                  
   ,@ERRORSEVERITY                                   
   ,@ERRORPROCEDURE                                  
   ,@ERRORLINE                                   
   ,@ERRORMESSAGE                                   
   ,GETDATE()                                  
   return -1                                      
 END CATCH                 
                                
 BEGIN TRY                                   
  INSERT INTO ANTIAVL (Bomparent ,uniq_key ,partmfgr ,mfgr_pt_no ,uniqanti)                                   
  SELECT @AssyUniqKey,CASE WHEN ad.CustUniq<>' ' THEN ad.CustUniq ELSE ad.Uniq_key END                            
  ,partmfgr,mfgr_pt_no,dbo.fn_GenerateUniqueNumber()                                   
  FROM @tAvlDynamic AD                             
  INNER JOIN @tInventor tI ON AD.RowId=tI.rowId                                  
  WHERE AD.BOM=0                                  
     AND ((ti.CustPartno<>' ' AND Ad.CustUniq<>' ') OR  ti.CustPartNo=' ')                                 
  AND ad.Class <> 'i05red'                                   
  AND Ad.comments lIKE 'exist%'                             
  -- 11/20/2018 Vijay G Add group by clause for the insert data in the Antiavl                            
  GROUP BY ad.CustUniq,ad.Uniq_key,partmfgr,mfgr_pt_no                                  
                                  
  -- 05/25/18 YS added antiavl if the settings is to disallow auto-adding new avl to the existsing BOMs other than the one loaded                                  
  -- 06/08/18 Vijay G : Moved the Disable Automatic BOM AVL Update setting value from InvtSetup table to MnxSettingsManagement and wmSettingsManagement table                                  
  -- 07/25/18 Vijay G : Renamed the setting name from "AutomaticBOMAVLUpdate" to "DisableAutoBOMAVLUpdate"                                  
  IF (SELECT ISNULL(w.settingValue,m.settingValue)FROM MnxSettingsManagement M LEFT OUTER JOIN wmSettingsManagement W ON m.settingId=w.settingId WHERE settingName ='DisableAutoBOMAVLUpdate')=1                                   
  BEGIN                                  
   INSERT INTO ANTIAVL (Bomparent ,uniq_key ,partmfgr ,mfgr_pt_no ,uniqanti)                                   
   select Bomparent,custuniq_key,partmfgr,mfgr_pt_no,dbo.fn_GenerateUniqueNumber()                                   
   from                            
   (                                  
   SELECT BomParent,Bom_Det.Uniq_key,M.BomCustNo ,i.PART_SOURC,c.custno,ad.partmfgr,ad.mfgr_pt_no,                                  
   CASE WHEN i.part_sourc='CONSG' THEN c.UNIQ_KEY                                   
   WHEN i.PART_SOURC='BUY' and c.CUSTNO=m.BOMCUSTNO THEN c.UNIQ_KEY ELSE i.UNIQ_KEY END AS custuniq_key                                  
   FROM @tAvlDynamic AD                             
   INNER JOIN inventor i ON ad.uniq_key=i.UNIQ_KEY                                  
   INNER JOIN Bom_Det ON bom_det.UNIQ_KEY=i.UNIQ_KEY                                  
   INNER JOIN Inventor M on M.Uniq_key=Bom_det.BomParent                                  
   LEFT OUTER JOIN inventor c ON i.UNIQ_KEY=c.INT_UNIQ                             
   -- 09/04/2018 Vijay G Remove And Condition it Will get wrong data to Insert Record in AntiAVL              
   WHERE ((m.bomcustno<>@custno or c.custno is null) or (m.bomcustno=@custno and BomParent<>@AssyUniqKey))            
   AND ad.Class <> 'i05red'                                   
   AND Ad.comments = 'newAvl'            
   --10/22/2018 Vijay G Fix the Issue for the Newly Added MPN are not checked in AVL Fixes Add And Condition BOMPARENT<>@AssyUniqKey                              
      AND BOMPARENT<>@AssyUniqKey                            
    ) T                                
    -- 11/20/2018 Vijay G Add group by clause for the insert data in the Antiavl                            
    GROUP BY Bomparent,custuniq_key,partmfgr,mfgr_pt_no                              
                                  
    --- 08/20/18 YS add missing antiavl for the existsing consign part if bom assigend to the custno already exists                                  
    --- new avl should not be added                                  
    INSERT INTO ANTIAVL (Bomparent ,uniq_key ,partmfgr ,mfgr_pt_no ,uniqanti)                                   
    SELECT Bomparent,custuniq_key,partmfgr,mfgr_pt_no,dbo.fn_GenerateUniqueNumber()                                   
    FROM                            
    (                                  
    SELECT BomParent,Bom_Det.Uniq_key,M.BomCustNo ,i.PART_SOURC,ad.partmfgr,ad.mfgr_pt_no,                                  
    CASE WHEN i.part_sourc='CONSG' THEN ad.custUniq_key                                   
    WHEN i.PART_SOURC='BUY' THEN ad.custUniq_key ELSE i.UNIQ_KEY END AS custuniq_key                                  
    --09/10/2018 Vijay G Newly Added MPN are Approved for the other Assembly Where same component is used                              
    FROM @tConsignExistsAvlAdded AD                               
    INNER JOIN inventor i on ad.custUniq_key=i.UNIQ_KEY                             
    INNER JOIN Bom_Det ON bom_det.UNIQ_KEY=i.UNIQ_KEY                        
    INNER JOIN Inventor M ON M.Uniq_key=Bom_det.BomParent                                  
    where (m.bomcustno=@custno and BomParent<>@AssyUniqKey)                            
    ) T                               
   -- 11/20/2018 Vijay G Add group by clause for the insert data in the Antiavl                            
   GROUP BY Bomparent,custuniq_key,partmfgr,mfgr_pt_no                                      
  END                                  
 END TRY                                    
 BEGIN CATCH                                   
  -- 12/09/13 YS check fr errors prior to proceeding                                  
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
  ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
  ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
  IF @@TRANCOUNT>0                                  
   ROLLBACK TRANSACTION                                   
   -- 12/10/13 YS inser into importBOMErrors                                  
   --12/06/17 YS change error handling to use variable                                  
   INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
   SELECT DISTINCT @importId,@ERRORNUMBER                                  
   ,@ERRORSEVERITY                                   
   ,@ERRORPROCEDURE                                  
   ,@ERRORLINE                                   
   ,@ERRORMESSAGE                                   
   ,GETDATE()                                  
   return -1                                                     
 END CATCH                
                                 
 -- update ImportBomHeader                                  
 BEGIN TRY                           
  -- 05/21/2019 Vijay G: In the Completed by Column Add Userid insted of initials                                 
  UPDATE ImportBomHeader SET CompleteDate =GETDATE(),CompletedBy=@userId,Uniq_key=@AssyUniqKey where importid=@importid                                  
 END TRY                                  
 BEGIN CATCH                                   
  -- 12/09/13 YS check fr errors prior to proceeding         
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                         
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)            ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                
  ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
  IF @@TRANCOUNT>0                                  
   ROLLBACK TRANSACTION                                   
   -- 12/10/13 YS inser into importBOMErrors                                  
   --12/06/17 YS change error handling to use variable                                  
   INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
   SELECT DISTINCT @importId,@ERRORNUMBER                                  
   ,@ERRORSEVERITY                                   
   ,@ERRORPROCEDURE                                  
   ,@ERRORLINE                                   
   ,@ERRORMESSAGE                                   
   ,GETDATE()                                  
   return -1                                                        
 END CATCH                                  
 IF @@TRANCOUNT>0                                  
 COMMIT TRANSACTION                                    
 --/* Run validation */                                   
                                   
 EXEC [dbo].[importBOMVldtnCheckManExNumAll] @importId                                    
 --DELETE FROM @iTable                      
 --INSERT INTO @iTable                                    
 --EXEC [dbo].[sp_getImportBOMItems] @importId                                    
 Declare @cnt as int;                                  
 --SELECT @cnt=COUNT(*)FROM @iTable WHERE class='i05red'                                    
 -- 10/11/18 Vijay G : Checking errors at part level , avl level and ref desg level                                
 ;WITH importBomErrorCount AS (                                
  SELECT status  from importBOMFields  WHERE importBOMFields.fkImportId = @importId AND status ='i05red'                                
  UNION                                  
  SELECT status  from importBOMAvl  WHERE fkImportId = @importId AND status ='i05red'                                
  UNION                                 
  SELECT status  from importBOMRefDesg  WHERE fkImportId = @importId AND status ='i05red'                                
 )SELECT @cnt = COUNT(Status) FROM importBomErrorCount                                 
                                
 BEGIN TRANSACTION                                  
 BEGIN TRY                                  
  UPDATE importBOMHeader SET status=CASE WHEN @cnt=0 THEN 'Loaded' ELSE 'PartLoaded' END WHERE importId=@importId                                   
 END TRY                                  
 BEGIN CATCH                                   
  -- 12/09/13 YS check fr errors prior to proceeding                                  
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
  ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
  ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
  IF @@TRANCOUNT>0                                  
   ROLLBACK TRANSACTION                                   
   -- 12/10/13 YS inser into importBOMErrors                                  
   --12/06/17 YS change error handling to use variable                                  
   INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
   SELECT DISTINCT @importId,@ERRORNUMBER                                  
   ,@ERRORSEVERITY                                   
   ,@ERRORPROCEDURE                                  
   ,@ERRORLINE                  
   ,@ERRORMESSAGE                                   
   ,GETDATE()                                  
   return -1                                                   
 END CATCH                                  
 IF @@TRANCOUNT>0                                  
 COMMIT TRANSACTION                           
                                    
 --06/13/2013 update mnxNotes                                  
 --11/11/13 use @userId instead of fixed id.                                  
 BEGIN TRY                                  
  DECLARE @noteId uniqueidentifier = newid(),                                  
  @Description VARCHAR(max) ='BOM for Assembly: '+ RTRIM(@AssyNum)+CASE WHEN @AssyRev<>' ' THEN ',Revision: '+ RTRIM(@AssyRev) ELSE '' END                                   
  +' was loaded by import module with import status:'                                  
  -- 05/15/2019 : Vijay G : Modify sp for change status from part load to Partialy Loaded in bom screen                               
  + CASE WHEN @cnt=0 THEN ' Loaded.' ELSE ' Partialy Loaded.' END,                                
  @CreatedUserID uniqueidentifier=@userId,                                  
  @ReminderDate datetime=NULL                                  
  -- @IsFlagged bit=0, -- 02/22/2017 : Vijay G : IsFlagged column no longer in used                                  
  -- @IsSystemNote bit=1 --02/22/2017 : Vijay G : IsSystemNote column no longer in used                                  
                                  
  -- 03/08/2018 : Vijay G : Insert the bom assembly notes into wmNotes and wmNoteRalationship table.                                  
  -- As RecordType Inventor for Part Master, BOM_Header for bom assembly header note.                                   
                              
  -- 10/22/2018 : Vijay G : Check for existing notes if exist and remove the notes in edit mode                              
  --IF EXISTS(SELECT 1 FROM wmNotes w JOIN wmNoteRelationship wnr ON w.NoteID = wnr.FkNoteId WHERE RecordId= @AssyUniqKey AND RecordType ='BOM_Header')                              
  --BEGIN                              
  -- DELETE FROM wmNoteRelationship WHERE FkNoteId IN (SELECT NoteID FROM wmNotes w                               
  --             JOIN wmNoteRelationship wnr ON w.NoteID = wnr.FkNoteId                               
  --             WHERE RecordId= @AssyUniqKey AND RecordType ='BOM_Header')                              
                              
  -- DELETE FROM wmNotes WHERE NoteID IN (SELECT NoteID FROM wmNotes w                               
  --          JOIN wmNoteRelationship wnr ON w.NoteID = wnr.FkNoteId                               
  --          WHERE RecordId= @AssyUniqKey AND RecordType ='BOM_Header')                              
  --END  
  
  -- 12/24/2020 : Sachin B : Fix the Note Record Duplication Issue WMNotes BOM_Header and Inventor
  IF EXISTS(SELECT 1 FROM wmNotes w WHERE RecordId= @AssyUniqKey AND RecordType ='BOM_Header')                              
  BEGIN                              
   DELETE FROM wmNoteRelationship WHERE FkNoteId IN (SELECT NoteID FROM wmNotes w WHERE RecordId= @AssyUniqKey AND RecordType ='BOM_Header')                              
                              
   DELETE FROM wmNotes WHERE NoteID IN (SELECT NoteID FROM wmNotes w WHERE RecordId= @AssyUniqKey AND RecordType ='BOM_Header')                              
  END  
  
  IF EXISTS(SELECT 1 FROM wmNotes w WHERE RecordId= @AssyUniqKey AND RecordType ='Inventor')                              
  BEGIN                              
   DELETE FROM wmNoteRelationship WHERE FkNoteId IN (SELECT NoteID FROM wmNotes w WHERE RecordId= @AssyUniqKey AND RecordType ='Inventor')                              
                              
   DELETE FROM wmNotes WHERE NoteID IN (SELECT NoteID FROM wmNotes w WHERE RecordId= @AssyUniqKey AND RecordType ='Inventor')                              
  END                             
                              
  DECLARE @tempwmNote tWmNotes                                  
  INSERT INTO @tempwmNote                                  
  SELECT NULL AS NoteId,'' AS Description,NULL AS fkCreatedUserID, NULL AS ReminderDate, '' AS RecordId, '' AS RecordType, 0 AS NoteCategory,NULL AS ImagePath,NULL as OldNoteId 
  FROM @tempwmNote
                                    
  EXEC MnxNotesAdd @tempwmNote, @NoteId=@noteId,@Description=@Description,@CreatedUserId=@userId,@ReminderDate=null,@RecordId=@AssyUniqKey,                                  
  @RecordType='Inventor',@NoteCategory=2                                  
                                       
  DECLARE @tempNoteId uniqueidentifier = newid()                                  
  EXEC MnxNotesAdd @tempwmNote, @NoteId=@tempNoteId,@Description=@Description,@CreatedUserId=@userId,@ReminderDate=null,@RecordId=@AssyUniqKey,                                  
    @RecordType='BOM_Header',@NoteCategory=2  
	                                 
  -- 10/22/2018 : Vijay G : Check for existing notes if exist and then update WmNoteRelationship table record with new noteid                               
  IF EXISTS(SELECT 1 FROM wmNotes w JOIN wmNoteRelationship wnr ON w.NoteID = wnr.FkNoteId WHERE RecordId=@importId AND RecordType ='importBOMHeader')                              
  BEGIN                               
   UPDATE wmNoteRelationship SET FKNoteId = @tempNoteId                              
   WHERE FkNoteId IN (SELECT w.NoteID FROM wmNotes w                               
      JOIN wmNoteRelationship wnr ON w.NoteID = wnr.FkNoteId                               
        WHERE RecordId=@importId AND RecordType ='importBOMHeader')                              
                              
   DELETE FROM wmNotes WHERE RecordId=@importId AND RecordType ='importBOMHeader'                              
  END          
                              
  ----04/07/2020 Sachin B:Commeneted old code of inventor note and add new block                         
  ----/*03/08/2018 : Vijay G : Add a Invt note and bom item note for assembly component*/                                  
  --/*Add a inventor note for assembly component*/                                  
  --DECLARE  @tempwmNotes tWmNotes                                  
  --INSERT INTO @tempwmNotes (NoteId,Description,fkCreatedUserID,ReminderDate,RecordId,RecordType,NoteCategory,ImagePath,OldNoteID)                                   
  ---- 03/08/2018 : Vijay G : oldNoteId used for join to insert child note.                                     
  ---- 04/24/2018 : Vijay G : Get invNote fieldDefId from importBOMFieldDefinitions                      
  --SELECT NEWID() AS NoteId,Description,@userId AS CreatedUserID,null AS ReminderDate, uniq_key AS RecordId, 'Inventor' AS RecordType,                                  
  --2 AS NoteCategory,NULL AS ImagePath, NoteId AS OldNoteId FROM wmNotes wm                                       
  --  INNER JOIN importBOMFields b on wm.RecordId = CAST(b.rowId  AS VARCHAR(100))  AND fkImportId=@importId                                  
  --  AND fkFieldDefId=(SELECT fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='invNote') AND wm.recordType='importBOMPMNote'                                  
                                     
  --DECLARE  @tempwmNoteRel tWmNotes                                  
  --INSERT INTO @tempwmNoteRel (NoteId,Description,fkCreatedUserID,ReminderDate,RecordId,RecordType,NoteCategory,ImagePath,OldNoteId)                                  
  ---- 03/08/2018 : Vijay G : oldNoteId used for join to insert child note.                                     
  ---- 04/24/2018 : Vijay G : Get invNote fieldDefId from importBOMFieldDefinitions                                  
  --SELECT NEWID() AS NoteId,Note AS Description,@userId AS CreatedUserID,null AS ReminderDate, uniq_key AS RecordId, 'Inventor' AS RecordType,                                  
  --  2 AS NoteCategory,ImagePath, NoteId as OldNoteId FROM wmNoteRelationship rl                                        
  --  INNER JOIN wmNotes wm on rl.FkNoteId=wm.NoteID and wm.recordType='importBOMPMNote'                              
  --  INNER JOIN importBOMFields b on wm.RecordId = CAST(b.rowId  AS VARCHAR(100))  AND fkImportId=@importId                                  
  --  AND fkFieldDefId=(SELECT fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='invNote')                                  
                                  
  --IF EXISTS (SELECT 1 FROM @tempwmNotes) AND EXISTS ( Select 1 from @tempwmNoteRel)                                  
  --BEGIN                                  
  -- EXEC SpMnxNotesAdd @tempwmNotes,@tempwmNoteRel                                  
  --END          
          
--04/07/2020 Sachin B:Commeneted old code of inventor note and add new block         
DECLARE @PartsNoteRecords Table(uniqKey VARCHAR(10),note VARCHAR(MAX),rowID uniqueidentifier,noteRelationshipId uniqueidentifier)           

--09/24/2020 Sachin B: Part Master Note Data Copy Issue               
--INSERT INTO @PartsNoteRecords (uniqKey ,note ,rowID)            
--SELECT uniq_key ,adjusted,rowid 
--From importBOMFields 
--JOIN importBOMFieldDefinitions ON FieldDefId=fkFieldDefId           
--WHERE fieldName='invNote' AND fkImportId= @importId AND adjusted<>'' 
 
INSERT INTO @PartsNoteRecords (uniqKey ,note ,rowID,noteRelationshipId)
SELECT  uniq_key AS RecordId,Note AS Description, rowId,wmNoteRelationship.NoteRelationshipId
FROM wmNoteRelationship                  
INNER JOIN wmNotes wm on wmNoteRelationship.FkNoteId=wm.NoteID AND wm.recordType='importBOMPMNote'                                  
INNER JOIN importBOMFields b on wm.RecordId = CAST(b.rowId  AS VARCHAR(100))  AND fkImportId=@importId                                  
AND fkFieldDefId=(SELECT fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='invNote')         
   
DECLARE @recId VARCHAR(MAX),@note VARCHAR(MAX),@noteRowId UNIQUEIDENTIFIER,@idForNote VARCHAR(MAX),@noteRelationshipId UNIQUEIDENTIFIER         
                    
WHILE EXISTS(SELECT 1 FROM @PartsNoteRecords)          
BEGIN           
   SELECT TOP 1 @recId=uniqKey,@note=note,@noteRowId=rowID,@noteRelationshipId=noteRelationshipId FROM @PartsNoteRecords          
   IF EXISTS(SELECT 1 FROM wmNotes WHERE RecordId=@recId AND RecordType='Inventor')          
	BEGIN          
	   SELECT @idForNote=NoteID FROM wmNotes WHERE RecordId=@recId AND RecordType='Inventor'        
              
	   INSERT INTO WMNOTERELATIONSHIP(FkNoteId,Note,CreatedUserId,CreatedDate,ImagePath)                            
	   VALUES( @idForNote,@note,@userId,GETDATE(),null)                            
	END          
  ELSE          
  BEGIN          
   SET @idForNote=NEWID()           
   INSERT INTO wmNotes (NoteID,NoteCategory,RecordId,RecordType,NoteType,fkCreatedUserID,CreatedDate)                            
   VALUES(@idForNote,2,@recId,'Inventor','Note',@userId,GETDATE())                          
                              
   INSERT INTO WMNOTERELATIONSHIP(FkNoteId,Note,CreatedUserId,CreatedDate)                            
   VALUES( @idForNote,@note,@userId,GETDATE())                          
  END          
  DELETE FROM @PartsNoteRecords WHERE noteRelationshipId=@noteRelationshipId         
END                      
  
  /*Add a bom item note for assembly component*/                                  
  -- 04/24/2018 : Vijay G : Get bomNote fieldDefId from importBOMFieldDefinitions                                  
  DECLARE  @tempbomWmNotes tWmNotes                                  
  INSERT INTO @tempbomWmNotes (NoteId,Description,fkCreatedUserID,ReminderDate,RecordId,RecordType,NoteCategory,ImagePath,OldNoteID)                                      
  SELECT NEWID() AS NoteId,Description,@userId AS CreatedUserID,null AS ReminderDate, uniq_key AS RecordId, 'BOM_DET' AS RecordType,                                  
  2 AS NoteCategory,NULL AS ImagePath, NoteId AS OldNoteId 
  FROM wmNotes wm                                       
  INNER JOIN importBOMFields b on wm.RecordId = CAST(b.rowId  AS VARCHAR(100))  AND fkImportId=@importId                                  
  AND fkFieldDefId=(SELECT fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='bomNote') AND wm.recordType='importBOMItemNote'                                  
                                  
  DECLARE  @tempbomWmNoteRel tWmNotes                                  
  INSERT INTO @tempbomWmNoteRel (NoteId,Description,fkCreatedUserID,ReminderDate,RecordId,RecordType,NoteCategory,ImagePath,OldNoteId)                                  
  -- 03/08/2018 : Vijay G : oldNoteId used for join to insert child note.                                     
  -- 04/24/2018 : Vijay G : Get bomNote fieldDefId from importBOMFieldDefinitions                                  
  SELECT NEWID() AS NoteId,Note AS Description,@userId AS CreatedUserID,null AS ReminderDate, uniq_key AS RecordId, 'BOM_DET' AS RecordType,                                  
    2 AS NoteCategory,ImagePath, NoteId as OldNoteId 
   FROM wmNoteRelationship rl                 
   INNER JOIN wmNotes wm on rl.FkNoteId=wm.NoteID and wm.recordType='importBOMItemNote'                                  
   INNER JOIN importBOMFields b on wm.RecordId = CAST(b.rowId  AS VARCHAR(100))  AND fkImportId=@importId                                  
   AND fkFieldDefId=(SELECT fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='bomNote')                                  
                                  
  IF EXISTS (SELECT 1 FROM @tempbomWmNotes) AND EXISTS ( Select 1 from @tempbomWmNoteRel)                                  
  BEGIN                                  
   EXEC SpMnxNotesAdd @tempbomWmNotes,@tempbomWmNoteRel                                  
  END                                  
  -- 26/02/2020 Vijay G : Added avls with customer part which associated with its internal part                            
  DECLARE @mfgrMasterId VARCHAR(10)='',@ConsgUniqKey VARCHAR(10)='',@invUniqKey VARCHAR(10)=''                  
  SELECT  * INTO #tmpConsgignInventor FROM @tConsgignInventor                  
  WHILE(EXISTS(SELECT 1 FROM #tmpConsgignInventor))                  
  BEGIN                  
   SELECT TOP 1 @ConsgUniqKey= uniq_key,@invUniqKey=Int_uniq FROM #tmpConsgignInventor                  
   INSERT INTO InvtMPNLink([Uniq_key],Uniqmfgrhd,mfgrMasterId,orderpref,is_deleted)                   
   SELECT @ConsgUniqKey,dbo.fn_GenerateUniqueNumber(),mfgrMasterId,orderpref,1 FROM InvtMPNLink                   
   WHERE uniq_key=@invUniqKey AND  MfgrMasterId NOT IN (SELECT MfgrMasterId FROM InvtMPNLink WHERE uniq_key=@ConsgUniqKey)                  
   DELETE FROM #tmpConsgignInventor WHERE uniq_key=@ConsgUniqKey AND Int_uniq=@invUniqKey                  
  END  
  
  -- 10/08/2020 Sachin B Fix the Consign Part AVL Attach Issue
  DECLARE  @rowID UNIQUEIDENTIFIER,@UniqKey CHAR(10),@custPartNo CHAR(25),@custRev CHAR(8)
  SELECT  * INTO #tmpExistingConsgPart FROM @tInventor WHERE uniq_key<>'' and Custno<>'' and CustPartNo<>''
  WHILE(EXISTS(SELECT 1 FROM #tmpExistingConsgPart))                  
  BEGIN                  
    
	SELECT TOP 1 @UniqKey= uniq_key,@custNo=Custno,@custPartNo =CustPartNo,@custRev=CustRev,@rowID =rowId FROM #tmpExistingConsgPart  
    
	SELECT TOP 1 @ConsgUniqKey = UNIQ_KEY  from INVENTOR where int_uniq =@UniqKey and CUSTNO =@custNo AND CUSTPARTNO= @custPartNo
	
	DELETE FROM @GenrMaster

	--select * from @tAvlDynamic
   --01/13/21 YS added distinct in the source part of the Merge to avoid multiple records result in the source and fail to merge  
	MERGE MfgrMaster T                                  
 USING (SELECT distinct PartMfgr, Mfgr_pt_no from @tAvlDynamic WHERE rowid =@rowID AND bom=1 AND comments='exist & connected')  as S                                    
	ON (s.PartMfgr=T.PartMfgr AND S.Mfgr_pt_no=T.Mfgr_pt_no)                                  
	WHEN MATCHED  THEN UPDATE SET T.is_deleted=0                                  
	WHEN NOT MATCHED BY TARGET THEN                                   
	INSERT (Partmfgr,mfgr_pt_no,MatlType) VALUES (CAST(rtrim(S.PartMfgr) as char(8)),S.mfgr_pt_no,'Unk')                                
	OUTPUT CAST(rtrim(Inserted.PartMfgr) as char(8)),Inserted.mfgr_pt_no,Inserted.MfgrmasterId into @GenrMaster; 

	--select * from @GenrMaster
    
	DELETE FROM @KeyUpdated
		
	MERGE InvtmpnLink As T                                  
	USING                          
	(                          
		SELECT DISTINCT CASE WHEN  t.custuniq='' THEN @ConsgUniqKey ELSE t.custuniq END AS Uniq_key,
		M.Mfgr_pt_no,M.PartMfgr,t.Uniqmfgrhd,m.mfgrmasterid,t.preference                                  
		FROM @tAvlDynamic T                           
		INNER JOIN @GenrMaster M                  
		ON m.partmfgr=CAST(rtrim(t.PartMfgr) as char(8)) and m.mfgr_pt_no=SUBSTRING(t.Mfgr_pt_no,1,30)  
		WHERE rowid =@rowID AND bom=1 AND comments='exist & connected'                       
	) as S 
	ON (S.Uniq_key=T.Uniq_key AND S.mfgrmasterid=T.mfgrmasterid )                                
	WHEN MATCHED THEN UPDATE SET T.IS_DELETED=0                                  
	WHEN NOT MATCHED BY TARGET THEN                           
	INSERT ([Uniq_key],mfgrmasterid,Uniqmfgrhd,orderpref) 
	VALUES (S.Uniq_key,S.MfgrMasterId,CASE WHEN S.UniqMfgrhd='' THEN dbo.fn_GenerateUniqueNumber() ELSE S.UniqMfgrhd END,ISNULL(preference,'99'))                                 
	OUTPUT Inserted.Uniq_key,Inserted.MfgrMasterId,Inserted.UniqMfgrhd into @KeyUpdated;                  
   
	MERGE InvtMfgr As T                                  
	USING (SELECT distinct Uniq_key,Uniqmfgrhd,@defaultUniqWh AS UniqWh,CAST(1 as bit) Netable FROM @KeyUpdated) as S                                  
	ON (S.Uniq_key=T.Uniq_key AND S.Uniqmfgrhd=T.UniqMfgrhd )                                  
	WHEN MATCHED THEN UPDATE SET T.IS_DELETED=0,T.Netable=1                                  
	WHEN NOT MATCHED BY TARGET THEN                                   
	INSERT ([Uniq_key],Uniqmfgrhd,UniqWh,W_key,Netable) VALUES (S.Uniq_key,S.Uniqmfgrhd,S.UniqWh,dbo.fn_GenerateUniqueNumber(),S.Netable) ; 

    DELETE FROM #tmpExistingConsgPart WHERE uniq_key=@UniqKey AND CUSTNO =@custNo AND CUSTPARTNO= @custPartNo AND rowId = @rowID                
  END
                                       
 END TRY                                  
 BEGIN CATCH                                   
  -- 12/09/13 YS check fr errors prior to proceeding                                  
  SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                                  
  ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                                  
  ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                                  
 ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                                  
  ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                                  
  IF @@TRANCOUNT>0                                  
  ROLLBACK TRANSACTION                                   
  -- 12/10/13 YS inser into importBOMErrors                                  
  --12/06/17 YS change error handling to use variable                                  
  INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg,errDate)                                  
  SELECT DISTINCT @importId,@ERRORNUMBER                                  
  ,@ERRORSEVERITY                                   
  ,@ERRORPROCEDURE                                  
  ,@ERRORLINE                                   
  ,@ERRORMESSAGE                                   
  ,GETDATE()                                  
  return -1                                                      
 END CATCH                                  
END