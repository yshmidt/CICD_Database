
-- =============================================
-- Author:			Yelena Shmidt
-- Create date:		01/13/2014
-- Description:		Costed Top Assembly Part Usage report
-- Reports Using:   VFP report was bmrpt11 
-- Modifications:	--02/20/15 YS Vicky added new parameter to fn_phantomSubSelect, have to provide it here
-- 08/16/17 VL added functional currency code
-- =============================================
CREATE procedure [dbo].[rptBomTopCostedAssembly]
--declare
			@lcUniqkey char(10) = ''		--- uniq_key for top assembly 
			,@lcIgnore as char(20) = 'No'	-- used within the report to indicate if the user elects to ignore any of the scrap settings.
			,@lcQty numeric(9,0) = '1'	-- user would populate the desired qty/bld qty here
			,@lcSupUsedKit char(18) = 'No' -- here the report will use the system default for Suppress Not Used in Kit, but the users have the option to change manually within the report. 
			,@userId uniqueidentifier=NULL	  --  @UserId - Will be used by WEB fron to identify if the user has rights to see the BOM.
				
as
begin
				
			-- SET NOCOUNT ON added to prevent extra result sets from
			-- interfering with SELECT statements.
			SET NOCOUNT ON;
			

			--- this sp will 
			----- 1. find BOM information and explode PHANTOM and Make parts. If the make part has make/buy flag  do not explode ( @IncludeMakeBuy=0)
			----  2. calculate the cost
		
		--The below is used to indicate to take the active BOM as of today's date (computer date)
		declare @lcDate smalldatetime,
					@cChkDate char(1)='T' , @cMake char(3)='T',@cMakeBuy char(1)='F',@lIgnoreScrap bit = 0, @lLeaveParentPart bit = 0,
					 @cKitInUse char(3)
		select @lcDate = DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0)
		
		
		select @cKitInUse = (select 
					case when @lcSupUsedKit = 'Use System Default' OR @lcSupUsedKit = '' OR @lcSupUsedKit IS NULL 
							then 
								CASE WHEN Lsuppressnotusedinkit=1 THEN 'T' ELSE 'ALL' END 
							when @lcSupUsedKit = 'Yes' then 'T'
							when @lcSupUsedKit = 'No' then 'All' end from KITDEF)

	
-- 08/16/17 VL separate FC and non FC
/*----------------------
None FC installation
*/----------------------
IF dbo.fn_IsFCInstalled() = 0 
	BEGIN	 
		select M.Part_no as AssemblyPart,M.Revision as AssemblyRev,M.Descript as AssemblyDescript,
		CAST(ISNULL(Customer.CustName,'') as varchar(50)) as Custname,
		isnull(Sub.PART_NO,space(25)) as SubAssemblyPart, isnull(Sub.REVISION, space(8)) as SubAssemblyRev,
		@lcQty*TopStdCost as ext_cost,@lcQty*StdCostper1Build as ext_cost_With_scrap,F.*
		--02/20/15 YS Vicky added new parameter to fn_phantomSubSelect, have to provide it here
		from dbo.fn_phantomSubSelect(@lcUniqkey, @lcQty,@cChkDate, @lcDate, @cMake, @cKitInUse,@cMakeBuy, @lIgnoreScrap, @lLeaveParentPart,1  ) F
		INNER JOIN Inventor M ON M.Uniq_key=@lcUniqkey
		LEFT OUTER JOIN Inventor Sub ON Sub.UNIQ_KEY=F.BomParent AND F.Bomparent<>@lcUniqkey 
		LEFT OUTER JOIN Customer ON M.BOMCUSTNO=Customer.CUSTNO
		ORDER BY F.Sort
	END
ELSE
/*-----------------
 FC installation
*/-----------------
	BEGIN
		select M.Part_no as AssemblyPart,M.Revision as AssemblyRev,M.Descript as AssemblyDescript,
		CAST(ISNULL(Customer.CustName,'') as varchar(50)) as Custname,
		isnull(Sub.PART_NO,space(25)) as SubAssemblyPart, isnull(Sub.REVISION, space(8)) as SubAssemblyRev,
		@lcQty*TopStdCost as ext_cost,@lcQty*StdCostper1Build as ext_cost_With_scrap,ISNULL(FF.Symbol,'') AS FSymbol,
		-- 08/16/17 VL added functional currency code
		@lcQty*TopStdCostPR as ext_costPR,@lcQty*StdCostper1BuildPR as ext_cost_With_scrapPR,ISNULL(PF.Symbol,'') AS PSymbol,
		F.*
		--02/20/15 YS Vicky added new parameter to fn_phantomSubSelect, have to provide it here
		from dbo.fn_phantomSubSelect(@lcUniqkey, @lcQty,@cChkDate, @lcDate, @cMake, @cKitInUse,@cMakeBuy, @lIgnoreScrap, @lLeaveParentPart,1  ) F
		INNER JOIN Inventor M ON M.Uniq_key=@lcUniqkey
		LEFT OUTER JOIN Inventor Sub ON Sub.UNIQ_KEY=F.BomParent AND F.Bomparent<>@lcUniqkey 
		LEFT OUTER JOIN Customer ON M.BOMCUSTNO=Customer.CUSTNO
		-- 08/15/17 VL added
		LEFT OUTER JOIN Fcused FF ON M.FuncFcused_uniq = FF.Fcused_uniq
		LEFT OUTER JOIN Fcused PF ON M.PrFcused_uniq = PF.Fcused_uniq	
		ORDER BY F.Sort

	END
	

end