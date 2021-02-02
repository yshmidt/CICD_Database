
-- =============================================
-- Author:		<Debbie>
-- Create date: <07/07/2011>
-- Description:	<created for reports icrpt10.rpt>
-- Modified:  01/15/2014 DRP:  added the @userid parameter for WebManex
--			03/05/2015 DRP:  Added the /*MFGR LIST*/
-- 03/29/16 YS removed invtmfhd table and added to manex_a_design database
--			08/04/2016 DRP:  needed to update the <<and 1= case WHEN DBO.SUPPORT.TEXT IN (SELECT MFGR FROM @Mfgr) THEN 1 ELSE 0  END >> to be <<and 1= case WHEN DBO.SUPPORT.TEXT2 IN (SELECT MFGR FROM @Mfgr) THEN 1 ELSE 0  END >> in order to work with the parameter properly. 
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptInvtPartByMfgrWM] 
--declare
	@lcMfgr as varchar (max) = 'All'
	,@userId uniqueidentifier=null

AS
BEGIN


/*MFGR LIST*/
	DECLARE  @tMfgr table(mfgr char(20),mfgrname char(35))
		DECLARE @Mfgr TABLE (mfgr char(20))
		-- get list of customers for @userid with access
		INSERT INTO @tMfgr select text2,text from support where fieldname = 'PARTMFGR' order by text

		IF @lcMfgr is not null and @lcMfgr <>'' and @lcMfgr<>'All'
			insert into @Mfgr select * from dbo.[fn_simpleVarcharlistToTable](@lcMfgr,',')
					where CAST (id as CHAR(10)) in (select mfgr from @tMfgr)
		ELSE

		IF  @lcMfgr='All'	
		BEGIN
			INSERT INTO @Mfgr SELECT mfgr FROM @tMfgr
		END	

/*SELECT STATEMENT*/
select		UNIQ_KEY, PART_NO, REV, PART_SOURC, CUSTNAME, PART_CLASS, PART_TYPE, DESCRIPT, PARTMFGR, MFGRNAME, MFGR_PT_NO, 
			MATLTYPE, Buyer, UNIQMFGRHD, SUM(QTY_OH) AS Qty_oh
from 
(
-- 03/29/16 YS removed invtmfhd 
-- 07/16/18 VL changed custname from char(35) to char(50)
Select		dbo.INVENTOR.UNIQ_KEY, CASE WHEN PART_SOURC = 'CONSG' THEN CUSTPARTNO ELSE PART_NO END AS PART_NO, 
			CASE WHEN PART_SOURC = 'CONSG' THEN CUSTREV ELSE REVISION END AS REV, dbo.INVENTOR.PART_SOURC, ISNULL(dbo.CUSTOMER.CUSTNAME, 
			CAST(' ' AS CHAR(50))) AS CUSTNAME, dbo.INVENTOR.PART_CLASS, dbo.INVENTOR.PART_TYPE, dbo.INVENTOR.DESCRIPT,M.PARTMFGR, 
			dbo.SUPPORT.TEXT AS MFGRNAME, M.MFGR_PT_NO, M.MATLTYPE, dbo.INVENTOR.BUYER_TYPE AS Buyer, 
			dbo.INVTMFGR.UNIQMFGRHD, dbo.INVTMFGR.QTY_OH
FROM		dbo.INVENTOR LEFT OUTER JOIN
			dbo.CUSTOMER ON dbo.INVENTOR.CUSTNO = dbo.CUSTOMER.CUSTNO LEFT OUTER JOIN
			-- 03/29/16 YS removed invtmfhd 
			--dbo.INVTMFHD ON dbo.INVENTOR.UNIQ_KEY = dbo.INVTMFHD.UNIQ_KEY INNER JOIN
			Invtmpnlink L on Inventor.uniq_key=L.Uniq_key LEFT OUTER JOIN 
			MfgrMaster M on l.mfgrmasterid=m.mfgrmasterid LEFT OUTER JOIN 
			dbo.SUPPORT ON dbo.SUPPORT.TEXT2 = M.PARTMFGR LEFT OUTER JOIN
			dbo.INVTMFGR ON L.UNIQMFGRHD = dbo.INVTMFGR.UNIQMFGRHD

WHERE		L.IS_DELETED = 0 and m.is_deleted=0
			--and dbo.SUPPORT.TEXT LIKE CASE WHEN @lcMfgr = '*' then '%' else @lcMfgr+'%' end	--03/05/2015 DRP:  replaced with the below when adding the Mfgr List
			-- 03/29/16 YS change this where to more readable version
			--and 1= case WHEN DBO.SUPPORT.TEXT IN (SELECT MFGR FROM @Mfgr) THEN 1 ELSE 0  END 
			and exists (select 1 from @mfgr t where support.text2=t.mfgr) --08/04/2016 DRP:  changed the support.text=t.mfgr to be support.text2=t.mfgr

) t1
GROUP BY	UNIQ_KEY, PART_NO, REV, PART_SOURC, CUSTNAME, PART_CLASS, PART_TYPE, DESCRIPT, PARTMFGR, MFGRNAME, MFGR_PT_NO, MATLTYPE, Buyer, UNIQMFGRHD

ORDER BY	mfgrname, mfgr_pt_no

END