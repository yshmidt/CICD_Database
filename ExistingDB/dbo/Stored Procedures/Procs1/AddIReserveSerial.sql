-- =============================================
-- Author:Rajendra K
-- Create date: 06/12/2017
-- Description:	Used to Add records into 'IReserveSerial' table
-- Modification
   --  06/28/2017 Rajendra K : Added ISNULL condition to insert SID
-- =============================================
CREATE PROCEDURE  [dbo].[AddIReserveSerial]
(
@InvtResNo CHAR(10),
@SID CHAR(10),
@KaSeqNum CHAR(10),
@UnReserve BIT = 0,
@XMLSerialUniqList XML
)
AS
BEGIN
	SET NOCOUNT ON;
			INSERT INTO iReserveSerial
			SELECT  dbo.fn_GenerateUniqueNumber()
				    ,@InvtResNo
				    ,data.col.value('@SerialUniqNumber', 'CHAR(10)')
					,ISNULL(@SID,'') --  06/28/2017 Rajendra K : Added ISNULL condition to insert SID
					,@KaSeqNum
					,@UnReserve
			FROM @XMLSerialUniqList.nodes('//a') data(col)
END	