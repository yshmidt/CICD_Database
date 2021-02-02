--   03/10/15 DS Added make_buy field      
CREATE PROCEDURE [dbo].[importBOMRowUpdateAll]       
  -- Add the parameters for the stored procedure here      
  @iTable importBOM READONLY      
 AS      
 BEGIN      
  -- SET NOCOUNT ON added to prevent extra result sets from      
  -- interfering with SELECT statements.      
  SET NOCOUNT ON;      
      
  -- This will update a adjusted fields very quickly...however, it will NOT update the status, validation, or message fields.      
  UPDATE i      
  SET i.adjusted = u.adjusted,i.uniq_key=u.uniq_key      
  FROM(      
   SELECT importId,rowId,[uniq_key],[itemno],[used],[partSource],[make_buy],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],      
     [standardCost],[workCenter],[partno],[rev]      
   FROM @iTable)p      
  UNPIVOT      
   (adjusted FOR fieldName IN       
    ([itemno],[used],[partSource],[make_buy],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],[standardCost],[workCenter],[partno],[rev])      
  ) AS u       
   INNER JOIN importBOMFieldDefinitions fd ON fd.fieldName = u.fieldName       
   INNER JOIN importBOMFields i ON i.rowId=u.rowId AND i.fkFieldDefId=fd.fieldDefId AND i.fkImportId=u.importId      
 END