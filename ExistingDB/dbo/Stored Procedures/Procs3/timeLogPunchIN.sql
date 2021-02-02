-- =============================================
-- Author:		David Sharp
-- Create date: 6/22/2012
-- Description:	Punch a user in to a job
-- 08/27/15 YS get number for a work center from dept_qty table if not avaialble from depts table
-- will make no difference after Vicky changes the calculation for the JC module where the cost will be calculated by WC, not differentiate by Number on the routing
-- 11/18/15 YS make sure that work order has leading zeros 
-- 8/23/2016 Raviraj P : Added a output parameter to get current inserted record
-- 8/23/2016 Raviraj P : Generating unique key & setting the value to output paramter @uniqLogin
-- 8/23/2016 Raviraj P : setting the value to output paramter @uniqLogin to its uniqkey
-- 12/16/16 Raviraj P : Passing sequence number from user interface
-- 5/31/17 Raviraj P : Passing originalDateIn as users system date time,currentily it was taking server time
-- =============================================
CREATE PROCEDURE [dbo].[timeLogPunchIN] 
	-- Add the parameters for the stored procedure here
	@userId uniqueidentifier,
	@record varchar(10),
	@dept_id varchar(10),
	@timeType varchar(10),
	@isHoliday bit = 0,
	@deleted bit = 0,
	@comment varchar(MAX)='',
	@originalDateIn datetime,      --5/31/17 Raviraj P : Passing originalDateIn as users system date time,currentily it was taking server time
	@number int,				   -- 12/16/16 Raviraj P : Passing sequence number from user interface
	@uniqLogin char(10) ='' OUTPUT -- 8/23/2016 Raviraj P : Added a output parameter to get current inserted record
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @initials varchar(4)
	SELECT @initials = Initials FROM aspnet_Profile WHERE UserId=@userId
	-- 11/18/15 YS make sure that work order has leading zeros
	set @record=case when @record='' then @record else dbo.padl(rtrim(ltrim(@record)),10,'0') end
	-- 12/16/16 Raviraj P : Passing sequence number from user interface
	---- 08/27/15 YS get number for a work center from dept_qty table if not avaialble from depts table
	--DECLARE @number int 
	----SELECT @number=NUMBER FROM TMLOGTP WHERE TMLOGTPUK = @timeType
	--IF EXISTS (select TOP 1 Number 
	--		FROM Dept_qty WHERE Wono=@record and DEPT_ID=@dept_id
	--		ORDER BY Number)
	--	select @Number=D.Number FROM
	--		(select TOP 1 Number 
	--		FROM Dept_qty WHERE Wono=@record and DEPT_ID=@dept_id
	--		ORDER BY Number) D
	--ELSE
	--	select @Number=Depts.Number FROM Depts WHERE DEPT_ID=@dept_id
			
	--SET @number=ISNULL(@number,0)
	set @uniqLogin =  dbo.fn_GenerateUniqueNumber()  -- 8/23/2016 Raviraj P : Generating unique key & setting the value to output paramter @uniqLogin
	-- 08/27/15 YS
	-- Insert statements for procedure here
    INSERT INTO DEPT_CUR
		(WONO
		,DEPT_ID
		,NUMBER
		,originalDateIn
		,DATE_IN
		,inUserId
		,LOG_INIT
		,TMLOGTPUK
		,IS_HOLIDAY
		,UNIQLOGIN
		,uDeleted
		,comment)
	VALUES
		(@record
		,@dept_id
		,@number
		,@originalDateIn --5/31/17 Raviraj P : Passing originalDateIn as users system date time,currentily it was taking server time
		,@originalDateIn --5/31/17 Raviraj P : Passing originalDateIn as users system date time,currentily it was taking server time
		,@userId
		,@initials
		,@timeType
		,@isHoliday
		,@uniqLogin -- 8/23/2016 Raviraj P : setting the value to output paramter @uniqLogin to its uniqkey
		,@deleted
		,@comment)
		
END