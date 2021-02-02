-- =============================================
-- Author: Rajendra K
-- Create date: 01/12/2018
-- Description:	Insert records into IRecSerial Table
-- EXEC AddIIssueSerial 'KIUORFKCDS','000000000000000000000556622336,000000000000000000000556622337,000000000000000000000556622338','KUIOKLOIKJ','IKOPLKUIJK'
-- Modified : Satish B : 03/13/2018 : Added the join of Invt_ISU table
-- ============================================= 
CREATE PROCEDURE AddIIssueSerial
(
@invtrecNo CHAR(10),
@serialNumberList VARCHAR(MAX),
@kaSequenceNumber CHAR(10),
@ipkeyUnique CHAR(10)
)
AS
BEGIN
	SET NOCOUNT ON;
		
		--Insert Serial Numbers into temp table
		SELECT id AS SerialNumber,Iser.SERIALUNIQ 
		INTO #tempSerialNumberList 
		FROM dbo.[fn_simpleVarcharlistToTable](@serialNumberList,',') SER INNER JOIN INVTSER ISer ON  SER.id = Iser.SERIALNO 			   
		--Satish B : 03/13/2018 : Added the join of Invt_ISU table
		INNER JOIN Invt_ISU ISU ON Iser.UNIQ_KEY = ISU.UNIQ_KEY AND ISU.invtisu_no = @invtrecNo

		--Add records into iRecSerial from temp table
		INSERT INTO IssueSerial (
								iIssueSerUnique
							   ,invtisu_no
							   ,SerialNo
							   ,Serialuniq
							   ,kaseqnum
							   ,IpKeyUnique
							   ) 
						 SELECT dbo.fn_GenerateUniqueNumber()
							   ,@invtrecNo
							   ,SerialNumber
							   ,SERIALUNIQ
							   ,@kaSequenceNumber
							   ,@ipkeyUnique 
				FROM  #tempSerialNumberList
				ORDER BY SerialNumber
END
