-- =============================================
-- Author:  Nilesh S 
-- Create date: 02/28/18
-- Description:	Check serial Numbers exisits or not
-- =============================================
CREATE PROCEDURE  [dbo].[CheckSerialNumbersExists]
(
@tPoRecser tPoRecser READONLY, 
@uniqKey char(10) = ' '
)
AS
BEGIN
	 BEGIN
		DECLARE @partSource CHAR(10) = (SELECT PART_SOURC FROM INVENTOR WHERE UNIQ_KEY =  @uniqKey) 
		IF(@partSource = 'MAKE')
		BEGIN
			SELECT ISNULL(1,0) FROM INVENTOR I INNER JOIN INVTSER ISER ON I.UNIQ_KEY = ISER.UNIQ_KEY AND ISER.SERIALNO IN (SELECT serialno FROM @tPoRecser) AND I.PART_SOURC = 'MAKE'
		END
		ELSE
		BEGIN
		    SELECT ISNULL(1,0) FROM INVTSER ISER WHERE ISER.SERIALNO IN (SELECT serialno FROM @tPoRecser) 
		END
	END
END
