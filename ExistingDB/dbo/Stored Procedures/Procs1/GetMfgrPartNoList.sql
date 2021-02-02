-- =============================================
-- Author: Vijay Gh
-- Create Date: 05/29/2018
-- Description: Get Mfgr Part Number List on the basis of part status 
-- Sanjay B 27/11/2018 : Select the distinct mfgr part number and not to select PartMfgr  
-- =============================================
CREATE PROCEDURE dbo.[GetMfgrPartNoList]
@pageNumber int = 0,
@pageSize int=10,
@mfgrPartNo varchar(30) =' ',
@status varchar(10)=' '

AS 
	BEGIN
	SET NOCOUNT ON;
		if(@mfgrPartNo != '')
			BEGIN
				 -- Sanjay B 27/11/2018 : Select the distinct mfgr part number and not to select PartMfgr
				SELECT  Distinct(m.mfgr_pt_no) FROM MfgrMaster m INNER JOIN InvtMPNLink l on m.MfgrMasterId = l.MfgrMasterId  
				INNER JOIN INVENTOR i on l.uniq_key = i.UNIQ_KEY where (i.STATUS = @status AND m.is_deleted <> 1 AND (m.mfgr_pt_no  LIKE '%'+ @mfgrPartNo + '%'))
				ORDER BY m.mfgr_pt_no
				OFFSET @pageNumber ROWS
				FETCH NEXT @pageSize ROWS ONLY;
			END
		ELSE
			BEGIN
				 -- Sanjay B 27/11/2018 : Select the distinct mfgr part number and not to select PartMfgr
				SELECT  Distinct(m.mfgr_pt_no) from MfgrMaster m INNER JOIN InvtMPNLink l on m.MfgrMasterId = l.MfgrMasterId  
				INNER JOIN INVENTOR i on l.uniq_key = i.UNIQ_KEY where (i.STATUS = @status AND m.is_deleted <> 1 AND m.mfgr_pt_no <> '')
				ORDER BY m.mfgr_pt_no
				OFFSET @pageNumber ROWS
				FETCH NEXT @pageSize ROWS ONLY;
			END
	END