-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/17/17 (Happy birthday Papa)
-- Description:	Parsing ranges of numbers and keeping alpha-numeric un-changed
--- example
/*
	declare @inputString varchar(MAX) ='500-670,abc,npt-122,123-aaaa,17-502'
	select * from dbo.fnParceRanges(@inputString ) order by rangeOrder,nseq 
	you can see that the last range includes 500 - 502 numbers, which are also part of the first range (500-670)
	if the value between the ',' contains charcaters other than numbers, we treat it as a single string, eg. npt-122

*/
-- =============================================
CREATE FUNCTION [dbo].[fnParseRanges](@inputString varchar(MAX))
RETURNS @returnT TABLE  (rangeOrder int,id varchar(30),sn varchar(30),nSeq int)
as begin
declare @tbl table	(rangeOrder int,id varchar(30))
	insert into @tbl 
		SELECT * 
			FROM dbo.fn_orderedVarcharlistToTable(@inputString,',')
	
	;with
	 tblRange AS(
		SELECT rangeOrder, ID, CAST(SUBSTRING(id,1,CHARINDEX('-',Id,1)-1) AS INT) AS StartNumber, CAST(SUBSTRING(Id,CHARINDEX('-',Id,1)+1, LEN(id)-CHARINDEX('-',id,1)) AS INT) AS EndNumber 
			FROM @tbl tbl 
			WHERE Id LIKE '%-%' 
			AND Id NOT LIKE '%[a-zA-Z]%'
	)
	, Range AS(
		SELECT rangeOrder, StartNumber AS Serialno
			FROM tblRange t 
		UNION ALL
		SELECT R.rangeOrder, R.Serialno+1
			FROM [Range] R INNER JOIN tblRange t1 ON r.rangeOrder = t1.rangeOrder
			WHERE r.Serialno < t1.EndNumber 
	)
	INSERT INTO @returnT (rangeOrder,id,sn) select rangeOrder,serialno,serialno from Range OPTION (MAXRECURSION 3200)
	insert into @returnT (rangeOrder,id,sn) select rangeOrder,id,id from @tbl where Id LIKE '%[a-zA-Z]%'
	--remove duplicates
	;with
	removeDupl
	as
	(
	select ROW_NUMBER() over (partition by sn order by rangeOrder) as n,rangeOrder,sn
	from @returnT)
	delete from @returnT  where exists (select 1 from removeDupl r where  r.rangeOrder=[@returnT].rangeOrder and r.sn=[@returnT].sn and r.n<>1)


	;with finalReturn
	as
	(
	select rangeOrder,id,dbo.padl(sn,30,'0') as sn,ROW_NUMBER() OVER (order by rangeOrder,dbo.padl(sn,30,'0')) n
	from @returnT
	)

	update @returnT set sn=f.sn, nSeq=f.n
	from finalReturn F where f.id=[@returnT].id and f.rangeOrder=[@returnT].rangeOrder
	
	RETURN

end 