-- =============================================
-- Author:		David Sharp
-- Create date: 5/2/2012
-- Description:	separates a string of ref desg into a table of ref desg
-- Requirements: 1. The ref desg CANNOT have a number in the non-incrementing portion (i.e. R, C, U, etc)
--				 2. Ranged items (separated by @rangeDel) must be in ascending order
--				 3. Ref Desgs can be added in any order, but will be stored in the order they are added
--				 4. All items in a range (separated by @rangeDel) use the alpha character from the first item regardless what is set for the second ref desg
--				 5. The user can provide a different @itemDel and @rangeDel so long as they are NOT part of ANY ref desg
--			Adjustment to above prerequisites:
-- Sample values for Ref Des entered into XL and how the system will treat these values
------------------------------------------------------------------------------------------
--	XL Values									: Parsed Values
-------------------------------------------------------------------------------------------
-- 1. a1-10										: Range a1 trhough a10
-- 2. d5-7										: Range d5 through d7
-- 3. abd9-15									: Range abd9 through abd15
-- 4. c50-10									: Single value c50-10
-- 5. c50-1										: Single value c50-1
-- 6. 10rr50-10									: Single value 10rr50-10
-- 7. b-10										: Single value b-10 	
-- 8. cdf-jhsss									: Single value cdf-jhsss
-- 9. dd1-msdhe									: Single value dd1-msdhe
-- 10. egh2-xx6									: Single value egh2-xx6
-- 11. egh2-egh12								: Range egh2 through egh12 
-- 12. ff4-8jj									: Single value ff4-8jj
-- 13. asd122									: Single value asd122
-- 14. U 50										: Single value U 50
-- 15. For U9									: Single value For U9
-- 16. 1-12										: Single value 1-12
-- 17. 1a2-1a12									: Range 1a2 through 1a12	
-- 18. 12a1-111292aaa							: Single value 12a1-111292aaa
-- 19. 1f1-10									: Range 1f1 through 1f10
-- 06/03/2013 YS trying to avoid too many IF and WHILE. Cannot say that the code looks happy, I think that the proper place for this function is to parse in .net
-- proper tool regex, maybe will try using CLR RegEx later
-- 04/21/15 YS  if @refDesgs = '-6.0, -8.0, -9.0' failed with 'Invalid length parameter passed to the RIGHT function.' error
-- 20. -5.0										: Single value -5.0
-- =============================================
CREATE FUNCTION [dbo].[fn_parseRefDesgString] (@rowId uniqueidentifier,@refDesgs varchar(max),@itemDel varchar(1)=',',@rangeDel varchar(1)='-')
/* 06/03/13 YS  added nSeq Field to be able to save into ImportBomRef table as 'RefOrd' column and can be used in BomRef table as 'Nbr' column */
RETURNS @refDesg TABLE (rowId uniqueidentifier,ref varchar(max),nSeq int) 
AS
BEGIN 
/* 06/03/13 YS new code */
DECLARE @TIn Table (RowValues varchar(max),nRow int Identity)
 
INSERT INTO @TIn (RowValues) SELECT RTRIM(LTRIM(ID)) FROM fn_simpleVarcharlistToTable(@refDesgs,@itemDel);

