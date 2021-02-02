-- =============================================
-- Author:		Vicky Lu
-- Create date: 2011/07/19
-- Description:	Update ECO Approval Depts if new approval depts are added in syssetup
-- =============================================
CREATE PROCEDURE [dbo].[sp_ECOUpdApprovalDept] @gUniqEcno AS char(10) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @lnTotalNo int, @lnCount int, @Dept char(25), @lcNewUniqNbr char(10)
DECLARE @ZECODept TABLE (nrecno int identity, Dept char(25))

INSERT @ZEcoDept SELECT LEFT(Text,25) AS Dept
		FROM Support
		WHERE FIELDNAME = 'DEPT'
		AND Logic1 = 1
		AND LEFT(Text,25) NOT IN 
			(SELECT DEPT FROM ECAPPROV WHERE UNIQECNO = @gUniqEcno)

SET @lnTotalNo = @@ROWCOUNT;	
BEGIN	
IF @lnTotalNo > 0
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @Dept = Dept
			FROM @ZEcoDept WHERE nrecno = @lnCount
			EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT	
		INSERT INTO ECAPPROV (UNIQECNO, UNIQAPPNO, DEPT) 
			VALUES (@gUniqEcno, @lcNewUniqNbr, @Dept)
	END
END

END









