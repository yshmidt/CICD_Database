-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <07/13/11 My brother's BD>
-- Description:	<View for auti distribution (details)>
-- Modification:
-- 05/24/17 VL separate FC and non-FC and added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[GLADDETVIEW]
	-- Add the parameters for the stored procedure here
	@pcglahdrkey as char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Gladdet.gl_nbr, Gl_nbrs.gl_descr, Gladdet.debit, Gladdet.credit,
	-- 03/27/17 VL added functional currency
  Gladdet.debitFC, Gladdet.creditFC, Gladdet.debitPR, Gladdet.creditPR,
  Gladdet.gladetkey, Gladdet.fkglahdr
 FROM gladdet 
    LEFT OUTER JOIN gl_nbrs 
   ON  Gladdet.gl_nbr = Gl_nbrs.gl_nbr
 WHERE  Gladdet.fkglahdr = @pcglahdrkey
END