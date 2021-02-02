-- =============================================
-- Author:		<Bill Blake>
-- Create date: <04/05/2010,>
-- Description:	<Select all records from ApRecur table. Use for the transfer to AP>
-- Modification:
-- 06/23/15 VL added FC fields
-- 12/07/16 VL added PR fields
-- =============================================
CREATE PROCEDURE [dbo].[ApRecurAllView]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Aprecur.uniqrecur, Aprecur.maxpmts, Aprecur.no_invcd,
  Aprecur.totamt_gen, Aprecur.lastpmtgen, Aprecur.is_closed,
  Aprecur.invamount, Aprecur.aptype, Aprecur.totamt_genFC, Aprecur.invamountFC,
  Aprecur.totamt_genPR, Aprecur.invamountPR
 FROM 
     aprecur
END