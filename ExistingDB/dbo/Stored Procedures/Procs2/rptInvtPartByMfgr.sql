
-- =============================================
-- Author:		<Debbie>
-- Create date: <07/07/2011>
-- Description:	<created for reports icrpt10.rpt>
-- Modified:  01/15/2014 DRP:  added the @userid parameter for WebManex
-- 10/10/14 YS replaced invtmfhd with 2 new tables
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptInvtPartByMfgr] 

	@lcMfgr as varchar (8) = '*'
	,@userId uniqueidentifier=null

AS
BEGIN

select		UNIQ_KEY, PART_NO, REV, PART_SOURC, CUSTNAME, PART_CLASS, PART_TYPE, DESCRIPT, PARTMFGR, MFGRNAME, MFGR_PT_NO, 
			MATLTYPE, Buyer, UNIQMFGRHD, SUM(QTY_OH) AS Qty_oh
from 
(
-- 07/16/18 VL changed custname from char(35) to char(50)
Select		dbo.INVENTOR.UNIQ_KEY, CASE WHEN PART_SOURC = 'CONSG' THEN CUSTPARTNO ELSE PART_NO END AS PART_NO, 
			CASE WHEN PART_SOURC = 'CONSG' THEN CUSTREV ELSE REVISION END AS REV, dbo.INVENTOR.PART_SOURC, ISNULL(dbo.CUSTOMER.CUSTNAME, 
			CAST(' ' AS CHAR(50))) AS CUSTNAME, dbo.INVENTOR.PART_CLASS, dbo.INVENTOR.PART_TYPE, dbo.INVENTOR.DESCRIPT, ML.PARTMFGR, 
			dbo.SUPPORT.TEXT AS MFGRNAME, ML.MFGR_PT_NO, ML.MATLTYPE, dbo.INVENTOR.BUYER_TYPE AS Buyer, 
			dbo.INVTMFGR.UNIQMFGRHD, dbo.INVTMFGR.QTY_OH
FROM		dbo.INVENTOR LEFT OUTER JOIN
			dbo.CUSTOMER ON dbo.INVENTOR.CUSTNO = dbo.CUSTOMER.CUSTNO 
			--- 10/10/14 YS replace invtmfhd table with 2 new tables
			--dbo.INVTMFHD ON dbo.INVENTOR.UNIQ_KEY = dbo.INVTMFHD.UNIQ_KEY INNER JOIN
			OUTER APPLY 
			-- 10/10/14 YS replaced invtmfhd with 2 new tables
			(SELECT L.Uniq_key,M.Partmfgr,M.Mfgr_pt_no,m.mfgrmasterid,m.MATLTYPE,l.uniqmfgrhd FROM 
			InvtMPNLink L INNER JOIN MfgrMaster M ON l.Mfgrmasterid=m.mfgrmasterid 
				where Inventor.Uniq_key=L.Uniq_key AND M.is_deleted=0 and l.is_deleted=0) ML
			LEFT OUTER JOIN
			dbo.SUPPORT ON ML.PartMfgr=RTRIM(SUPPORT.TEXT2) LEFT OUTER JOIN
			dbo.INVTMFGR ON ML.UNIQMFGRHD = InvtMfgr.UNIQMFGRHD
			-- 10/10/14 YS replaced invtmfhd with 2 new tables
WHERE		(INVTMFGR.IS_DELETED = 0 or Invtmfgr.is_deleted is null)
			and dbo.SUPPORT.TEXT LIKE CASE WHEN @lcMfgr = '*' then '%' else @lcMfgr+'%' end

) t1
GROUP BY	UNIQ_KEY, PART_NO, REV, PART_SOURC, CUSTNAME, PART_CLASS, PART_TYPE, DESCRIPT, PARTMFGR, MFGRNAME, MFGR_PT_NO, MATLTYPE, Buyer, UNIQMFGRHD

ORDER BY	mfgrname, mfgr_pt_no

END