;WITH RefDesPrep
AS(
SELECT RowValues,nRow,Header,Tail,DashPosition, Prefix,nStart,Sufix,nEnd,
cast(CASE WHEN nStart=0 OR nEnd=0 THEN RowValues 
	WHEN Prefix<>Sufix THEN RowValues 
	WHEN Prefix=Sufix and nEnd<=nStart THEN RowValues 
	ELSE '' END as varchar(max)) as FinalValue	
FROM
(
SELECT RowValues,nRow,Header,Tail,DashPosition, Prefix,nStart,
CAST(CASE WHEN nStart=0 THEN '' 
		WHEN ISNUMERIC(Tail)=1 THEN Prefix 
		ELSE 
		LEFT(Tail,LEN(Tail) - (PATINDEX('%[^0-9]%',REVERSE(Tail)) - 1)) END as varchar(max)) as Sufix,
CAST(CASE WHEN nStart=0 THEN 0
			WHEN ISNUMERIC(Tail)=1 THEN Tail
			ELSE RIGHT(Tail,(PATINDEX('%[^0-9]%',REVERSE(Tail)) - 1)) END as int) as nEnd
FROM
(
-- 04/21/15 YS fix when @refDesgs = '-6.0, -8.0, -9.0' failed with 'Invalid length parameter passed to the RIGHT function.' error
--- check DashPosition>1 instead of <>0
SELECT RowValues,nRow,Header,Tail,DashPosition, 
CAST(CASE WHEN DashPosition>1 THEN LEFT(Header,LEN(Header) - (PATINDEX('%[^0-9]%',REVERSE(Header)) - 1)) ELSE '' END as varchar(max)) as Prefix,
CAST(CASE WHEN DashPosition>1 AND ISNUMERIC(Header)<>1 and PATINDEX('%[^0-9]%',REVERSE(Header))<>1 THEN RIGHT(Header,(PATINDEX('%[^0-9]%',REVERSE(Header)) - 1)) ELSE '0' END as int) as nStart
FROM(
SELECT RowValues,nRow,
-- 04/21/15 YS added OR LEFT(RowValues,1)='-' to treat values like '-5.0' as a single value not a part of the range
	CAST(CASE WHEN CHARINDEX(@rangeDel,RowValues)=0 OR LEFT(RowValues,1)='-' THEN RowValues
		ELSE SUBSTRING(RowValues,1,CHARINDEX(@rangeDel,RowValues)-1) END as varchar(max)) as Header,
	CAST(CASE WHEN CHARINDEX(@rangeDel,RowValues)=0 OR LEFT(RowValues,1)='-' THEN ''
		ELSE SUBSTRING(RowValues,CHARINDEX(@rangeDel,RowValues)+1,LEN(RowValues)) END as varchar(max)) as Tail,
		 CHARINDEX(@rangeDel,RowValues) as DashPosition
		FROM @tIN	)a 
)b	
)c	),
RefRanges
	as 
	( 		 
  Select Prefix,nStart As [Seq],CAST(LTRIM(Prefix)+CAST(nStart as varchar(10)) as varchar(max)) as FinalValue,nRow
		FROM RefDesPrep WHERE FinalValue=''
	Union All
    Select T.Prefix,R.Seq+1 as [Seq],CAST(LTRIM(T.Prefix)+CAST(R.Seq+1 as varchar(10)) as varchar(max)) as FinalValue,T.nRow
    From RefDesPrep T INNER JOIN RefRanges R ON  R.nRow=t.nRow and R.Prefix=T.Prefix 
   Where R.[Seq] <  T.nEnd AND T.nEnd <>0 and T.FinalValue=''
   
   ),
   AllRef
   As
   (
   select FinalValue ,nRow,Seq 
   FROM RefRanges
   union all
   select FinalValue,nRow,0 as seq
   from RefDesPrep where FinalValue<>''
)
INSERT INTO @refDesg (rowId,ref,nSeq) 
	select @rowId,FinalValue,ROW_NUMBER() over (order by nRow,seq) as nseq  from AllRef
     OPTION(MAXRECURSION 32000)



