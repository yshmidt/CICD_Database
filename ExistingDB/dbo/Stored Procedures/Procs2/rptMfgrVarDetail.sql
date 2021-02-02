-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/28/2013
-- Description:	Manufacturer Variance Detail Report by Wonum or Part_no/Rev
--- In VFP report froms MANFVAR1 and MANFVAR2. Can use the same SP and the same report, the difference is in the order
-- Modified:	09/27/2013 DRP: Needed to change the parameter names from @StartDate/@EndDate to @lcDateStart/@lcDateEnd so that they would work with the webmanex Date Range feature
--								Also changed the DateTime field name to be just Date and I also re-arranged the results putting the detailed the users would most 
--								likely want to see first and additional fields at the end . . . it looked better on the QuickViews
--				10/08/2013 DRP:  I believe that we pull the Rounding variance from the Mfgrvar table so I am going to update the below so that it does not pull the vartype.RVAR
--				09/26/2014 DRP: replaced the Date range filter wiht the DATEDIFF.
-- =============================================
CREATE PROCEDURE [dbo].[rptMfgrVarDetail] 
	-- Add the parameters for the stored procedure here
	@lcDateStart Date = null, 
	@lcDateEnd Date = null
 , @userId uniqueidentifier=null 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT @lcDateStart = CASE WHEN @lcDateStart IS NULL THEN DATEADD(Day,7,GETDATE()) ELSE @lcDateStart END, 
		   @lcDateEnd= CASE WHEN @lcDateEnd IS NULL THEN GETDATE() ELSE @lcDateEnd END ;
	
	SELECT	Wono, [dateTime] as Date,ISNULL(Inventor.part_no,space(25)) as part_no,ISNULL(Inventor.Revision,space(8)) as revision
			,isnull(inventor.descript,CAST('Missing part Infotmation' as CHAR(45))) as Descript , Issuecost, Bomcost, ROUND(TotalVar,2) AS TotalVar, UniqMfgVar 
	FROM	mfgrvar LEFT OUTER JOIN inventor ON mfgrvar.uniq_key = inventor.uniq_key
	WHERE	--cast([DATETIME] as DATE) BETWEEN @lcDateStart and @lcDateEnd	--09/26/2014 DRP :  Removed
			datediff(day,[datetime],@lcDateStart)<=0 and datediff(day,[datetime],@lcDateEnd)>=0
	--10/08/2013L  added the  VARTYPE='RVAR'
			and VARTYPE<>'RVAR'
 
		    
END