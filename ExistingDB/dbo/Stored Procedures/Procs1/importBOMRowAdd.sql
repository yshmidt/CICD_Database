  
-- =============================================  
-- Author:  David Sharp  
-- Create date: 4/18/2012  
-- Description: add import detail  
 --03/06/15 ys added make_buy to field definition and importbom table type  
 -- 09/17/15 ys changed @Rev size to varchar(8)  
 --10/15/18 ys modified partno to be 35 char not 23  
 --05/15/2019 Vijay Modofy the Order of @partno Partmerter use it before the Default value parameter  
 --05/15/2019 Vijay G Added two new row as mtc and serial   
 --01/16/2020 Vijay G Replace name of columns/variable sid with mtc  
 -- [importBOMRowAdd] 'a61af1a7-9c4c-4865-88c5-bec4a8b19b24','2A0B10AB-0588-E111-B197-1016C92052BC',''  
-- =============================================  
CREATE PROCEDURE [dbo].[importBOMRowAdd]    
 -- Add the parameters for the stored procedure here  
  --05/15/2019 Vijay Modofy the Order of @partno Partmerter use it before the Default value parameter  
 @importId uniqueidentifier, @rowId uniqueidentifier,@partno varchar(35), @uniq_key varchar(10)='', @itemno varchar(4)='', @used varchar(1)='',  
 --10/15/18 YS part_no is 35 characters not 23  
 @partSource varchar(10)='', @qty varchar(10)=0, @custPartNo varchar(35)='', @crev varchar(8)='', @descript varchar(45)='',   
 @u_of_m varchar(10)='', @partClass varchar(10)='', @partType varchar(10)='', @warehouse varchar(10)='',  
 --10/15/18 YS part_no is 35 characters not 23    
 @rev varchar(8)='', @wc varchar(10)='', @standardCost varchar(10)=0, @bomNote varchar(MAX)='', @invNote varchar(MAX)='',  
 --03/06/15 ys added make_buy  
 @make_buy varchar(1)='0' ,  
  --05/15/2019 Vijay G Added two new row as mtc and serial  
 --01/16/2020 Vijay G Replace name of columns/variable sid with mtc    
 @mtc bit = 0, @serial bit = 0    
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
    -- Get highest current itemno for the importId and prepare for auto increment if needed.  
    DECLARE @nextItem int = 1  
      
 ---!!! YS 03/06/15 find which value to use and change the code  
 SELECT @nextItem = CAST(MAX(adjusted)AS INT)+1 FROM importBOMFields WHERE fkImportId = @importId AND fkFieldDefId = '2a0b10ab-0588-e111-b197-1016c92052bc'  
      
    --Give the items the default value if not provided  
    IF @itemno = ''  SELECT @itemno = CASE WHEN [default]=''THEN CAST(@nextItem AS varchar(4)) ELSE [default] END FROM importBOMFieldDefinitions WHERE fieldName = 'itemNo'  
 IF @used = ''  SELECT @used=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'used'  
 IF @partSource = '' SELECT @partSource=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'partSource'  
 IF @partClass = '' SELECT @partClass=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'partClass'  
 IF @qty = ''  SELECT @qty=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'qty'  
 IF @custPartNo = '' SELECT @custPartNo=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'custPartNo'  
 IF @crev = ''  SELECT @crev=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'crev'  
 IF @descript = '' SELECT @descript=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'descript'  
 IF @u_of_m = ''  SELECT @u_of_m=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'u_of_m'  
 IF @warehouse = '' SELECT @warehouse=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'warehouse'  
 IF @standardCost = '' SELECT @standardCost=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'standardCost'  
 IF @wc = ''   SELECT @wc=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'workCenter'  
 IF @partno = ''  SELECT @partno=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'partno'  
 IF @rev = ''  SELECT @rev=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'rev'  
  --03/06/15 ys copy and paste not always good  
 --IF @bomNote = '' SELECT @partno=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'bomNote'  
 --IF @invNote = '' SELECT @rev=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'invNote'  
 IF @bomNote = '' SELECT @bomNote=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'bomNote'  
 IF @invNote = '' SELECT @invNote=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'invNote'  
  --05/15/2019 Vijay G Added two new row as mtc and serial     
  --01/16/2020 Vijay G Replace name of columns/variable sid with mtc  
 IF @mtc = '' SELECT @mtc=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'MTC'    
 IF @serial = '' SELECT @serial=[default] FROM importBOMFieldDefinitions WHERE fieldName = 'serial'  
  --03/06/15 ys added make_buy to field definition and importbom table type  
 IF @make_buy ='1' and @partSource <> 'MAKE' SELECT @make_buy=0  
      
    --03/06/15 ys added make_buy to field definition and importbom table type  
    --01/16/2020 Vijay G Replace name of columns/variable sid with mtc  
    DECLARE @iTable importBOM  
    INSERT INTO @iTable (rowId,uniq_key,itemno,used,partSource,make_buy,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partno,rev,workCenter,standardCost,importId,bomNote,invNote,[mtc],serial)    
  SELECT @rowId,@uniq_key,RTRIM(@itemno),RTRIM(@used),RTRIM(@partSource),RTRIM(@make_buy),RTRIM(@qty),RTRIM(@custPartNo),RTRIM(@crev),RTRIM(@descript),RTRIM(@u_of_m),  
    RTRIM(@partClass),RTRIM(@partType),RTRIM(@warehouse),RTRIM(@partno),RTRIM(@rev),RTRIM(@wc),RTRIM(@standardCost),@importId,RTRIM(@bomNote),RTRIM(@invNote),RTRIM(@mtc),RTRIM(@serial)    
   
 -- Unpivot the table and insert  
 INSERT INTO importBOMFields (fkImportId,rowId,fkFieldDefId,uniq_key,original,adjusted)  
 SELECT u.importId,u.rowId,fd.fieldDefId,u.uniq_key,u.adjusted,u.adjusted  
  FROM(  
   --01/16/2020 Vijay G Replace name of columns/variable sid with mtc  
   SELECT importId,rowId,[uniq_key],[itemno],[used],[partSource],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],[standardCost],[workCenter],[partno],[rev],[bomNote],[invNote],[mtc],[serial]    
   FROM @iTable)p  
  UNPIVOT  
   (adjusted FOR fieldName IN   
    ([itemno],[used],[partSource],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],[standardCost],[workCenter],[partno],[rev],[bomNote],[invNote],[mtc],[serial])    
  ) AS u INNER JOIN importBOMFieldDefinitions fd ON fd.fieldName = u.fieldName  
      
 --INSERT INTO importBOMFields (fkImportId,rowId,fkFieldDefId,original,adjusted)  
 --SELECT @importId,@rowId,fieldDefId,@itemno,CASE WHEN @itemno = '' THEN CASE WHEN [default] = '' THEN CAST(@nextItem AS varchar(4)) ELSE [default] END ELSE RTRIM(@itemno) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'itemNo'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@used,CASE WHEN @used = '' THEN [default] ELSE RTRIM(@used) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'used'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@partSource,CASE WHEN @partSource = '' THEN [default] ELSE RTRIM(@partSource) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'partSource'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@partClass,CASE WHEN @partClass = '' THEN [default] ELSE RTRIM(@partClass) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'partClass'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@partType,CASE WHEN @partType = '' THEN [default] ELSE RTRIM(@partType) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'partType'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@qty,CASE WHEN @qty = '' THEN [default] ELSE @qty END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'qty'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@custPartNo,CASE WHEN @custPartNo = '' THEN [default] ELSE RTRIM(@custPartNo) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'custPartNo'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@crev,CASE WHEN @crev = '' THEN [default] ELSE RTRIM(@crev) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'crev'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@descript,CASE WHEN @descript = '' THEN [default] ELSE RTRIM(@descript) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'descript'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@u_of_m,CASE WHEN @u_of_m = '' THEN [default] ELSE RTRIM(@u_of_m) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'u_of_m'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@warehouse,CASE WHEN @warehouse = '' THEN [default] ELSE RTRIM(@warehouse) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'warehouse'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@standardCost,CASE WHEN @standardCost = '' THEN [default] ELSE RTRIM(@standardCost) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'standardCost'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@wc,CASE WHEN @wc = '' THEN [default] ELSE RTRIM(@wc) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'workCenter'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@partno,CASE WHEN @partno = '' THEN [default] ELSE RTRIM(@partno) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'partno'  
 --UNION ALL  
 --SELECT @importId,@rowId,fieldDefId,@rev,CASE WHEN @rev = '' THEN [default] ELSE RTRIM(@rev) END  
 -- FROM importBOMFieldDefinitions WHERE fieldName = 'rev'  
END