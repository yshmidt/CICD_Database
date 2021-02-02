-- =============================================
-- Author:	Sachin B
-- Create date: 10/06/2017
-- Description:	this procedure will be called from the SF module and update ipkey in invtSer  
-- =============================================
CREATE PROCEDURE [dbo].[UpdateIpKeyForSerialItem]
@tSerailIssue tSerialsIssue2Kit READONLY,
@IpKeyUnique char(10) = ''

AS
BEGIN

SET NOCOUNT ON;

  UPDATE ser
  SET ser.IPKEYUNIQUE = @IpKeyUnique
  FROM dbo.INVTSER AS ser
  INNER JOIN @tSerailIssue AS serialIssue
  ON ser.SERIALUNIQ = serialIssue.SERIALUNIQ

END