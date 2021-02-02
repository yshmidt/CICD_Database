
CREATE PROCEDURE [dbo].[ContMfgrView] @gContr_Uniq AS Char(10) = ' '
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Mfgr_uniq, Contr_uniq, Partmfgr, Mfgr_pt_no
	FROM Contmfgr
	WHERE Contr_uniq = @gContr_uniq
	ORDER BY Partmfgr
 
END