-- =============================================
-- Author: Rajendra K
-- Create date: 01/12/2018
-- Description:	Insert records into IRecSerial Table
-- EXEC AddIIssueSerial 'KIUORFKCDS','000000000000000000000556622336,000000000000000000000556622337,000000000000000000000556622338','KUIOKLOIKJ'
-- Nilesh Sa 3/13/2018 Insert 1 new column IsGeneralReceive if receive from general receiving
--==============================================
CREATE PROCEDURE AddIRecSerial
(
@invtrecNo CHAR(10),
@serialNumberList VARCHAR(MAX),
@ipkeyUnique CHAR(10)
)
AS
BEGIN
	SET NOCOUNT ON;
		
		--Insert Serial Numbers into temp table
		SELECT id AS SerialNumber INTO #tempSerialNumberList FROM dbo.[fn_simpleVarcharlistToTable](@serialNumberList,',')

		--Add records into iRecSerial from temp table
		INSERT INTO iRecSerial (
								iRecSeriUnique
							   ,Invtrec_No
							   ,SerialNo
							   ,Serialuniq
							   ,IpKeyUnique
							   ,IsGeneralReceive -- Nilesh Sa 3/13/2018 Insert 1 new column IsGeneralReceive if receive from general receiving
							   ) 
						 SELECT dbo.fn_GenerateUniqueNumber()
							   ,@invtrecNo
							   ,SerialNumber
							   ,dbo.fn_GenerateUniqueNumber()
							   ,@ipkeyUnique ,
							   1 -- Nilesh Sa 3/13/2018 Insert 1 new column IsGeneralReceive if receive from general receiving
				FROM  #tempSerialNumberList
				WHERE SerialNumber != ''
				ORDER BY SerialNumber
END
