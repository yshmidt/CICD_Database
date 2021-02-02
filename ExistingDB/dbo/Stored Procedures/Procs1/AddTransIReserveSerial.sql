-- =============================================
-- Author:Rajendra K
-- Create date: 04/02/2019
-- Description:	Used to Add records into 'iTransferSerial' table and update "INVTSER" table
-- =============================================
CREATE PROCEDURE  [dbo].[AddTransIReserveSerial]
(
@invtxfer_n CHAR(10),
@tSerialUniq tSerialUniq READONLY,
@fromSID CHAR(10),
@toSID CHAR(10),
@isWH BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO iTransferSerial
	SELECT  dbo.fn_GenerateUniqueNumber()
			,@invtxfer_n
			,Serialno
			,SerialUniq
			,ISNULL(@fromSID,'')
			,ISNULL(@toSID,'')					
	FROM @tSerialUniq	

    UPDATE INVTSER 
	SET INVTSER.ipkeyunique = CASE 
								WHEN @isWH = 0 THEN @toSID
								ELSE ISNULL(@fromSID,'')
							END
	FROM @tSerialUniq AS ts
	WHERE INVTSER.SERIALUNIQ = ts.SerialUniq
END