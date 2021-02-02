-- =============================================
-- Author:		Bill Blake
-- Create date: ????
-- Description:	Get MRP action for the given uniq_key
-- 11/25/15 YS added new parameter @showForecast to show or remove forecast actions
-- 02/27/17 YS remove conversion to DATE format. In vfp it comes as yyyy-mm-dd instead of mm/dd/yyyy
-- 07/18/17 Shivshankar P added column for checkbox property required
-- 08/21/17 Shivshankar P -- Added column for Part num revision and filters
-- 08/25/17 YS I have changed @EndRecord int to default to null. then assign max count if null is not overwritten, for use in the desctop
--- 08/25/17 YS In the desktop need to show all the actions including release. Will add another parameter @ShowRelease and default to 1
-- 09/07/17 YS if the count() of rows is 0 need to assign any number more than that or receive an error FETCH clause must be greater than zero
  --09/20/17 YS Desktop is using this SP to display actions for each @gcUniq_Key. If new UI require different action use a diffrent SP or program accordingly
  -- 07/02/19 YS remove StartRecord and EndRecord
-- =============================================
CREATE PROCEDURE [dbo].[MrpAction4UniqKeyView] 
	-- Add the parameters for the stored procedure here
	@gcUniq_Key as char(10) = ' ',
	@showForecast as bit = 1,
	@isQtyChange as bit = 0,
	@isReschedl as bit=0,
	@isCancel as bit  =0,
	--- 08/25/17 YS In the desktop need to show all the actions including release. Will add another parameter @ShowRelease and default to 1
	@showRelease bit = 1
---	@StartRecord int=0,
	-- 08/25/17 YS  I have changed @EndRecord int to default to null. then assign max count if null is not overwritten, for use in the desctop
	---@EndRecord int=10000   --Used for Desktop with default rows for web each time passing 150 (@EndRecord=150) server paging
---	@endRecord int = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- 08/25/17 YS although I do not know why we need paging for a single uniq_key, I have changed @EndRecord int to default to null. then assign max count if null is not overwritten, for use in the desctop
--07/02/19 YS remove start and end record
	--if (@endRecord is null)
	--	-- 09/07/17 YS if the count() of rows is 0 need to assign any number more than that or receive an error FETCH clause must be greater than zero
	--	select @endRecord=case when count(*)=0 then 1 else  count(*) end from mrpact where Mrpact.ACTION Not Like '%Release%'

-- 08/08/13 YS remove gldiv from mrpact
    -- Insert statements for procedure here
    --02/21/14 YS change due_date and reqDate type to "Date"
	-- 02/27/17 YS remove conversion to DATE format. In vfp it comes as yyyy-mm-dd instead of mm/dd/yyyy
	SELECT  Mrpact.uniqmrpact, Mrpact.uniq_key, Mrpact.due_date,
	--CAST(Mrpact.due_date as Date) as Due_date,
  Mrpact.startdate, Mrpact.balance, Mrpact.reqqty, Mrpact.ref, Mrpact.[action],
  Mrpact.parentpt, Mrpact.dttakeact, Mrpact.reqdate,
  --cast(Mrpact.reqdate as DATE) as reqdate, 
  Mrpact.mfgrs,
  Mrpact.[days], Mrpact.wono,  Mrpact.uniqmrpsch,
  Mrpact.prjunique, Mrpact.prefavl, Mrpact.pouniqlnno,is_forecast, 0 as IsChecked   -- 07/18/17 Shivshankar P added column for checkbox property required
  ,INVENTOR.PART_NO + '/' +  INVENTOR.REVISION  AS PartNoRevision,Mrpact.wono , totalCount = COUNT(Mrpact.uniqmrpact) OVER()  -- 08/21/17 Shivshankar P -- Added column for Part num revision
 FROM 
     mrpact LEFT JOIN INVENTOR on mrpact.UNIQ_KEY = INVENTOR.UNIQ_KEY 
 WHERE 
	 --09/20/17 YS Desktop is using this SP to display actions for each @gcUniq_Key. If new UI require different action use a diffrent SP or program accordingly
	--  Mrpact.UNIQ_KEY = CASE WHEN @gcUniq_Key=' ' THEN Mrpact.UNIQ_KEY ELSE @gcUniq_Key END AND 
	 Mrpact.UNIQ_KEY = @gcUniq_Key and
	  (@showForecast=1 or @showForecast=0 and mrpact.is_forecast=0) 
	  -- 08/25/17 YS this is not the best whay to do a where. Useing CASE in the WHere will be not optimizable
	  -- Mrpact.ACTION Like CASE WHEN @isQtyChange=0 THEN Mrpact.ACTION ELSE '%Qty%' END AND   -- 08/21/17 Shivshankar P -- Added filters
	 -- Mrpact.ACTION Like CASE WHEN @isReschedl=0 THEN Mrpact.ACTION ELSE '%RESCH%' END AND 
	 -- Mrpact.ACTION Like CASE WHEN @isCancel=0 THEN Mrpact.ACTION ELSE '%Cancel%' END   
	 --and Mrpact.ACTION Not Like '%Release%'
	 --- same as above with new parameter for release
	 AND (@isQtyChange=0 or  Mrpact.ACTION LIKE '%Qty%')
	 AND (@isReschedl=0 or Mrpact.ACTION LIKE '%RESCH%')
	 AND  (@isCancel=0 or Mrpact.ACTION LIKE '%Cancel%' ) 
	 --- 08/25/17 YS In the desktop need to show all the actions including release. Will add another parameter @ShowRelease and default to 1
	 and (@showRelease=1 or Mrpact.ACTION Not Like '%Release%')
  ORDER BY Mrpact.uniqmrpact
        --OFFSET (@StartRecord) ROWS  
        --FETCH NEXT @EndRecord ROWS ONLY;  
 

END