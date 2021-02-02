CREATE PROCEDURE [dbo].[InvtPropertyValueUpdate]
(
@p_invtUpdate dbo.BulkInvtUpdate READONLY
)
AS
BEGIN

SET NOCOUNT ON;	
Update ImportBulkInvtFields 
                         SET Original = p.Value
						 From ImportBulkInvtFields i INNER JOIN @p_invtUpdate p on  p.[RowId] = i.RowId and p.FieldDefId = i.FkFieldDefId
						    
  
END