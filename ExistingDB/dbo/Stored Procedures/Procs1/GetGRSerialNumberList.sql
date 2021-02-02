-- ==================================================================================================
-- Author:		Nilesh S
-- Create date: <02/21/2018>
-- Description:	Get Serial Number List for general receiving
-- exec GetGRSerialNumberList '0000000110','XPVNWI4TMD'
-- Nilesh Sa 3/15/2018 Added grouping for result
-- ==================================================================================================
CREATE PROCEDURE [dbo].[GetGRSerialNumberList] 
	@receiverNo CHAR(10)='',
	@invtRecNo CHAR(10)=''
AS
BEGIN
		DECLARE @tSerialList TABLE
		( serialno CHAR(30) NULL,
		  lotuniq CHAR(10) NULL
		)
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;
		INSERT INTO @tSerialList 
		SELECT iRecSerial.serialno,INVT_REC.UNIQ_LOT AS lotuniq
        FROM iRecSerial  
		INNER JOIN INVTSER ON iRecSerial.serialuniq = INVTSER.SERIALUNIQ 
		INNER JOIN INVT_REC ON iRecSerial.invtrec_no = INVT_REC.INVTREC_NO
		INNER JOIN receiverDetail ON INVT_REC.receiverdetId = receiverDetail.receiverDetId
		INNER JOIN receiverHeader ON receiverDetail.receiverHdrId = receiverDetail.receiverHdrId
		WHERE receiverHeader.receiverno=@receiverNo AND INVT_REC.INVTREC_NO = @invtRecNo
		Group BY iRecSerial.serialno,INVT_REC.UNIQ_LOT -- Nilesh Sa 3/15/2018 Added grouping for result
		
		;with 
		startRangePoint as
		(
		SELECT A.serialno, ROW_NUMBER() OVER(ORDER BY Serialno) AS rownum,A.serialno as start_range ,A.LotUniq
		FROM @tSerialList AS A 
		WHERE 
		(serialno  LIKE '%[a-z]%' AND 
		PATINDEX('%[^a-zA-Z0-9]%' , A.serialno) > 0 
		and 
	    EXISTS (SELECT 1 FROM @tSerialList AS B WHERE 
		PATINDEX('%[^a-zA-Z0-9]%',b.serialno)=0
		OR(
		PATINDEX('%[^a-zA-Z0-9]%',b.serialno)=0
		and convert(varchar, dbo.fRemoveLeadingZeros(B.Serialno))=Convert(varchar, dbo.fRemoveLeadingZeros(A.Serialno))-1 ) AND A.lotuniq = B.lotuniq
		)) 
		OR (PATINDEX('%[^0-9]%',A.serialno)=0  and NOT EXISTS (SELECT 1 FROM @tSerialList AS B WHERE 
		PATINDEX('%[^0-9]%',b.serialno)=1 OR(
		PATINDEX('%[^0-9]%',b.serialno)=0  
		and convert(float, dbo.fRemoveLeadingZeros(B.Serialno))=Convert(float, dbo.fRemoveLeadingZeros(A.Serialno))-1 ) AND A.lotuniq = B.lotuniq) 
		))
		,endRangePoint
		as
		(
			select AE.serialno, ROW_NUMBER() OVER(ORDER BY Serialno) AS rownum,AE.serialno as End_range ,AE.LotUniq
			FROM @tSerialList AS AE 
			WHERE (serialno  LIKE '%[a-z]%' AND 
		PATINDEX('%[^a-zA-Z0-9]%' , ae.serialno) > 0  
		and 
	    EXISTS (SELECT 1 FROM @tSerialList AS B WHERE 
		PATINDEX('%[^a-zA-Z0-9]%',b.serialno)=0
		OR(
		PATINDEX('%[^a-zA-Z0-9]%',b.serialno)=0
		and convert(varchar, dbo.fRemoveLeadingZeros(B.Serialno))=Convert(varchar, dbo.fRemoveLeadingZeros(Ae.Serialno))-1 ) AND AE.lotuniq = B.lotuniq
		))  
		OR (PATINDEX('%[^0-9]%',ae.serialno)=0 and 
			NOT EXISTS (SELECT 1 FROM @tSerialList AS BE WHERE 
			PATINDEX('%[^0-9]%',be.serialno)=1
			OR(
			PATINDEX('%[^0-9]%',be.serialno)=0  
			and convert(float, Be.Serialno)=Convert(float, Ae.Serialno)+1 ) AND AE.lotuniq = BE.lotuniq) 
		))
		,endstart
		as
		(
		select s.serialno,s.rownum,s.start_range,e.End_range ,s.LotUniq from startRangePoint s
		inner join EndRangePoint e on s.rownum=e.rownum  
		)

			SELECT serialno,rownum,replace(ltrim(replace(start_range,'0',' ')),' ','0') as start_range ,replace(ltrim(replace(End_range,'0',' ')),' ','0') as End_range,LotUniq from endstart
		UNION ALL
			SELECT serialno,lastrownum.nstart+ ROW_NUMBER () OVER (order by serialno) as rownum,dbo.fRemoveLeadingZeros(serialno) as start_range,dbo.fRemoveLeadingZeros(serialno) as end_range ,LotUniq
			FROM @tSerialList 
			CROSS APPLY (select top 1 rownum as nstart from endstart order by rownum desc) lastRownum
			where PATINDEX('%[^0-9]%',[@tSerialList].serialno)<>0
END