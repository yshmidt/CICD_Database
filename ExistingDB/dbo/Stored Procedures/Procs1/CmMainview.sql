-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Credit memo information
-- Modified: 04/01/14 YS add custpo from somain
--			 03/05/15 VL added all FC fields
--			 10/31/16 VL added PR fields
-- =============================================

CREATE PROCEDURE [dbo].[CmMainview]
	-- Add the parameters for the stored procedure here
@gcCmUnique as Char(10) = ' '

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Sname, CmDate, Cmemono, InvDate, CMMAIN.InvoiceNo, PacklistNo, CMMAIN.SoNo, CmMain.CustNo, cmMain.SaveInit,
		linkAdd, Frt_txble, Cm_Frt, Cm_Frt_Tax, CmStdPrice, CmTotExten, CmStd_Tax, tottaxe,
		CmTotal, CmReason, Cm_Dupl, CmType, InvTotal, Is_Rel_GL, Is_CmPost, Is_CMPrn, CmMain.Terms,
		CmMain.BLinkAdd, Prnt_Inv,Cog_Gl_Nbr, Frt_Gl_no, Fc_Gl_no, Disc_Gl_no, AR_GL_no, Printed,
		Inv_Dupl, cmmain.Is_Rma, RecvDate, CMMAIN.FOB, CMMAIN.ShipVia, CMMAIN.ShipCharge, DsctAmt, cStatus,
		cAppvName, tAppvDtTime, dSaveDate, lSalesTaxOnly, lFreightOnly, pTax, sTax,TotExten,CmUnique,lFreightTaxOnly, cRmaNo,RecVer,
		cmmain.Attention, WayBill, Rmar_foot,isnull(somain.PONO,space(20)) as custPO, CM_FRTFC, CM_FRT_TAXFC, CMTOTEXTENFC, TOTTAXEFC,
		CMTOTALFC, INVTOTALFC, TOTEXTENFC, DSCTAMTFC, PTAXFC,STAXFC, Cmmain.FcUsed_uniq, Cmmain.Fchist_key, 
		CM_FRTPR, CM_FRT_TAXPR, CMTOTEXTENPR, TOTTAXEPR, CMTOTALPR, INVTOTALPR, TOTEXTENPR, DSCTAMTPR, PTAXPR,STAXPR, Cmmain.PRFcused_Uniq, Cmmain.FUNCFCUSED_UNIQ
	from CmMain inner join Customer on CMMAIN.CUSTNO=customer.CUSTNO 
	left outer join somain on CMMAIN.sono=somain.sono
	where cmUnique = @gcCmUnique

END 