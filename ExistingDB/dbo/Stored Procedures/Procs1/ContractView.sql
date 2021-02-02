-- =============================================
-- Author:		???
-- Create date: ??
-- Description:	
-- Modified: 02/02/17 YS contract tables were updated
-- 04/03/17 VL added functional currency fields
-- =============================================
CREATE PROCEDURE [dbo].[ContractView] @gUniqSupno AS Char(10) = ' '
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT h.Contr_no, h.Quote_no, c.Contr_uniq, C.Uniq_key, h.UniqSupNo, QtyLimit, Startdate, h.Expiredate, 
		inventor.Part_class, inventor.Part_type, inventor.Part_no, inventor.Revision, inventor.Descript, inventor.U_of_meas, inventor.Pur_uofm, 
		supinfo.Supname, PrimSupplier, h.contractNote,
		h.Fcused_Uniq, h.Fchist_key, supinfo.SUPID,
		-- 04/03/17 VL added functional currency fields
		H.PRFcused_uniq, H.FuncFcused_uniq   
	---02/02/17 YS contract tables were updated
	FROM ContractHeader H INNER JOIN  Contract C ON h.contractH_unique=c.contractH_unique
	inner join Supinfo on h.uniqsupno=supinfo.UNIQSUPNO
	inner join Inventor on inventor.UNIQ_KEY=c.UNIQ_KEY 
 WHERE (Part_sourc = 'BUY'
   OR Part_sourc = 'MAKE')
   AND h.UniqSupno = @gUniqSupno

END