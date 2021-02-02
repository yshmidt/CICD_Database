CREATE PROCEDURE [dbo].[sp_GlobalInvtDescriptionCaseChanger] @lcCASE AS char(10) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

BEGIN TRANSACTION

UPDATE Inventor SET Descript = CASE WHEN @lcCASE = 'UPPER' THEN UPPER(Descript) ELSE	
								(CASE WHEN @lcCASE = 'LOWER' THEN LOWER(Descript) ELSE
								(CASE WHEN @lcCASE = 'PROPER' THEN dbo.PROPER(DESCRIPT) ELSE DESCRIPT END) END) END
								


COMMIT

END