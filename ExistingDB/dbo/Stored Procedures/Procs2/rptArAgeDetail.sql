		-- =============================================
		-- Author:		<Debbie>
		-- Create date: <11/29/2012>
		-- Description:	<Was created and used on aragedet.rpt ~ aragesum.rpt>
		-- Modified:	11/29/2012 DRP:  This stored procedure repaces the rptArAgeView.  We needed to have the Customer Parameter added into the stored procedure itself and a view does not allow it. 
		-- =============================================
		create PROCEDURE [dbo].[rptArAgeDetail]

		@lcCust as varchar (35) = '*'

 , @userId uniqueidentifier=null 
as
begin

SELECT     TOP (100) PERCENT dbo.ACCTSREC.CUSTNO,dbo.customer.custname, dbo.ACCTSREC.INVNO,somain.PONO, dbo.ACCTSREC.INVDATE, dbo.ACCTSREC.DUE_DATE, CASE WHEN LEFT(dbo.acctsrec.invno, 4) 
                      = 'PPay' THEN 000000000.00 ELSE dbo.ACCTSREC.INVTOTAL END AS InvTotal, dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS AS BalAmt,customer.PHONE,CUSTOMER.TERMS ,customer.CREDLIMIT
                      ,a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, 
                      a4.nEnd AS R4End,micssys.LIC_NAME
FROM         dbo.ACCTSREC INNER JOIN
                      dbo.CUSTOMER ON dbo.ACCTSREC.CUSTNO = dbo.CUSTOMER.CUSTNO left outer join 
                      plmain on dbo.ACCTSREC.CUSTNO = dbo.plmain.CUSTNO and dbo.acctsrec.INVNO = dbo.plmain.INVOICENO left outer join
                      somain on plmain.SONO = somain.sono  cross JOIN
                      dbo.AgingRangeSetup AS a2 CROSS JOIN
                      dbo.AgingRangeSetup AS a3 CROSS JOIN
                      dbo.AgingRangeSetup AS a4 CROSS JOIN
                      dbo.AgingRangeSetup AS a1 cross join
                      MICSSYS
WHERE     CUSTNAME like case when @lcCust ='*' then '%' else @lcCust + '%' end
		  and(dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS <> 0) AND (a1.cType = 'AR') AND (a1.nRange = 1) AND (a2.cType = 'AR') AND (a2.nRange = 2) AND 
                      (a3.cType = 'AR') AND (a3.nRange = 3) AND (a4.cType = 'AR') AND (a4.nRange = 4)
ORDER BY dbo.CUSTOMER.CUSTNAME
end