-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/13/17
-- Description:	get latest exchange rate for a given currency
-- =============================================
create FUNCTION [dbo].[getLatestExchangeRate] 
(
	-- Add the parameters for the function here
	@fcUsed_uniq char(10)
)
RETURNS char(10)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @fcHist_key char(10)=''

	-- Add the T-SQL statements to compute the return value here
	SELECT @fcHist_key = M.Fchist_key FROM 	(select FcHistory.Fchist_key,FcHistory.Fcused_Uniq,FcHistory.FcDateTime,FcHistory.Askprice,
				rank() over (partition by fchistory.Fcused_Uniq order by fcdatetime desc) as n
	from FcHistory where FcHistory.Fcused_Uniq=@FcUsed_Uniq  ) M 
	where n=1
	

	-- Return the result of the function
	RETURN @fcHist_key

END