/* 06/03/13 YS code prior to 06/03/2013 */
		-- Add the SELECT statement with parameter references here
	--DECLARE @element varchar(max),@index int,@count int,@left varchar(max),@right varchar(max),@root varchar(max),@position int, @refLen int, @numPlace int
	--DECLARE @elements TABLE (Element varchar(max),[Count] int)
	
	--SELECT @refLen= character_maximum_length FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='BOM_REF' AND COLUMN_NAME='REF_DES'

	----Check to see if the range delimitor exists, if not, parse the string
	--SET @index = charindex(@rangeDel, @element)
	--IF @index<0
	--BEGIN
	--	INSERT INTO @refDesg
	--	SELECT @rowId,id FROM fn_simpleVarcharlistToTable(@refDesgs,@itemDel)
	--END
	--ELSE
	--BEGIN
	--	--Get all Ref Desg before the last comma
	--	WHILE (len(@refDesgs) > 0 AND charindex(@itemDel, @refDesgs) > 0)
	--	begin
	--		--Get the item before the next @itemDel
	--		set @element = substring(@refDesgs, 0, charindex(@itemDel, @refDesgs))
	--		-- Check if @element contains a number
	--		IF PATINDEX('%[0-9]%',@element) > 0 
	--		BEGIN
	--			--Check to see if the @rangDel is present in the item
	--			if (charindex(@rangeDel, @element) > 0)
	--			begin
	--				set @index = charindex(@rangeDel, @element)
	--				set @left = left(@element, @index - 1)
	--				--Check to see if the @left has a number, ABC-5.  If not, INSERT @element
	--				IF PATINDEX('%[0-9]%',@left) > 0 
	--				BEGIN
	--					set @right = substring(@element, @index + 1, len(@element) - len(@left))
	--					-- Find the first numeric character on the left of the range delimitor
	--					set @position = 0
	--					while (isnumeric(substring(@left, @position, 1)) = 0)
	--					begin
	--						set @position = @position + 1
	--					end
	--					SET @root = REPLACE(@left,SUBSTRING(@left, @position, LEN(@left)),'')
	--					set @left = substring(@left, @position, len(@left))
	--					-- Find the first numeric character on the right of the range delimitor
	--					set @position = 0
	--					while (isnumeric(substring(@right, @position, 1)) = 0)
	--					begin
	--						set @position = @position + 1
	--					end
	--					set @right = substring(@right, @position, len(@right))
	--					set @count = cast(@right as int) - cast(@left as int) + 1
	--					--Enter the Ref Desg into Ref Desg Table
	--					SET @position = 0
	--					WHILE (@position < @count)
	--					BEGIN
	--						INSERT INTO @refDesg
	--						SELECT   @rowId,RTRIM(LTRIM(@root + CAST(CAST(@left AS int) + @position AS varchar(20))))
	--						SET @position = @position + 1
	--					END
	--				END
	--				ELSE
	--					INSERT INTO @refDesg SELECT @rowId,RTRIM(LTRIM(@element))
	--					set @refDesgs = replace(@refDesgs, @element + @itemDel, '')
	--			end
	--			else
	--				INSERT INTO @refDesg SELECT @rowId,RTRIM(LTRIM(@element))
	--				set @refDesgs = replace(@refDesgs, @element + @itemDel, '')				
	--		END
	--		ELSE
	--			INSERT INTO @refDesg SELECT @rowId,RTRIM(LTRIM(@element))
	--		--Reset @input to start the loop over
	--		set @refDesgs = replace(@refDesgs, @element + @itemDel, '')
	--	end --end WHILE (len(@refDesgs) > 0 AND charindex(@itemDel, @refDesgs) > 0)
		
	--	IF PATINDEX('%[0-9]%',@refDesgs) > 0 
	--	BEGIN
	--		--Get all Ref Desg after the last comma
	--		if (len(@refDesgs) > 0)
	--		begin
	--			set @element = @refDesgs
	--			--Check to see if the @rangDel is present in the item
	--			if (charindex(@rangeDel, @element) > 0)
	--			begin
	--				set @index = charindex(@rangeDel, @element)
	--				set @left = left(@element, @index - 1)
	--				IF PATINDEX('%[0-9]%',@left) > 0 
	--				BEGIN
	--					set @right = substring(@element, @index + 1, len(@element) - len(@left))
	--					-- Find the first numeric character on the left of the range delimitor
	--					set @position = 0
	--					while (isnumeric(substring(@left, @position, 1)) = 0)
	--					begin
	--						set @position = @position + 1
	--					end
	--					SET @root = REPLACE(@left,SUBSTRING(@left, @position, LEN(@left)),'')
	--					set @left = substring(@left, @position, len(@left))
	--					-- Find the first numeric character on the right of the range delimitor
	--					set @position = 0
	--					while (isnumeric(substring(@right, @position, 1)) = 0)
	--					begin
	--						set @position = @position + 1
	--					end
	--					set @right = substring(@right, @position, len(@right))

	--					set @count = cast(@right as int) - cast(@left as int) + 1
	--					--Enter the Ref Desg into Ref Desg Table
	--					SET @position = 0
	--					WHILE (@position < @count)
	--					BEGIN
	--						INSERT INTO @refDesg
	--						SELECT   @rowId,RTRIM(LTRIM(@root + CAST(CAST(@left AS int) + @position AS varchar(20))))
	--						SET @position = @position + 1
	--					END
	--				END
	--				ELSE
	--					INSERT INTO @refDesg SELECT @rowId,RTRIM(LTRIM(@element))
	--			end
	--			else
	--			begin
	--				INSERT INTO @refDesg SELECT @rowId,RTRIM(LTRIM(@element))
	--			end
	--		end
	--	END
	--	ELSE
	--		INSERT INTO @refDesg SELECT @rowId,RTRIM(LTRIM(@refDesgs))
	--END
	RETURN
END