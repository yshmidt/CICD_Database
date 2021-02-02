

-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <05/13/10>
-- Description:	<This Proceudre is used by the frmpartxreffind>
-- Modified: 10/10/14 YS removed invtmfhd and replaced with 2 new tables
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int
-- 07/16/18 VL changed supname from char(30) to char(50)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[XrefInvtSearchBySupplPaRTNo]
	-- Add the parameters for the stored procedure here
	@lcsuplpartno char(30)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--DECLARE @lcmd varchar(500)
	--DECLARE @ZIntPart TABLE (Part_no Char(25),Revision char(8),Descript char(45),Part_class char(8),Part_type char(8),
		--			Uniq_key char(10),part_sourc char(10),Status  char(8)) 
	-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	DECLARE @ZConsgnPart TABLE (CustPartno Char(35),CustRev char(8),Descript char(45),CustName Char(35),Custno char(10),
					Uniq_key char(10),Int_uniq char(10),Status  char(8)) 
	-- 06/22/12 YS added order pref
	DECLARE @ZIntMfgrPart TABLE (PartMfgr char(8),Mfgr_pt_no char(30),UniqMfgrHd Char(10),Uniq_key Char(10),OrderPref int,Qty_oh Numeric(12,2))

	DECLARE @ZCustMfgrPart TABLE (PartMfgr char(8),Mfgr_pt_no char(30),UniqMfgrHd Char(10),Uniq_key Char(10),OrderPref int,Qty_oh Numeric(12,2))
	-- 07/16/18 VL changed supname from char(30) to char(50)
	DECLARE @ZSupplPart TABLE (suplpartno char(30),SupName char(50),UniqSupNo char(10),UniqMfgrHd char(10))
 
	
	--- get all the suppl part number matching to the given parameter
	-- 06/22/12 YS check for is_deleted
	INSERT INTO @ZSupplPart SELECT suplpartno,SupName,Invtmfsp.UniqSupNo,Invtmfsp.UniqMfgrHd 
		FROM Invtmfsp,Supinfo 
		WHERE Supinfo.UniqSupNO=Invtmfsp.UniqSupno 
		AND Invtmfsp.IS_DELETED =0
		AND CHARINDEX(UPPER(RTRIM(@lcsuplpartno)),UPPER(suplpartno))>0

	-- Get Internal PartMfgr information
	--  10/10/14 YS removed invtmfhd and replaced with 2 new tables
	--INSERT INTO @ZIntMfgrPart 
	--		SELECT PartMfgr ,Mfgr_pt_no ,Invtmfhd.UniqMfgrHd ,Invtmfhd.Uniq_key ,OrderPref,
	--				CAST(ISNULL(SUM(Invtmfgr.Qty_oh),0.00) as Numeric(12,2)) AS Qty_oh
	--				FROM Invtmfhd LEFT OUTER JOIN Invtmfgr ON Invtmfhd.UniqMfgrhd=Invtmfgr.UniqMfgrHd 
	--		WHERE Invtmfhd.UniqMfgrHd  IN (SELECT UniqMfgrHd FROM @ZSupplPart)
	--		AND Invtmfhd.is_deleted=0 
	--		GROUP BY PartMfgr ,Mfgr_pt_no ,Invtmfhd.UniqMfgrHd ,Invtmfhd.Uniq_key,ORDERPREF 	
	-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int
	INSERT INTO @ZIntMfgrPart 
			SELECT PartMfgr ,Mfgr_pt_no ,l.UniqMfgrHd ,l.Uniq_key ,OrderPref,
					CAST(ISNULL(SUM(Invtmfgr.Qty_oh),0.00) as Numeric(12,2)) AS Qty_oh
					FROM InvtmpnLink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
					LEFT OUTER JOIN Invtmfgr ON l.UniqMfgrhd=Invtmfgr.UniqMfgrHd 
			WHERE EXISTS (SELECT 1 FROM @ZSupplPart z where z.UniqMfgrHd=l.UniqMfgrHd)
			AND l.is_deleted=0 and m.IS_DELETED=0
			GROUP BY PartMfgr ,Mfgr_pt_no ,l.UniqMfgrHd ,l.Uniq_key,ORDERPREF ;

	-- get internal parts for selected criteria	- SqlResult
	SELECT DISTINCT  Part_no,Revision,Descript,Part_class,Part_type,Inventor.Uniq_key,Part_sourc,Status 
		FROM Inventor
	WHERE Inventor.Part_sourc<>'CONSG' AND Inventor.Uniq_key IN (SELECT Uniq_key from @ZIntMfgrPart)
	
	-- get Consign parts
	INSERT INTO @ZConsgnPart SELECT Inventor.CustPartno,Inventor.CustRev,Inventor.Descript,CustName,Inventor.CustNo,Inventor.Uniq_key,Inventor.Int_uniq,Inventor.Status 
			FROM Inventor,Customer WHERE Inventor.Int_uniq IN (SELECT Uniq_key FROM @ZIntMfgrPart)
			AND Inventor.Custno=Customer.Custno 
			AND Inventor.Part_sourc='CONSG'
	
	--- SqlResult1
	SELECT * FROM @ZConsgnPart
	
	--- SqlResult2
	SELECT * FROM @ZIntMfgrPart

	-- Get Consign PartMfgr information
	--  10/10/14 YS removed invtmfhd and replaced with 2 new tables
	--INSERT INTO @ZCustMfgrPart 
	--		SELECT PartMfgr ,Mfgr_pt_no ,Invtmfhd.UniqMfgrHd ,Invtmfhd.Uniq_key ,OrderPref,
	--				CAST(ISNULL(SUM(Invtmfgr.Qty_oh),0.00) as Numeric(12,2)) AS Qty_oh
	--				FROM Invtmfhd LEFT OUTER JOIN Invtmfgr ON Invtmfhd.UniqMfgrhd=Invtmfgr.UniqMfgrHd 
	--		WHERE Invtmfhd.Uniq_key  IN (SELECT UNIQ_KEY FROM @ZConsgnPart)
	--		AND Invtmfhd.is_deleted=0 
	--		GROUP BY PartMfgr ,Mfgr_pt_no ,Invtmfhd.UniqMfgrHd ,Invtmfhd.Uniq_key,OrderPref


	INSERT INTO @ZCustMfgrPart 
			SELECT PartMfgr ,Mfgr_pt_no ,l.UniqMfgrHd ,l.Uniq_key ,OrderPref,
					CAST(ISNULL(SUM(Invtmfgr.Qty_oh),0.00) as Numeric(12,2)) AS Qty_oh
					FROM Invtmpnlink L INNER JOIN MfgrMaster M ON  L.mfgrMasterId=M.MfgrMasterId
					LEFT OUTER JOIN Invtmfgr ON l.UniqMfgrhd=Invtmfgr.UniqMfgrHd 
			WHERE EXISTS (SELECT 1 from @ZConsgnPart z where z.Uniq_key= l.Uniq_key)
			AND l.is_deleted=0 and m.IS_DELETED=0
			GROUP BY PartMfgr ,Mfgr_pt_no ,l.UniqMfgrHd ,l.Uniq_key,OrderPref ;
	
	--- SqlResult3
	SELECT * FROM @ZCustMfgrPart
	-- Get Supplier part numbers - SQLResult4
	SELECT * FROM @ZSupplPart

END