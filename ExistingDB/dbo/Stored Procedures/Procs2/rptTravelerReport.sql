
-- =============================================
-- Author:			Sachin B
-- Create date:		11/09/2017
-- Description:		Created for the  traveler Report
-- Reports:			traveler.rmt
-- rptTravelerReport 'BF5UOFMMOR','["IZOP94ZWGP","P82MJG8WR8","8U9Z2MVF9P","B5KAW9ICBM","H61UUGID3R","SFYOF327JG","J4BHACH7L2","H88ZIS5F7V"]',''
-- Sachin B 09/25/2017 Add join with Invt_rec and iRecIpKey tables and parameter InvtRecNo
-- Sachin B 03/10/2017 Add i.useipkey,i.SERIALYES in select statement , trim part_no and correct join in customer and PJCTMAIN table
-- Sachin B 10/16/2017 Sachin B Add logic for the show continuously serial numbers in range and temp table @serialData
-- Sachin B 05/23/2019 - Get user name based on BY column of TRANSFER table
-- =============================================
CREATE PROCEDURE [dbo].[rptTravelerReport] 
	@XFER_UNIQ varchar (35),
	@SerialUniqList VARCHAR(MAX)='',
	@InvtRecNo VARCHAR(15)=''
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
SET NOCOUNT ON;

SET @SerialUniqList = REPLACE(REPLACE(REPLACE(@SerialUniqList,'[',''),']',''),'"','') 

IF EXISTS(SELECT id FROM dbo.[fn_simpleVarcharlistToTable](@SerialUniqList,','))
	BEGIN

			-- Sachin B 10/16/2017 Sachin B Add logic for the show continuously serial numbers in range and temp table @serialData
			DECLARE @serialData TABLE  (UNIQ_KEY CHAR(10),WONO CHAR(10),OPENCLOS CHAR(10),SONO CHAR(10),part_no CHAR(45),DESCRIPT CHAR(45),useipkey BIT,SERIALYES BIT,CUSTNAME CHAR(35),
      PRJNUMBER CHAR(10),fromDept CHAR(4),toDept CHAR(4),QTY NUMERIC(7,0),[BY] CHAR(512),[DATE] DATETIME,SERIALNO CHAR(30),ipkeyunique CHAR(10))  

			-- Sachin B 03/10/2017 Add i.useipkey,i.SERIALYES in select statement , trim part_no and correct join in customer and PJCTMAIN table
			-- Sachin B 05/23/2019 - Get user name based on BY column of TRANSFER table
      INSERT INTO @serialData (UNIQ_KEY,WONO,OPENCLOS,SONO,part_no,DESCRIPT,useipkey,SERIALYES,CUSTNAME,PRJNUMBER,fromDept,toDept,QTY,[BY],[DATE],SERIALNO,ipkeyunique)
			SELECT DISTINCT i.UNIQ_KEY, w.WONO,w.OPENCLOS,w.SONO,CONCAT(RTRIM(LTRIM(i.part_no)),'/',i.REVISION) AS part_no ,
      i.DESCRIPT,i.useipkey,i.SERIALYES, c.CUSTNAME,p.PRJNUMBER,t.FR_DEPT_ID AS fromDept,t.TO_DEPT_ID AS toDept,t.QTY,u.UserName As [BY],t.DATE,  
			ser.SERIALNO,RTRIM(LTRIM(ISNULL(ser.ipkeyunique,''))) AS ipkeyunique
			FROM dbo.WOENTRY w
			JOIN INVENTOR i ON w.UNIQ_KEY = i.UNIQ_KEY
			JOIN TRANSFER t ON w.WONO = t.WONO AND t.XFER_UNIQ=@XFER_UNIQ
			INNER JOIN dbo.CUSTOMER c ON w.CUSTNO = c.CUSTNO 
			LEFT JOIN PJCTMAIN p ON w.PRJUNIQUE = p.PRJUNIQUE
			LEFT JOIN InvtSer ser ON i.UNIQ_KEY = ser.UNIQ_KEY AND ser.SERIALUNIQ IN(SELECT id FROM dbo.[fn_simpleVarcharlistToTable](@SerialUniqList,','))
      LEFT JOIN aspnet_Users u on t.[BY] =  u.UserId

			-- Sachin B 10/16/2017 Sachin B Add logic for the show continuously serial numbers in range and temp table @serialData
			;WITH SerialList AS
			(
				SELECT CAST(DBO.fRemoveLeadingZeros(SERIALNO) AS NUMERIC(30,0)) AS iSerialno,UNIQ_KEY,WONO,OPENCLOS,SONO,part_no,DESCRIPT,useipkey,SERIALYES,CUSTNAME,PRJNUMBER,
				fromDept,toDept,QTY,[BY],[DATE],SERIALNO,ipkeyunique  
				FROM @serialData 
				where  PATINDEX('%[^0-9]%',SERIALNO)=0 
			)
			,StartingPoints as
			(
				select A.*, ROW_NUMBER() OVER(PARTITION BY A.WONO ORDER BY iSerialno) AS rownum
				FROM SerialList AS A WHERE NOT EXISTS (SELECT 1 FROM SerialList AS B WHERE B.iSerialno=A.iSerialno-1)
			)
			--SELECT * FROM StartingPoints  
   			,EndingPoints AS
			(
				select A.*, ROW_NUMBER() OVER(PARTITION BY WONO ORDER BY iSerialno) AS rownum
				FROM SerialList AS A WHERE NOT EXISTS (SELECT 1 FROM SerialList AS B WHERE B.iSerialno=A.iSerialno+1) 
			)
			--SELECT * FROM EndingPoints
			,StartEndSerialno AS 
			(
				SELECT S.*,S.iSerialno AS start_range, E.iSerialno AS end_range
				FROM StartingPoints AS S
				JOIN EndingPoints AS E
				ON E.rownum = S.rownum and E.WONO = S.WONO --and E.ipkeyunique =S.ipkeyunique 
			)
			,FinalSerialno AS
			(
				SELECT UNIQ_KEY,WONO,OPENCLOS,SONO,part_no,DESCRIPT,useipkey,SERIALYES,CUSTNAME,PRJNUMBER,fromDept,toDept,QTY,[BY],[DATE],
				CASE WHEN A.start_range=A.End_range
				THEN CAST(RTRIM(CONVERT(CHAR(30),A.start_range))  AS VARCHAR(MAX)) ELSE
				CAST(RTRIM(CONVERT(CHAR(30),A.start_range))+'-'+RTRIM(CONVERT(CHAR(30),A.End_range)) AS VARCHAR(MAX)) END AS SERIALNO,
				ipkeyunique
				FROM StartEndSerialno  A
			UNION 
				SELECT UNIQ_KEY,WONO,OPENCLOS,SONO,part_no,DESCRIPT,useipkey,SERIALYES,CUSTNAME,PRJNUMBER,fromDept,toDept,QTY,[BY],[DATE],
				CAST(DBO.fRemoveLeadingZeros(Serialno) AS VARCHAR(MAX)) AS SERIALNO,
				ipkeyunique FROM @serialData  
				WHERE (Serialno LIKE '%[a-z]%' OR PATINDEX('%[^0-9A-Za-z]%',serialno)<>0) 
			)
			,WoData AS(
			 SELECT s.UNIQ_KEY,s.WONO,s.OPENCLOS,s.SONO,part_no,DESCRIPT,useipkey,s.SERIALYES,CUSTNAME,PRJNUMBER,fromDept,toDept,QTY,[BY],[DATE],
			 CAST(stuff((SELECT', '+ps.Serialno	from FinalSerialno PS
														WHERE	PS.WONO = w.WONO
														ORDER BY SERIALNO FOR XML PATH ('')),1,2,'') AS VARCHAR (MAX)) AS Serialno
			FROM dbo.WOENTRY w
			JOIN @serialData s ON w.WONO = s.wono		
		)
		SELECT DISTINCT UNIQ_KEY,WONO,OPENCLOS,SONO,part_no,DESCRIPT,useipkey,SERIALYES,CUSTNAME,PRJNUMBER,fromDept,toDept,QTY,[BY],[DATE],SERIALNO FROM WoData
	END 
