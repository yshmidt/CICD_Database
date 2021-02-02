-- =================================================
-- Author:		Shivshankar P
-- Create date: <03/22/2017>
-- Description:	Return PO Line Items
--Shivshankar P :04/01/17 Used for display wether part is loted/not on grid
--Shivshankar P :02/01/17 For getting all line items based on ponum OR Single line Item
--Shivshankar P :04/12/17 Ranging the serial number based on Lot
--Shivshankar P  : Display Alpha Numeric Serial numbers in Range and removed the leading zero's
--Shivshankar P : 11/14/17 Get all the serial number which are received against the multiple Schedule
--Shivshankar P : 12/08/17 Get all the serial number which are received against the multiple Schedule against line Item
--Shivshankar P : 08/20/20 Remove dbo.fRemoveLeadingZeros function to improve performance 
--[GetPoResSerList] '0000001514','ZEASKLED5S'
-- =================================================
CREATE PROCEDURE [dbo].[GetPoResSerList] 
@ReceiverNo char(10)='',
@fkUniqRecdtl char(10) = ''
AS
BEGIN

declare @tSerialList  table
( serialno char(30) null,
  lotuniq char(10) null
)
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;
		INSERT INTO @tSerialList SELECT POR.serialno,por.LOT_UNIQ FROM PORECSER POR INNER JOIN INVTSER INTS ON POR.FK_SERIALUNIQ = INTS.SERIALUNIQ 
		WHERE POR.RECEIVERNO =@ReceiverNo AND POR.LOC_UNIQ IN (SELECT LOC_UNIQ FROM PORECLOC where FK_UNIQRECDTL =@fkUniqRecdtl) --Shivshankar P : 12/08/17 Get all the serial number which are received against the multiple Schedule against line Item

	;with 
		startRangePoint as
		(
		SELECT A.serialno, ROW_NUMBER() OVER(ORDER BY Serialno) AS rownum,A.serialno as start_range ,A.LotUniq
		FROM @tSerialList AS A 
		WHERE 
		(serialno  LIKE '%[a-z]%' AND 
		PATINDEX('%[^a-zA-Z0-9]%' , A.serialno) > 0  --Shivshankar P  : Display Alpha Numeric Serial numbers in Range
		and 
	    EXISTS (SELECT 1 FROM @tSerialList AS B WHERE 
		PATINDEX('%[^a-zA-Z0-9]%',b.serialno)=0
		OR(
		PATINDEX('%[^a-zA-Z0-9]%',b.serialno)=0
		and convert(varchar, B.Serialno)=Convert(varchar,A.Serialno)-1 ) AND A.lotuniq = B.lotuniq --Shivshankar P : 08/20/20 Remove dbo.fRemoveLeadingZeros function to improve performance
		)) 
		OR (PATINDEX('%[^0-9]%',A.serialno)=0  and NOT EXISTS (SELECT 1 FROM @tSerialList AS B WHERE 
		PATINDEX('%[^0-9]%',b.serialno)=1 OR(
		PATINDEX('%[^0-9]%',b.serialno)=0  
		and convert(float, B.Serialno)=Convert(float, A.Serialno)-1 ) AND A.lotuniq = B.lotuniq)  --Shivshsnkar P :04/12/17 Ranging the serial number based on Lot
		)) --Shivshankar P : 08/20/20 Remove dbo.fRemoveLeadingZeros function to improve performance
		,endRangePoint
		as
		(
			select AE.serialno, ROW_NUMBER() OVER(ORDER BY Serialno) AS rownum,AE.serialno as End_range ,AE.LotUniq
			FROM @tSerialList AS AE 
			WHERE (serialno  LIKE '%[a-z]%' AND 
		PATINDEX('%[^a-zA-Z0-9]%' , ae.serialno) > 0  --Shivshankar P  : Display Alpha Numeric Serial numbers in Range
		and 
	    EXISTS (SELECT 1 FROM @tSerialList AS B WHERE 
		PATINDEX('%[^a-zA-Z0-9]%',b.serialno)=0
		OR(
		PATINDEX('%[^a-zA-Z0-9]%',b.serialno)=0
		and convert(varchar, B.Serialno)=Convert(varchar, Ae.Serialno)-1 ) AND AE.lotuniq = B.lotuniq --Shivshankar P : 08/20/20 Remove dbo.fRemoveLeadingZeros function to improve performance
		))  
		OR (PATINDEX('%[^0-9]%',ae.serialno)=0 and 
			NOT EXISTS (SELECT 1 FROM @tSerialList AS BE WHERE 
			PATINDEX('%[^0-9]%',be.serialno)=1
			OR(
			PATINDEX('%[^0-9]%',be.serialno)=0  
			and convert(float, Be.Serialno)=Convert(float, Ae.Serialno)+1 ) AND AE.lotuniq = BE.lotuniq)  --Shivshsnkar P :04/12/17 Ranging the serial number based on Lot
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


