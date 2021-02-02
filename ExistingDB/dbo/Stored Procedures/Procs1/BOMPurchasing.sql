
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/09/2012
-- Description:	BOM Purchasing view
-- MODIFIED:	03/20/14 YS check if gridid is passed , if not do not return extra set
--				02/17/15 VL	Added 10th parameter to fn_PhantomSubSelect() to get inactive parts or no, and added @lcStatus parameter, 'Active' parts as default
-- =============================================
CREATE PROCEDURE [dbo].[BOMPurchasing] 
	-- Add the parameters for the stored procedure here
	@lcBomParent char(10)=' ',@UserId uniqueidentifier=NULL, @gridId varchar(50) = null, @dDate smalldatetime = '19000101', @lcStatus char(8) = 'Active'
AS
BEGIN
	-- 07/27/2012 YS added new @dDate parameter, 
	-- by default request parts, which are current for today's date  (cannot use GETDATE() function when assign a value to a parameter) 
	-- if user pass NULL all the parts has to be included
	-- otherwise only those parts that are active for the given @dDate
	
	--- this sp will explode BOM including phantom and make parts, but not make buy
	-- find required quantites to build one unit taking run scrap and setup scrap into concideration
	-- I am using function created by Vicky for the Kitting module
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	
	SET NOCOUNT ON;
	
	--  07/27/12 DATEADD(day, DATEDIFF(day, 0, @dDate), 0) to get rid of the time pasrt
    SET @dDate = CASE WHEN @dDate='19000101' THEN DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0) 
					WHEN  NOT @dDate IS NULL THEN DATEADD(day, DATEDIFF(day, 0, @dDate), 0) ELSE @dDate END
	DECLARE @checkDate char(1)
	SET @checkDate=CASE WHEN  @dDate IS NULL THEN 'F' ELSE 'T' END
    -- Insert statements for procedure here
    --07/27/12 YS use @checkDate and @dDate when pass parameters to fn_phantomSubSelect instead of hard coded values.
	-- 02/17/15 VL added 10th paramete to get inactive parts or not
	select SUM(reqqty) as [Total Req Qty],Count(Uniq_key) as [Number Occurred],Part_no,Revision,Custno,Custpartno,
		Custrev,Part_class,Part_type,Descript,Uniq_key,Part_sourc,U_of_meas ,StdCost,MatlType  
		from fn_phantomSubSelect( @lcBomParent,1,@checkDate,@dDate,'T','ALL','F',0,0,CASE WHEN @lcStatus = 'Active' THEN 0 ELSE 1 END) 
		GROUP BY Part_no,Revision,Custno,Custpartno,
		Custrev,Part_class,Part_type,Descript,Uniq_key,Part_sourc,U_of_meas ,StdCost,MatlType
		
	--3/20/2012 added by David Sharp to return grid personalization with the results
	-- 03/20/14 YS check if gridid is passed , if not do not return extra set
	IF (@gridId is not null)
	EXEC MnxUserGetGridConfig @userId, @gridId
	
END