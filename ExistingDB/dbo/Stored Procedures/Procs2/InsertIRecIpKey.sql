-- =============================================
-- Author:	Sachin b
-- Create date: 06/07/2016
-- Description:	this procedure will be called from the SF module while manual transfer put entry on the irecipkey
-- 02/14/2020 Rajendra K : Changed type from decimal to decimal(12,2) 
-- =============================================
CREATE Procedure [dbo].[InsertIRecIpKey] 
  @invtrec_no char(10),
  @qtyPerPackage decimal(12,2),-- 02/14/2020 Rajendra K : Changed type from decimal to decimal(12,2) 
  @qtyReceived decimal(12,2),
  @ipkeyunique char(10)
AS
BEGIN
SET NoCount ON;
INSERT INTO  [dbo].[iRecIpKey]
			([iRecIpKeyUnique]
			,[invtrec_no]
			,[qtyPerPackage]
			,[qtyReceived]
			,[ipkeyunique]) 
			values(
			dbo.fn_GenerateUniqueNumber(),
			@invtrec_no,
			@qtyPerPackage,
			@qtyReceived,
			@ipkeyunique
			)
END