-- =============================================
-- Author:		Vicky Lu	
-- Create date: <10/16/12>
-- Description:	<Get all invtmfhd records with mfgr_pt_no table passed in>
-- Modified: 10/08/14 YS replace invtmfhd table with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[GetMfgr_pt_no] 
	-- Add the parameters for the stored procedure here
	@ltMfgr_pt_no AS tMfgr_pt_no READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- 10/08/14 YS replace invtmfhd table with 2 new tables
--SELECT ltMfgr_pt_no.Mfgr_pt_no, Inventor.Part_no, Inventor.Revision,Inventor.Descript,Invtmfhd.Partmfgr
--	FROM @ltMfgr_pt_no ltMfgr_pt_no, Invtmfhd, Inventor
--	WHERE LOWER(Invtmfhd.Mfgr_pt_no)=  LOWER(ltMfgr_pt_no.MFgr_pt_no) 
--	AND Inventor.Uniq_key = Invtmfhd.Uniq_key
--	AND Inventor.Part_sourc <> 'CONSG'
--	ORDER BY ltMfgr_pt_no.Mfgr_pt_no

SELECT ltMfgr_pt_no.Mfgr_pt_no, Inventor.Part_no, Inventor.Revision,Inventor.Descript,M.Partmfgr
	FROM @ltMfgr_pt_no ltMfgr_pt_no, InvtMPNLink,MfgrMaster M, Inventor
	WHERE LOWER(m.Mfgr_pt_no)=  LOWER(ltMfgr_pt_no.MFgr_pt_no) 
	AND Inventor.Uniq_key = InvtMPNLink.Uniq_key
	AND InvtMPNLink.mfgrMasterId=M.MfgrMasterId
	AND Inventor.Part_sourc <> 'CONSG'
	ORDER BY ltMfgr_pt_no.Mfgr_pt_no
		
END