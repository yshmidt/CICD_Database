-- =============================================
-- Author:	Sachin b
-- Create date: 06/16/2016
-- Description:	this procedure will be called from the SF module while manual transfer put entry on the issueIpkey
-- =============================================
Create Procedure [dbo].[InsertIssueIpKey] 
  @Invtisu_no char(10),
  @Qtyissued decimal,
  @Ipkeyunique char(10)
AS
BEGIN
SET NoCount ON;
INSERT INTO  [dbo].[issueipkey]
			([issueIpKeyUnique]
			,[invtisu_no]
			,[qtyissued]
			,[ipkeyunique]) 
			values(
			dbo.fn_GenerateUniqueNumber(),
			@Invtisu_no,
			@Qtyissued,
			@Ipkeyunique
			)
END