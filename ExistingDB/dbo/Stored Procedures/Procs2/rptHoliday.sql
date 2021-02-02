    
-- =============================================          
-- Author:  Debbie Peltier          
-- Create date:	12/19/2013         
-- Description:	Get the details for the Holidays List report 
-- Reference:		holidays.rpt     
-- Modified: 
-- =============================================          
create PROCEDURE [dbo].[rptHoliday]

 @lcYear varchar(max) = 'All'
,@UserId uniqueidentifier =NULL  -- userid for security

as
Begin

--compiles the Year selection list
declare @Year table(Year char(4))
if @lcYear is not null and @lcYear <> ''  and @lcYear <>'All'
	insert into @Year select * from dbo.[fn_simpleVarcharlistToTable](@lcYear,',')
	

SELECT	HOLIDAY, DATE, CAST(YEAR(DATE) AS char(4)) AS YEAR
FROm	HOLIDAYS
where	1 = case when @lcYear = 'All' then 1 when CAST(Year(Date) as CHAR(4)) IN(select Year from @Year) then 1 else 0 end 
ORDER BY YEAR

end
