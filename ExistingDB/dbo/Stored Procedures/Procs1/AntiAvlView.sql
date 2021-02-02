
CREATE PROCEDURE [dbo].[AntiAvlView]
	-- Add the parameters for the stored procedure here
	@gUniq_key char(10)=' ', @cUniq_key char(10)=' ' 
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT Uniq_key, Partmfgr, Mfgr_pt_no, Bomparent, Uniqanti
	FROM Antiavl
	WHERE Bomparent = @gUniq_key
	AND Uniq_key = @cUniq_key

END
