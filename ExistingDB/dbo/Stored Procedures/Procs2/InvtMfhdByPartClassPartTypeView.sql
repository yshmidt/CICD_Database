-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- Modified: 10/09/14 YS removed invtmfhd table and replace with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[InvtMfhdByPartClassPartTypeView]
	-- Add the parameters for the stored procedure here
	@lcPart_class char(8) = ' ', @lcPart_type char(8) = ' '

AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
--10/09/14 rewrote without CTE
--WITH ZInvt AS
--(
--SELECT Uniq_key
--	FROM Inventor
--	WHERE 1 = CASE WHEN @lcPart_type = '' THEN
--				CASE WHEN PART_CLASS = @lcPart_class THEN 1 ELSE 0 END
--				ELSE CASE WHEN PART_CLASS = @lcPart_class AND PART_TYPE = @lcPart_type THEN 1 ELSE 0 END END
--)
----10/09/14 YS removed invtmfhd table and replace with 2 new tables
--SELECT M.AutoLocation, L.Uniq_key, L.UniqMfgrhd 
--	FROM InvtmpnLink L INNER JOIN MfgrMaster M on L.MfgrMasterid=M.MfgrMasterId
--	WHERE L.UNIQ_KEY IN
--		(SELECT UNIQ_KEY
--			FROM ZInvt)		
		
----10/09/14 YS removed invtmfhd table and replace with 2 new tables
-- 10/16/14 YS added mfgrmasterid column to be able to update mfgrmaster.autolocation from invtutility form (desktop)
-- 10/16/14 YS remove uniq_key and Uniqmfgrhd, but use it to find correct record in mfgrMaster
--SELECT M.AutoLocation, L.Uniq_key, L.UniqMfgrhd ,m.MfgrMasterid
--FROM InvtmpnLink L INNER JOIN MfgrMaster M on L.MfgrMasterid=M.MfgrMasterId
--INNER JOIN Inventor I ON l.uniq_key=I.Uniq_key
--WHERE 1 = CASE WHEN @lcPart_type = '' THEN
--		CASE WHEN PART_CLASS = @lcPart_class THEN 1 ELSE 0 END
--	ELSE CASE WHEN PART_CLASS = @lcPart_class AND PART_TYPE = @lcPart_type THEN 1 ELSE 0 END END

SELECT M.AutoLocation, m.MfgrMasterid
FROM MfgrMaster M 
WHERE EXISTS (select 1 FROM Invtmpnlink L
INNER JOIN Inventor I ON l.uniq_key=I.Uniq_key
WHERE 1 = CASE WHEN @lcPart_type = '' THEN
		CASE WHEN PART_CLASS = @lcPart_class THEN 1 ELSE 0 END
	ELSE CASE WHEN PART_CLASS = @lcPart_class AND PART_TYPE = @lcPart_type THEN 1 ELSE 0 END END
	and L.mfgrMasterId=M.MfgrMasterId)
        
END
 