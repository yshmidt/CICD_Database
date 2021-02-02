-- =============================================
-- Author:		<Debbie> 
-- Create date: <05/26/2015>
-- Description:	compiled for the Inventory and AVL Material Type Validation
-- Reports:     icrptmt2
-- Modified:	05/26/2015 DRP:  When creating I time tested VFP against this procedure against one of the largest datasets and VFP = 21 Minutes and this SQL Procedure = 5 Minutes
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptInvtAvlMatlTypeValid] 

@userId uniqueidentifier=null 

as 
Begin

; with zMatlType as 
(
SELECT Uniq_key, Part_no,Revision,Part_class,Part_type,Descript,Part_sourc,Buyer_type as Buyer,CustPartno,CustRev ,isnull(CustName,SPACE(50)) AS CustName,Matltype, dbo.fn_GetOneInvMatlType(Uniq_key) AS CalcMatltype
FROM Inventor LEFT OUTER JOIN Customer ON Inventor.Custno=Customer.CustNo
where inventor.STATUS = 'Active'
)
select * from zMatlType where matltype <> '' and  MATLTYPE <> CalcMatltype order by custname,part_no,revision

end