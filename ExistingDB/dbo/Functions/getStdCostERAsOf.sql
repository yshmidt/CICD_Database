
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/21/17
-- Description:	get exchange rate for the standard cost using new FCSTDCOSTERHIST table 
--as of given date
--07/12/17 YS fix for the dates before the erliest date in the file
-- =============================================
CREATE FUNCTION [dbo].[getStdCostERAsOf] 
(
	-- Add the parameters for the function here
	@asofDate datetime
)
RETURNS numeric(13,5)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @returnER numeric(13,5)=0


	-- Add the T-SQL statements to compute the return value here
	-- find if the asofdate is earlier then the first date in the table
	if ( (select top 1 StdCostERUpdateDate from fcstdcosterhist order by StdCostERUpdateDate)>@asofDate )
		
		select  @returnER = M.stdcostexRate from (select top 1 stdcostexRate from fcstdcosterhist order by StdCostERUpdateDate) M
	else
		SELECT @returnER = M.stdcostexRate 
		FROM 	(select f.StdCostERUpdateDate,f.stdcostexRate,
				rank() over ( order  by StdCostERUpdateDate desc) as n
			from fcstdcosterhist f where convert(date,StdCostERUpdateDate)<=convert(date,@asofDate) ) M 
		where n=1
	

	-- Return the result of the function
	RETURN @returnER

END