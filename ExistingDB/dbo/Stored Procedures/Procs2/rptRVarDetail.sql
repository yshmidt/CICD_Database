-- =============================================
-- Author:		Debbie
-- Create date: 10/08/2013
-- Description:	Rounding Variance Detail Report by Wonum or Part_no/Rev
-- Modified:	09/26/2014 DRP: replaced the Date range filter wiht the DATEDIFF.
-- =============================================
CREATE PROCEDURE [dbo].[rptRVarDetail] 
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
	WHERE	--cast([DATETIME] as DATE) BETWEEN @lcDateStart and @lcDateEnd	--09/26/2014 DRP:  REmoved
			datediff(day,[datetime],@lcDateStart)<=0 and datediff(day,[datetime],@lcDateEnd)>=0
			and VARTYPE='RVAR'
		    
END