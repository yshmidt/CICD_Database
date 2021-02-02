-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/25/11
-- Description:	<Gather data for the Sales Orders>
-- 10/24/13 DS Removed TOP(100) from the CTE to fix an issue with da.Fill()
-- =============================================
CREATE PROCEDURE [dbo].[spManexWebSOStatus]
	-- Add the parameters for the stored procedure here
	@pcCustNo as char(10)=' ',@pcStatus as varchar(25)='Open' ,@pnClosedDays as int =0, @userId uniqueidentifier = null, @gridId varchar(50) = null
	--@pcCustNo - custno to find sales orders for a specific customer. If empty no information will be found
	--- possible values for @pcStatus
	--- 'Open' - find all the items on the sales order with the status other than closed or cancelled
	--- 'Closed' - all the SO with the items that are closed for @pnClosedDays. If @pnClosedDays=0 all closed items
	--- 'All' - clsed and open 
	--- @pnClosedDays will be ignored for the Open status
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
SET ARITHABORT OFF
	DECLARE @lcStatus varchar(25)
	DECLARE @tS AS Table (sono char(10),pono char(20),line_no char(7),custno char(10),orderdate smalldatetime,ord_qty decimal(8,2),shippedqty decimal(8,2),balance decimal(8,2),
				uniqueln char(10),uniq_key char(10),Part_no char(45),Revision Char(8),Descript char(45),
				Released bit,status char(10), is_rma bit,ord_type char(10), Complete_date smalldatetime NULL );
			
	--DECLARE @tD AS Table (due_dts  Date,qty  decimal(8,2),act_shp_qt decimal(8,2),uniqueln char(10));
    
    -- Insert statements for procedure here
    IF  @pcStatus='Open'
		BEGIN
		WITH S
		AS
		(
			SELECT Somain.sono,somain.pono,sodetail.line_no,somain.custno,somain.orderdate,sodetail.ord_qty,sodetail.shippedqty,sodetail.balance,
				Sodetail.uniqueln,sodetail.uniq_key,
				CASE WHEN sodetail.uniq_key=' ' THEN sodetail.[Sodet_Desc] 
					ELSE cast(inventor.part_no as char(45)) END AS Part_no,
				CASE WHEN sodetail.uniq_key=' ' THEN CAST(' ' as CHAR(4)) ELSE inventor.revision END as Revision,
				CASE WHEN sodetail.uniq_key=' ' THEN sodetail.[Sodet_Desc] ELSE cast(inventor.Descript as char(45)) END AS Descript,
				 	w.Kit as released ,sodetail.status,Somain.is_rma,Somain.ord_type  
			from Somain INNER JOIN sodetail on somain.sono=sodetail.sono left outer join inventor on sodetail.uniq_key=inventor.uniq_key 
			outer apply 
			(select TOP(1) woentry.kit  from woentry where woentry.uniqueln = sodetail.uniqueln and woentry.kit=1 order by wono) as W
			WHERE somain.custno=@pcCustNo
			and sodetail.status<>'Closed' and sodetail.status<>'Cancel' and sodetail.status<>'Archived')
			INSERT INTO @tS SELECT sono,pono,line_no,custno,orderdate,ord_qty,shippedqty,balance,
				uniqueln,uniq_key,part_no,Revision,Descript,Released,status,is_rma,ord_type,CAST(null as SMALLDATETIME) FROM S; 
		END -- IF  @pcStatus='Open'
		
		
	IF 	@pcStatus='All'
		BEGIN
			WITH
			S
			AS
			(
			SELECT Somain.sono,somain.pono,sodetail.line_no,somain.custno,somain.orderdate,sodetail.ord_qty,sodetail.shippedqty,sodetail.balance,
				Sodetail.uniqueln,sodetail.uniq_key,
				CASE WHEN sodetail.uniq_key=' ' THEN sodetail.[Sodet_Desc] 
					ELSE cast(inventor.part_no as char(45)) END AS Part_no,
				CASE WHEN sodetail.uniq_key=' ' THEN CAST(' ' as CHAR(4)) ELSE inventor.revision END as Revision,
				CASE WHEN sodetail.uniq_key=' ' THEN sodetail.[Sodet_Desc] ELSE cast(inventor.Descript as char(45)) END AS Descript,
				w.Kit as released ,sodetail.status ,Somain.is_rma,Somain.ord_type
			from Somain INNER JOIN sodetail on somain.sono=sodetail.sono
			left outer join inventor on sodetail.uniq_key =inventor.uniq_key 
			outer apply 
			(select TOP(1) woentry.kit  from woentry where woentry.uniqueln = sodetail.uniqueln and woentry.kit=1 order by wono) as W
			WHERE somain.custno=@pcCustNo
			)
			INSERT INTO @tS SELECT sono,pono,line_no,custno,orderdate,ord_qty,shippedqty,balance,
					uniqueln,uniq_key,part_no,revision,Descript,Released,status,is_rma,ord_type,CAST(null as SMALLDATETIME) FROM S 
					ORDER BY status DESC; 
					
		END -- IF 	@pcStatus='All'		
	IF 	@pcStatus='Archived'
		BEGIN
			WITH
			S
			AS
			(
			SELECT Somain.sono,somain.pono,sodetail.line_no,somain.custno,somain.orderdate,sodetail.ord_qty,sodetail.shippedqty,sodetail.balance,
				Sodetail.uniqueln,sodetail.uniq_key,
				CASE WHEN sodetail.uniq_key=' ' THEN sodetail.[Sodet_Desc] 
					ELSE cast(inventor.part_no as char(45)) END AS Part_no,
				CASE WHEN sodetail.uniq_key=' ' THEN CAST(' ' as CHAR(4)) ELSE inventor.revision END as Revision,
				CASE WHEN sodetail.uniq_key=' ' THEN sodetail.[Sodet_Desc] ELSE cast(inventor.Descript as char(45)) END AS Descript,
				w.Kit as released ,sodetail.status ,Somain.is_rma,Somain.ord_type
			from Somain INNER JOIN sodetail on somain.sono=sodetail.sono
			left outer join inventor on sodetail.uniq_key =inventor.uniq_key 
			outer apply 
			(select TOP(1) woentry.kit  from woentry where woentry.uniqueln = sodetail.uniqueln and woentry.kit=1 order by wono) as W
			WHERE somain.custno=@pcCustNo
			and sodetail.status='Archived' 
			)
			INSERT INTO @tS SELECT sono,pono,line_no,custno,orderdate,ord_qty,shippedqty,balance,
					uniqueln,uniq_key,part_no,revision,Descript,Released,status,is_rma,ord_type,CAST(null as SMALLDATETIME) FROM S 
					ORDER BY status DESC; 
					
		END -- IF 	@pcStatus='All'	
	IF 	@pcStatus='Closed' and @pnClosedDays=0
		
		BEGIN	
			WITH 
			S 
			AS
			(
			SELECT Somain.sono,somain.pono,sodetail.line_no,somain.custno,somain.orderdate,sodetail.ord_qty,sodetail.shippedqty,sodetail.balance,
				Sodetail.uniqueln,sodetail.uniq_key,
				CASE WHEN sodetail.uniq_key=' ' THEN sodetail.[Sodet_Desc] 
					ELSE cast(inventor.part_no as char(45)) END AS Part_no,
				CASE WHEN sodetail.uniq_key=' ' THEN CAST(' ' as CHAR(4)) ELSE inventor.revision END as Revision,
				CASE WHEN sodetail.uniq_key=' ' THEN sodetail.[Sodet_Desc] ELSE cast(inventor.Descript as char(45)) END AS Descript,
				w.Kit as released,sodetail.status,Somain.is_rma,Somain.ord_type  
			from Somain INNER JOIN sodetail on somain.sono=sodetail.sono
			left outer join inventor on sodetail.uniq_key =inventor.uniq_key 
			outer apply 
			(select TOP(1) woentry.kit  from woentry where woentry.uniqueln = sodetail.uniqueln and woentry.kit=1 order by wono) as W
			WHERE somain.custno=@pcCustNo
			and sodetail.status='Closed' 
			),
			P AS
			(
			SELECT MAX(shipDate) as Complete_date,pldetail.uniqueln FROM plmain inner join pldetail on plmain.packlistno = pldetail.packlistno inner join s on pldetail.uniqueln =S.uniqueln group by pldetail.uniqueln 
			)
			INSERT INTO @tS SELECT sono,pono,line_no,custno,orderdate,ord_qty,shippedqty,balance,
						uniqueln,uniq_key,part_no, revision, descript,Released,status,is_rma,ord_type,
						pSub.Complete_date
			FROM S  CROSS APPLY 
			(select p.Complete_date from p  WHERE p.uniqueln =S.uniqueln ) as PSub; 
				
		END -- IF 	@pcStatus='Closed' and @pnClosedDays=0		
	IF 	@pcStatus='Closed' and @pnClosedDays<>0
		BEGIN
		WITH S AS
		(
		SELECT Somain.sono,somain.pono,sodetail.line_no,somain.custno,somain.orderdate,sodetail.ord_qty,sodetail.shippedqty,sodetail.balance,
			Sodetail.uniqueln,sodetail.uniq_key,
				CASE WHEN sodetail.uniq_key=' ' THEN sodetail.[Sodet_Desc] 
					ELSE cast(inventor.part_no as char(45)) END AS Part_no,
				CASE WHEN sodetail.uniq_key=' ' THEN CAST(' ' as CHAR(4)) ELSE inventor.revision END as Revision,
				CASE WHEN sodetail.uniq_key=' ' THEN sodetail.[Sodet_Desc] ELSE cast(inventor.Descript as char(45)) END AS Descript,
			w.Kit as released ,sodetail.status ,Somain.is_rma,Somain.ord_type
		from Somain INNER JOIN sodetail on somain.sono=sodetail.sono
		left outer join inventor on sodetail.uniq_key =inventor.uniq_key 
		outer apply 
		(select TOP(1) woentry.kit  from woentry where woentry.uniqueln = sodetail.uniqueln and woentry.kit=1 order by wono) as W
		WHERE somain.custno=@pcCustNo
		and sodetail.status='Closed' 
		),	
		P AS
		(
			SELECT MAX(shipDate) as Complete_date,pldetail.uniqueln FROM plmain inner join pldetail on plmain.packlistno = pldetail.packlistno inner join s on pldetail.uniqueln =S.uniqueln group by pldetail.uniqueln 
		)
		INSERT INTO @tS SELECT sono,pono,line_no,custno,orderdate,ord_qty,shippedqty,balance,
						uniqueln,uniq_key,part_no,revision,Descript,Released,status,is_rma,ord_type,pSub.Complete_date
			FROM S  CROSS APPLY 
		(select p.Complete_date from p  WHERE p.uniqueln =S.uniqueln and DATEDIFF(Day,Complete_date,DATEADD(Day,-@pnClosedDays,GETDATE()))<=0) as PSub;
		
	END -- IF 	@pcStatus='Closed' and @pnClosedDays<>0	
	SELECT * FROM @ts
	
	--2/8/2012 added by David Sharp to return grid personalization with the results
	EXEC MnxUserGetGridConfig @userId, @gridId
	--IF @userId = NULL OR @gridId = NULL
	--	SELECT '' AS gridConfig 
	--ELSE
	--	SELECT colModel, colNames, groupedCol FROM MnxUserGridConfig WHERE userId = @userId AND gridId = @gridId
		
END