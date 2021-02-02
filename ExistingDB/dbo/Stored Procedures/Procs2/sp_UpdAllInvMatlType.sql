-- =============================================
-- Author:		Vicky Lu
-- Create date: 08/31/2009
-- Description:	This procedure will go through Inventor table active parts and update Matltype
--				from the sp_FigureoutMatlType
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdAllInvMatlType] @cUserId AS char(8) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @lnCount int,@lnTotalNo int,@Uniq_key char(10);
SET @lnCount = 0;

DECLARE @ZInventor TABLE (nrecno int identity,Uniq_key char(10));
INSERT @ZInventor
	SELECT Uniq_key
		FROM Inventor
		WHERE Status = 'Active'

SET @lnTotalNo = @@ROWCOUNT;

IF (@lnTotalNo>0)
BEGIN	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @Uniq_key=Uniq_key
			FROM @ZInventor WHERE nrecno = @lnCount;
		IF (@@ROWCOUNT<>0)
			EXEC sp_UpdOneInvMatlType @Uniq_key, @cUserId
		
	END
END

END