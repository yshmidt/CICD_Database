-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/29/2013
-- Description:	Not Posted Cost Adjustment
--- In VFP report froms INVCADJ2   
-- Modified:	09/27/2013 DRP: Needed to change the parameter names from @StartDate/@EndDate to @lcDateStart/@lcDateEnd so that they would work with the webmanex Date Range feature
--								Also changed the DateTime field name to be just Date and I also re-arranged the results putting the detailed the users would most 
--								likely want to see first and additional fields at the end . . . it looked better on the QuickViews
--				09/26/2014 DRP: replaced the Date range filter wiht the DATEDIFF. 

-- =============================================
CREATE PROCEDURE [dbo].[rptCostAdjNotPosted] 
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
	SELECT distinct warehous.WAREHOUSE,updtstd.rundate,isnull(Inventor.part_no,space(25)) as Part_no,ISNULL(Inventor.Revision,space(8)) as revision
			,isnull(inventor.descript,space(45)) as Descript,UPDTSTD.ROLLTYPE,UPDTSTD.OLDMATLCST,UPDTSTD.NEWMATLCST,UPDTSTD.CHANGEAMT,UPDTSTD.WH_GL_NBR
	FROM updtstd 
		LEFT OUTER JOIN Inventor on UpdtStd.Uniq_key=Inventor.Uniq_key
		LEFT OUTER JOIN Glreleased ON updtstd.UNIQ_UPDT = RTRIM(GlReleased.cdrill) and GlReleased.TransactionType = 'COSTADJ' 
		left outer join warehous on UPDTSTD.UniqWh = WAREHOUS.UNIQWH
	WHERE (updtstd.is_rel_gl =0 OR (updtstd.is_rel_gl = 1 and Glreleased.GlrelUnique IS not NULL))
	--and CAST(UpdtDate as date) BETWEEN @lcDateStart and @lcDateEnd ORDER BY Part_no	--09/26/2014 DRP:  Removed
	and datediff(day,UpdtDate,@lcDateStart)<=0 and datediff(day,UpdtDate,@lcDateEnd)>=0
		    
END