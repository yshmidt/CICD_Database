-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/17/17 (Happy birthday Papa)
-- Description:	Generate range for serial number list provide in the @tSerialList table as a parameter. 
-- use tSerial table type 
--Shivshankar : 03/22/2017 To get end value of the sequence number 
--- example
/*
	declare @tSerialList  tSerialno
	insert into @tSerialList values ('200'),
	('201'), ('206'),('207'),('500'),('abc-1'),('ndf'),('200-abv')
	update @tSerialList set serialno=dbo.padl(serialno,30,'0')
	select * from dbo.[fnGenerateSerialNoRanges](@tSerialList)

*/
-- =============================================
CREATE FUNCTION [dbo].[fnGenerateSerialNoRanges](@tSerialList tSerialno READONLY)
RETURNS @returnT TABLE  (iSerialNo varchar(30),rownum int,start_range varchar(30),End_range varchar(30))
as begin
	
	--declare @startRangePoint Table (serialno varchar(30),rownum int,start_range varchar(30))
	--insert into @startRangePoint (serialno,rownum,start_range)
	;with
	startRangePoint
	as
	(
	select A.serialno, ROW_NUMBER() OVER(ORDER BY Serialno) AS rownum,A.serialno as start_range
	FROM @tSerialList AS A 
	WHERE PATINDEX('%[^0-9]%',A.serialno)=0  
	and 
	NOT EXISTS (SELECT 1 FROM @tSerialList AS B WHERE 
	PATINDEX('%[^0-9]%',b.serialno)=1
	OR(
	PATINDEX('%[^0-9]%',b.serialno)=0  
	and convert(int, B.Serialno)=Convert(int, A.Serialno)-1 ))
	),
	
	--declare @endRangePoint Table (serialno varchar(30),rownum int,End_range varchar(30))
	endRangePoint
	as
	(
	select AE.serialno, ROW_NUMBER() OVER(ORDER BY Serialno) AS rownum,AE.serialno as End_range
		FROM @tSerialList AS AE 
		WHERE PATINDEX('%[^0-9]%',ae.serialno)=0 and 
		NOT EXISTS (SELECT 1 FROM @tSerialList AS BE WHERE 
		PATINDEX('%[^0-9]%',be.serialno)=1
		OR(
		PATINDEX('%[^0-9]%',be.serialno)=0  
		and convert(int, Be.Serialno)=Convert(int, Ae.Serialno)  + 1 ))   --Shivshankar : 03/22/2017 To get end value of the sequence number 
		),
		endstart
		as
		(
		select s.serialno,s.rownum,s.start_range,e.End_range from startRangePoint s
		inner join EndRangePoint e on s.rownum=e.rownum
		)
	
		insert into @returnT (iSerialNo,rownum ,start_range ,End_range )
		select serialno,rownum,start_range,End_range from endstart
		union all
	select serialno,lastrownum.nstart+ ROW_NUMBER () OVER (order by serialno) as rownum,serialno as start_range,serialno as end_range 
	from @tSerialList 
	CROSS APPLY (select top 1 rownum as nstart from endstart order by rownum desc) lastRownum
	where PATINDEX('%[^0-9]%',[@tSerialList].serialno)<>0
	
RETURN
end