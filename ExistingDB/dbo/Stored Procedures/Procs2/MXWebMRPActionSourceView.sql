-- =============================================
-- Author: Shivshankar P
-- Create date: 07/19/2018 
-- Description:	SP to view source information for the MRP action copy of (MRPActionSourceView)
-- 02/27/17 YS remove conversion to DATE format. In vfp it comes as yyyy-mm-dd instead of mm/dd/yyyy
-- 07/18/17 Shivshankar P Merged the columns Part_no and Revision
--- 08/23/17 Shivshankar P :  Added OFFSET,totalCount and FETCH NEXT for server paging 
-- 08/25/17 YS changed @EndRecord int to default to null. then assign max count if null is not overwritten, for use in the desctop
-- =============================================
CREATE PROCEDURE [dbo].[MXWebMRPActionSourceView] 
	-- Add the parameters for the stored procedure here
	@lcUniq_key char(10)=' ',
	@StartRecord int=1,
	-- 08/25/17 YS changed @EndRecord int to default to null. then assign max count if null is not overwritten, for use in the desctop
	--@EndRecord int= 10000    --Used for Desktop with default rows for web each time passing 150 (@EndRecord=150) server paging
	@endRecord int = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- 08/25/17 YS changed @EndRecord int to default to null. then assign max count if null is not overwritten, for use in the desctop
	if (@endRecord is null)
		select @endRecord=count(*) from mrpsch2

    -- Insert statements for procedure here
	-- get demands from forecast (did ot convert forecast yet)
	;
	WITH tTemp AS 
	(
	SELECT CAST(LEFT(Ref,12) as CHAR(17)) AS WoNo, 
		- ReqQty AS ReqQty, ReqDate,
		-- 02/27/17 YS remove conversion to DATE format. In vfp it comes as yyyy-mm-dd instead of mm/dd/yyyy
		--CAST(ReqDate as DATE) as ReqDate, 
		CAST('Demand From Forecast' as CHAR(35)) AS CustName, 
		MrpSch2.Mfgrs, @lcUniq_key as ParentPt 
	FROM MrpSch2 
	WHERE MrpSch2.Uniq_Key = @lcUniq_Key 
		AND LEFT(Ref,2) = 'FC' 
	-- Get Demands from Sales Orders (MAKE parts)
	UNION ALL
	SELECT CAST(SUBSTRING(Ref,5,12) as CHAR(17)) AS WoNo, 
		- ReqQty AS ReqQty,	ReqDate,
		-- 02/27/17 YS remove conversion to DATE format. In vfp it comes as yyyy-mm-dd instead of mm/dd/yyyy
		--CAST(ReqDate as DATE) as ReqDate, 
		 CustName, MrpSch2.Mfgrs, @lcUniq_key as ParentPt 
	FROM MrpSch2 INNER JOIN SoMain ON SUBSTRING(Ref,7,10)=SoMain.SoNo
	INNER JOIN Customer ON Somain.CUSTNO =Customer.CUSTNO 
	WHERE MrpSch2.Uniq_Key = @lcUniq_Key 
		AND LEFT(Ref,6) = 'Dem SO' 
    --Get Demands from Sales Orders (BUY parts)
    UNION ALL
	SELECT CAST(LEFT(Ref,12) as CHAR(17)) AS WoNo, 
		- ReqQty AS ReqQty, ReqDate,
		-- 02/27/17 YS remove conversion to DATE format. In vfp it comes as yyyy-mm-dd instead of mm/dd/yyyy
		--CAST(ReqDate as DATE) as ReqDate, 
		 CustName, Mfgrs, @lcUniq_key as ParentPt 
	FROM MrpSch2 INNER JOIN SoMain ON SoMain.SoNo = SUBSTRING(Ref,3,10)
	   INNER JOIN Customer ON Somain.CUSTNO =Customer.Custno  
	WHERE MrpSch2.Uniq_Key = @lcUniq_Key 
		AND LEFT(Ref,2) = 'SO' 
	-- Get Demands from Work Orders
	UNION ALL
	SELECT CAST(SUBSTRING(Ref,5,12) as char(17)) AS WoNo, 
		- ReqQty AS ReqQty, ReqDate,
		-- 02/27/17 YS remove conversion to DATE format. In vfp it comes as yyyy-mm-dd instead of mm/dd/yyyy
		--CAST(ReqDate as DATE) as ReqDate, 
		CustName, Mfgrs, ParentPt 
	FROM MrpSch2 INNER JOIN WoEntry ON WoEntry.WoNo = SUBSTRING(Ref,7,10)
	INNER JOIN Customer ON Woentry.CUSTNO =Customer.Custno 
	WHERE MrpSch2.Uniq_Key = @lcUniq_Key 
		AND LEFT(Ref,6) = 'Dem WO' 
		
	-- 04/27/04 WDB New code to get demands from shortages
	-- 11/10/05 WDB Changed SQL because "Shortage" truncated in some cases to "Shortag"
	UNION ALL
	SELECT CAST(RTRIM(Ref) as CHAR(17)) AS WoNo, 
		- ReqQty AS ReqQty,   ReqDate,
		-- 02/27/17 YS remove conversion to DATE format. In vfp it comes as yyyy-mm-dd instead of mm/dd/yyyy
		--CAST(ReqDate as DATE) as ReqDate, 
		CustName, Mfgrs, ParentPt 
	FROM MrpSch2 INNER JOIN WoEntry ON WoEntry.WoNo = SUBSTRING(Ref,3,10)
	INNER JOIN Customer ON Woentry.CUSTNO =Customer.Custno 
	WHERE MrpSch2.Uniq_Key = @lcUniq_Key 
		AND LEFT(Ref,2) = 'WO' 
		AND CHARINDEX('Short' , Ref )<>0
	UNION ALL
	-- Get Demands from Proposed Work Orders
	SELECT CAST(SUBSTRING(Ref,5,12) as CHAR(17)) AS WoNo, 
		- ReqQty AS ReqQty, ReqDate, 
		-- 02/27/17 YS remove conversion to DATE format. In vfp it comes as yyyy-mm-dd instead of mm/dd/yyyy
		--CAST(ReqDate as DATE) as ReqDate, 
		 CAST('Demand from Proposed Work Order' as CHAR(35)) AS CustName, 
			Mfgrs, ParentPt 
	FROM MrpSch2 
	WHERE MrpSch2.Uniq_Key = @lcUniq_Key
		AND CHARINDEX('PWO' , Ref)<>0
		AND ReqQty < 0 
	UNION ALL
	-- 05/24/04 WDB New Code to get demands from Safety Stock
	SELECT CAST(RTRIM(Ref) As CHAR(17)) WoNo, 
		- ReqQty as ReqQty, ReqDate,
		-- 02/27/17 YS remove conversion to DATE format. In vfp it comes as yyyy-mm-dd instead of mm/dd/yyyy
		--CAST(ReqDate as DATE) as ReqDate, 
		  CAST(' ' as CHAR(35)) AS CustName, 
		 Mfgrs, @lcUniq_key as ParentPt 
	FROM MrpSch2 
	WHERE MrpSch2.Uniq_key = @lcUniq_key 
		AND CHARINDEX('Safety',Ref)<>0 
	-- 11/15/04 WDB New code for demands from  RMAs
	UNION ALL
	SELECT CAST('RMA-SO' + SUBSTRING(Ref,4,10) as char(17)) AS WoNo, 
		- ReqQty AS ReqQty, ReqDate, 
		-- 02/27/17 YS remove conversion to DATE format. In vfp it comes as yyyy-mm-dd instead of mm/dd/yyyy
		--CAST(ReqDate as DATE) as ReqDate, 
		CustName, Mfgrs, @lcUniq_key as ParentPt 
	FROM MrpSch2 INNER JOIN SoMain ON SoMain.SoNo = SUBSTRING(Ref,4,10)
	INNER JOIN Customer ON Somain.CUSTNO =Customer.CUSTNO 
	WHERE MrpSch2.Uniq_Key = @lcUniq_Key 
		AND LEFT(Ref,3) = 'RMA' 
	UNION ALL	 
	-- 02/11/08 WDB New code for other RMAs
	SELECT CAST(SUBSTRING(Ref,5,13) as CHAR(17)) AS WoNo, 
		- ReqQty AS ReqQty, ReqDate, 
		-- 02/27/17 YS remove conversion to DATE format. In vfp it comes as yyyy-mm-dd instead of mm/dd/yyyy
		--CAST(ReqDate as DATE) as ReqDate, 
		CustName,Mfgrs, @lcUniq_key as ParentPt 
	FROM MrpSch2 INNER JOIN SOMAIN ON Somain.SONO=RIGHT(RTRIM(ref),10) 
	INNER JOIN CUSTOMER ON Somain.CUSTNO =Customer.Custno
	WHERE MrpSch2.Uniq_Key = @lcUniq_Key 
		AND LEFT(Ref,7) = 'Dem RMA' )
	SELECT Wono as Work_order,ReqQty as Req_Qty,ReqDate as Req_Date,CustName as Customer,Inventor.Part_no,Inventor.Revision,Mfgrs,ParentPt,
	      Inventor.Part_no + '/' + Inventor.Revision AS Partno_view,   -- 07/18/17 Shivshankar P Merged the columns Part_no and Revision
		  totalCount = COUNT(Wono) OVER()    --- 08/23/17 Shivshankar P : TotalCount row count 
		  FROM tTEMP INNER JOIN INVENTOR ON tTemp.parentpt=inventor.uniq_key
		    ORDER BY Wono  --- 08/23/17 Shivshankar P :  Add fetch,totalCount and next for server paging 
                    OFFSET (@StartRecord-1) ROWS  
                    FETCH NEXT @EndRecord ROWS ONLY;  
	
END