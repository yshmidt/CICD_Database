-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/19/2018
-- Description:	Find outdented BOM for a part and all the open sales orders
-- this SP is currently for internal use. It helps to find the possible demands for a component that is used on the BOM   
-- 10/11/19 VL changed part_no from char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[mrpCompOutdentedWithSalesOrders] 
	-- Add the parameters for the stored procedure here
	@uniq_key char(10) = null, 
	@customerStatus varchar (20) = 'All',  --- I am not sure what this is for, see [rptBomOutdentedWhereUsed]
	@userId uniqueidentifier = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	


		/*INQUIRY DETAIL*/	--05/19/2015 DRP:  Added
		-- 10/11/19 VL changed part_no from char(25) to char(35)
		DECLARE @lcPartNo as char(35),@lcRev as char(8)	
		select @lcPartNo = part_no,@lcRev = Revision from inventor where @uniq_key = inventor.UNIQ_KEY
		
		IF OBJECT_ID('tempdb..#tTemp1') IS NOT NULL
			DROP TABLE #tTemp1

		/*SELECT STATEMENT*/
		;with BomOutdented
		as
		(
		SELECT	cast(0 as Integer) as [Level],Eff_Dt,Term_Dt,Item_no,m.PART_SOURC
				,case when M.PART_SOURC = 'MAKE' and m.PHANT_MAKE = 1 then 'Phantom/Make'
					when M.PART_SOURC = 'MAKE' and M.MAKE_BUY = 1 then 'Make/Buy' else '' end as MbPhSource
				,m.Part_no,m.Revision,m.PART_CLASS,m.PART_TYPE,LEFT(m.Descript,19) AS Descript,USED_INKIT,m.U_OF_MEAS,Qty,DEPT_NAME,LEFT(m.Bom_Status,8) AS Bom_Status
				, M.Status,Bom_det.BomParent,'/'+CAST(bomparent as varchar(max)) as [path],@lcPartNo as InquiredPart ,@lcRev as InquiredRev
		FROM	Bom_det 
				INNER JOIN Inventor M ON Bom_det.Bomparent = M.Uniq_key
				inner join DEPTS on bom_det.DEPT_ID = depts.DEPT_ID 
		WHERE	Bom_det.Uniq_key = @Uniq_key
				and 1 = case when m.BOMCUSTNO in (select CUSTNO from @tcustomer) then 1 else 0 end


		UNION ALL

		SELECT  P.[Level]+1 as Level,b2.Eff_Dt,b2.Term_Dt,B2.Item_no,m2.PART_SOURC
				,case when M2.PART_SOURC = 'MAKE' and m2.PHANT_MAKE = 1 then 'Phantom/Make'
					when M2.PART_SOURC = 'MAKE' and M2.MAKE_BUY = 1 then 'Make/Buy' else '' end as MbPhSource
				,M2.part_no,M2.Revision,m2.PART_CLASS,m2.PART_TYPE,LEFT(M2.Descript,19) AS Descript,B2.USED_INKIT,m2.U_OF_MEAS,B2.Qty,d2.DEPT_NAME,LEFT(M2.Bom_Status,8) AS Bom_Status
				, M2.Status,B2.BomParent,CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as [path] ,@lcPartNo as InquiredPart,@lcRev as InquiredRev
		FROM	BomOutdented as P INNER JOIN BOM_DET B2 ON P.BomParent =B2.Uniq_key 
				INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY
				inner join DEPTS d2 on b2.DEPT_ID = d2.DEPT_ID  
		WHERE	(P.PART_SOURC='PHANTOM' or P.PART_SOURC='MAKE')
				and 1 = case when m2.BOMCUSTNO in (select CUSTNO from @tcustomer) then 1 else 0 end
		)
		 --04/02/15 YS/DP changed order at the ebd of the code	  
		 SELECT E.* 
		into #temp1	
		from BomOutdented E 
		where 
		Bom_Status='Active'
		ORDER BY path 
		-- find all open sales orders
		select s.sono,s.ORD_TYPE,s.ORDERDATE,sd.UNIQ_KEY,sd.status,sd.ORD_QTY,sd.balance,t.* from somain s inner join sodetail sd on s.SONO=sd.SONO
		inner join #temp1 t on sd.UNIQ_KEY=t.BOMPARENT
		and s.ORD_TYPE='Open'
		and sd.balance>0 
		and sd.[STATUS]<>'Cancel'
		 order by path

		 IF OBJECT_ID('tempdb..#tTemp1') IS NOT NULL
			DROP TABLE #tTemp1

END