ELSE
	BEGIN
  
		-- Sachin B 09/25/2017 Add join with Invt_rec and iRecIpKey tables and parameter InvtRecNo
		-- Sachin B 03/10/2017 Add i.useipkey,i.SERIALYES in select statement , trim part_no and correct join in customer and PJCTMAIN table
		-- Sachin B 05/23/2019 - Get user name based on BY column of TRANSFER table
    SELECT DISTINCT i.UNIQ_KEY, w.WONO,w.OPENCLOS,w.SONO,CONCAT(RTRIM(LTRIM(i.part_no)),'/',i.REVISION) AS part_no  ,
    i.DESCRIPT,i.useipkey,i.SERIALYES,c.CUSTNAME,p.PRJNUMBER,t.FR_DEPT_ID AS fromDept,t.TO_DEPT_ID AS toDept,t.QTY,u.UserName As [BY] ,t.DATE,'' AS SERIALNO,ISNULL(ipk.ipkeyunique,'') AS ipkeyunique  
		FROM dbo.WOENTRY w
		JOIN INVENTOR i ON w.UNIQ_KEY = i.UNIQ_KEY
		JOIN TRANSFER t ON w.WONO = t.WONO AND t.XFER_UNIQ=@XFER_UNIQ
		INNER JOIN dbo.CUSTOMER c ON w.CUSTNO = c.CUSTNO 
		LEFT JOIN PJCTMAIN p ON w.PRJUNIQUE = p.PRJUNIQUE
		LEFT JOIN INVT_REC ivr ON i.UNIQ_KEY = ivr.UNIQ_KEY AND ivr.INVTREC_NO=@InvtRecNo
		LEFT JOIN iRecIpKey ipk ON ivr.INVTREC_NO = ipk.invtrec_no
    LEFT JOIN aspnet_Users u on t.[BY] =  u.UserId
	END
END 


