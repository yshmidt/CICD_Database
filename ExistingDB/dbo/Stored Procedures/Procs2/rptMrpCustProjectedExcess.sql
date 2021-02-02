-- =============================================
-- Author:		Debbie Peltier
-- Created:		01/08/2016
-- Description:	Created for the MRP Customer Projected Excess Inventory List
-- Report:		MRPEXIN2
-- Modified:	
-- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 08/15/17 VL  Added functional currency code
-- 08/16/17 VL added ExcessValuePR at final sql statement
-- =============================================
CREATE PROCEDURE [dbo].[rptMrpCustProjectedExcess]
--declare		
			@lcInvtType char(8) = 'All'		--All, Internal, In Store
			,@lcCustNo varchar(max) = ''
			,@lcSort char(25) = 'Internal Part Number'	--Internal Part Number or Customer Part Number
			,@userId uniqueidentifier = null

as 
begin


/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)

--select * from @tCustomer


/**************************/
/*RECORD SELECTION SECTION*/
/**************************/

/*USED FOR LIST OF PARTS*/
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 08/15/17 VL  Added functional currency code: StdcostPR, FSymbol and PSymbol 
declare @zlist table (uniq_key char(10),PART_NO CHAR(35),REVISION CHAR(8),CUSTPARTNO CHAR(35),CUSTREV CHAR(8),PART_CLASS CHAR(8),PART_TYPE CHAR(8),DESCRIPT CHAR(45),STDCOST NUMERIC(13,5),PART_SOURC CHAR(10),
				StdCostPR numeric(13,5), FSymbol char(3), PSymbol char(3))

/*Get the make parts*/
-- 08/15/17 VL  Added functional currency code
	insert into @zlist 
			SELECT	Uniq_key,PART_NO,REVISION,CUSTPARTNO,CUSTREV
					,PART_CLASS,PART_TYPE,DESCRIPT,STDCOST,PART_SOURC, StdCostPR, SPACE(3) AS FSymbol, SPACE(3) AS PSymbol 
			FROM	inventor 
			WHERE	exists(select 1 from @Customer PC where PC.custno = BOMCUSTNO)
					AND part_sourc = 'MAKE'




/*EXPLODE OUT BOM FROM THE LIST OF MAKE PARTS GATHERED ABOVE AND INSERT THEM INTO THE @ZLIST TABLE*/
-- 08/15/17 VL  Added functional currency code
	;with
	BomExplode as (
					SELECT	B.bomParent,M.BOMCUSTNO,B.UNIQ_KEY, B.item_no,C.PART_NO,C.Revision,c.Part_sourc
							,CAST(CASE WHEN C.part_sourc='CONSG' THEN C.Custpartno ELSE C.Part_no END as varchar(max)) AS ViewPartNo
							,CASE WHEN C.part_sourc='CONSG' THEN C.Custrev ELSE C.Revision END AS ViewRevision,C.Part_class,C.Part_type,C.Descript,c.MATLTYPE
							,B.Dept_id, B.Item_note, B.Offset, B.Term_dt, B.Eff_dt, B.Used_inKit,C.Custno, C.Inv_note, C.U_of_meas, C.Scrap, C.Setupscrap,M.USESETSCRP
							,M.STDBLDQTY, C.Phant_Make, c.StdCost, C.Make_buy, C.Status,cast(1.00 as numeric(9,2)) as TopQty,B.qty as Qty, cast(0 as Integer) as Level
							,'/'+CAST(bomparent as varchar(max)) as path,CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS Sort
							,B.UNIQBOMNO, c.StdCostPR 
					FROM	BOM_DET B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY 
							INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY 
					WHERE	B.BOMPARENT in (select uniq_key from @zlist)
					
	UNION ALL
					
					SELECT  B2.BOMPARENT, M2.BOMCUSTNO ,B2.Uniq_key,B2.item_no  ,C2.PART_NO,C2.Revision,c2.Part_sourc 
							,CAST(SPACE((P.level+1)*4) + CASE WHEN C2.part_sourc='CONSG' THEN C2.Custpartno ELSE C2.Part_no  END as varchar(max)) AS ViewPartNo
							,CASE WHEN C2.part_sourc='CONSG' THEN C2.Custrev ELSE C2.Revision END AS ViewRevision,C2.Part_class, C2.Part_type, C2.Descript,c2.MATLTYPE,B2.Dept_id
							,B2.Item_note, B2.Offset, B2.Term_dt, B2.Eff_dt, B2.Used_inKit,C2.Custno,C2.Inv_note, C2.U_of_meas, C2.Scrap, C2.Setupscrap,M2.USESETSCRP,M2.STDBLDQTY
							,C2.Phant_Make, C2.StdCost, C2.Make_buy, C2.Status,P.Qty as TopQty,B2.QTY, P.Level+1,CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as path 
							,CAST(RTRIM(p.Sort)+'-'+	dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS Sort,B2.UNIQBOMNO, C2.StdCostPR    
					FROM	BomExplode as P 
							INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT 
							INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY 
							INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY 
					WHERE	P.PART_SOURC='PHANTOM'
							or (p.PART_SOURC = 'MAKE' and P.PHANT_MAKE = 1) 
					)


	INSERT INTO @zlist	SELECT DISTINCT	E.UNIQ_KEY,E.PART_NO,E.REVISION,isnull(CustI.CUSTPARTNO,space(35)) as CustPartno,isnull(CustI.CUSTREV,SPACE(8)) as CustRev
								,E.PART_CLASS,E.PART_TYPE,E.DESCRIPT,E.STDCOST,E.PART_SOURC, E.STDCOSTPR, SPACE(3) AS FSymbol, SPACE(3) AS PSymbol
						FROM	BOMEXPLODE E
								LEFT OUTER JOIN INVENTOR CustI ON E.UNIQ_KEY =CustI.INT_UNIQ 
								and E.BOMCUSTNO=CustI.CUSTNO 
						where	(Term_dt>GETDATE() OR Term_dt IS NULL)			
								AND (Eff_dt<GETDATE() OR Eff_dt IS NULL)
								AND E.Status = 'Active'
								
--SELECT * FROM @zlist

/*GATHER ALTERNATE PARTS AND INSERT THEM INTO THE @ZLIST TABLE*/
	INSERT INTO @zlist
			SELECT	DISTINCT Bom_Alt.Uniq_key,F.part_no,F.REVISION,F.CUSTPARTNO,F.CUSTREV,F.PART_CLASS,F.PART_TYPE,F.DESCRIPT,F.STDCOST,A.PART_SOURC, F.StdCostPR, SPACE(3) AS FSymbol, SPACE(3) AS PSymbol
			FROM	Bom_Alt, @zlist A, Inventor F
			WHERE	Bom_alt.BomParent = A.Uniq_Key 
					AND Bom_Alt.Uniq_key NOT in (select Uniq_key FROM @zlist) 
					and F.Uniq_key = Bom_Alt.Uniq_key 


/*NOW ANALYZE TO SEE IF ANY PARTS LISTED ARE USED ON ASSEMBLIES ASSOCIATED WITH OTHER CUSTOMERS, THEN REMOVE THEM FROM THE @ZLIST*/
	;with znotgood as (
						SELECT	DISTINCT B.uniq_key,B.PART_NO,B.REVISION,B.CUSTPARTNO,B.CUSTREV 
						FROM	@ZLIST B, Inventor, Bom_det 		
						WHERE	INVENTOR.bomcustno <> @lcCustNo 
								AND Bom_det.Uniq_key = B.uniq_key 
								AND Inventor.Uniq_key = Bom_det.BomParent 
					  )
					  --select * from znotgood

	DELETE FROM @ZLIST  WHERE UNIQ_KEY IN (SELECT UNIQ_KEY FROM znotgood) 

	-- 08/15/17 VL  Added functional currency code
	IF dbo.fn_IsFCInstalled() = 1
	BEGIN
		UPDATE Z SET FSymbol = ISNULL(FF.Symbol,''),
					 PSymbol = ISNULL(PF.Symbol,'')
			FROM @Zlist Z, Inventor 
		LEFT OUTER JOIN Fcused FF ON Inventor.FuncFcused_uniq = FF.Fcused_uniq
		LEFT OUTER JOIN Fcused PF ON Inventor.PrFcused_uniq = PF.Fcused_uniq	
		WHERE Inventor.Uniq_key = Z.uniq_key
	END

--select * from @zlist

/*FROM THE FINAL @ZLIST BELOW WILL NOW CALCULATE THE SUPPLY DEMAND DETAIL FOR REPORT*/
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 08/15/17 VL  Added functional currency code: StdCostPR, FSymbol, PSymbol and ExcessValuePR, Found STdCost had numeric(13,2) changed to numeric(13,5)
Declare @results as table (part_no char(35),Revision char(8),CUSTPARTNO char(35),CUSTREV char(8),part_class char(8),Part_type char(8),Descript char(45),warehouse char(6),STDCOST numeric(13,5), Invt_oh numeric(13,2) 
		,Supply numeric(12,2),SoDemand numeric(12,2),Demand numeric(12,2),TotalQtyOh numeric(12,2),ExcessQty numeric(12,2),ExcessValue numeric(12,2),UNIQ_KEY char(10),CUSTNAME char(35),MRPDATE smalldatetime
		,StdCostPR numeric(13,5), FSymbol char(3), PSymbol char(3), ExcessValuePR numeric(12,2))

insert into @results
select	part_no,Revision,CUSTPARTNO,CUSTREV,I.part_class,Part_type,Descript,H.warehouse,STDCOST, cast(isnull(H.Invt_OH,0.00)  as numeric(12,2)) as Invt_oh 
		,CASE WHEN ROW_NUMBER() OVER(Partition by PART_NO,REVISION Order by PART_NO,REVISION)=1 Then cast(isnull(S.Supply,0.00) as numeric(12,2)) ELSE CAST(0.00 as Numeric(20,2)) END AS Supply
		,CASE WHEN ROW_NUMBER() OVER(Partition by PART_NO,REVISION Order by PART_NO,REVISION)=1 Then cast(ISNULL(D.SoDemand,0.00) as numeric(12,2)) ELSE CAST(0.00 as Numeric(20,2)) END AS SoDemand
		,CASE WHEN ROW_NUMBER() OVER(Partition by PART_NO,REVISION Order by PART_NO,REVISION)=1 Then cast(isnull(E.Demand,0.00) as numeric(12,2))  ELSE CAST(0.00 as Numeric(20,2)) END AS Demand
		,CASE WHEN ROW_NUMBER() OVER(Partition by PART_NO,REVISION Order by PART_NO,REVISION)=1 Then cast(isnull(H.TotalQtyOh,0.00) as numeric(12,2))  ELSE CAST(0.00 as Numeric(20,2)) END AS TotalQtyOh
		,CASE WHEN ROW_NUMBER() OVER(Partition by PART_NO,REVISION Order by PART_NO,REVISION)=1 Then cast(H.TotalQtyOh+isnull(S.Supply,0.00)-(isnull(D.SoDemand,0.00)+isnull(E.Demand,0.00)) as numeric(12,2))  ELSE CAST(0.00 as Numeric(20,2)) END AS ExcessQty
		,CASE WHEN ROW_NUMBER() OVER(Partition by PART_NO,REVISION Order by PART_NO,REVISION)=1 Then cast((H.TotalQtyOh+isnull(S.Supply,0.00)-(isnull(D.SoDemand,0.00)+isnull(E.Demand,0.00)))*STDCOST as numeric(12,2))  ELSE CAST(0.00 as Numeric(20,2)) END AS ExcessValue
		,I.UNIQ_KEY,CUSTOMER.CUSTNAME,MPSSYS.MRPDATE, STDCOSTPR, FSymbol, PSymbol
		,CASE WHEN ROW_NUMBER() OVER(Partition by PART_NO,REVISION Order by PART_NO,REVISION)=1 Then cast((H.TotalQtyOh+isnull(S.Supply,0.00)-(isnull(D.SoDemand,0.00)+isnull(E.Demand,0.00)))*STDCOSTPR as numeric(12,2))  ELSE CAST(0.00 as Numeric(20,2)) END AS ExcessValuePR
from	@ZLIST I
		outer apply  
			(select invtmfgr.uniq_key,WAREHOUSE,sum(invtmfgr.qty_oh) as Invt_OH,M2.TotalQtyOh 
					from invtmfgr 
						 inner join warehous W on invtmfgr.UNIQWH = W.uniqwh 
						 inner join (select uniq_key,sum(m.qty_oh) as TotalQtyOh from invtmfgr M group by uniq_key) M2 on invtmfgr.UNIQ_KEY = M2.UNIQ_KEY
					where invtmfgr.IS_DELETED <> 1  
						  and invtmfgr.UNIQ_KEY =  I.Uniq_key 
						  and 1 = case when @lcInvtType = 'Internal' and INVTMFGR.INSTORE = 0 then 1 when @lcInvtType = 'In Store' and invtmfgr.INSTORE = 1 then 1 when @lcInvtType = 'All' then 1 else 0 end
					group by invtmfgr.uniq_key,w.WAREHOUSE,TotalQtyOh ) H 
		outer apply 
			(select uniq_key,sum(reqqty) as Supply from MRPSCH2 where I.UNIQ_KEY = MRPSCH2.UNIQ_KEY and reqQty > 0 and ref <> 'Available Inventory' group by MRPSCH2.UNIQ_KEY) S 
		outer apply 
			(select SODETAIL.uniq_key,sum(balance) as SoDemand 
					from  sodetail inner join somain on sodetail.sono = somain.sono 
					where sodetail.UNIQ_KEY = I.UNIQ_KEY and balance > 0  and somain.ORD_TYPE = 'OPEN' GROUP BY SODETAIL.UNIQ_KEY) D 
		outer apply 
			(select uniq_key,sum(-reqqty) as Demand 
				from MRPSCH2 where MRPSCH2.Uniq_key=I.UNIQ_KEY and REQQTY < 0 and left(ref,2) <> 'SO' and left(ref,3) <> 'RMA' group by uniq_key ) E 
		cross apply MPSSYS
		INNER JOIN CUSTOMER ON @lcCustNo = CUSTOMER.CUSTNO
		--where invt_oh <> 0

WHERE	cast(isnull(H.TotalQtyOh,0.00)+ISNULL(SUPPLY,0.00)-(ISNULL(SODEMAND,0.00)+ISNULL(DEMAND,0.00))  as numeric(12,2)) > 0


-- 08/15/17 VL separate FC and non FC
/*----------------------
None FC installation
*/----------------------
IF dbo.fn_IsFCInstalled() = 0 
	BEGIN
	if @lcSort = 'Internal Part Number'
		Begin
			select part_no,Revision,CUSTPARTNO,CUSTREV,part_class,Part_type,Descript,warehouse,STDCOST, Invt_oh,Supply,SoDemand,Demand,TotalQtyOh,ExcessQty,ExcessValue,UNIQ_KEY,CUSTNAME,MRPDATE
				from @results order by part_no, Revision
		End

	else if @lcSort = 'Customer Part Number'
		Begin
			select part_no,Revision,CUSTPARTNO,CUSTREV,part_class,Part_type,Descript,warehouse,STDCOST, Invt_oh,Supply,SoDemand,Demand,TotalQtyOh,ExcessQty,ExcessValue,UNIQ_KEY,CUSTNAME,MRPDATE
				from @results order by CUSTPARTNO,CUSTREV
		End
	END
ELSE
/*-----------------
 FC installation
*/-----------------
	BEGIN
	if @lcSort = 'Internal Part Number'
		Begin
			select part_no,Revision,CUSTPARTNO,CUSTREV,part_class,Part_type,Descript,warehouse,STDCOST, FSymbol, StdCostPR, PSymbol, Invt_oh,Supply,SoDemand,Demand,TotalQtyOh,ExcessQty,ExcessValue,ExcessValuePR,UNIQ_KEY,CUSTNAME,MRPDATE
				from @results order by part_no, Revision
		End

	else if @lcSort = 'Customer Part Number'
		Begin
			select part_no,Revision,CUSTPARTNO,CUSTREV,part_class,Part_type,Descript,warehouse,STDCOST, FSymbol, StdCostPR, PSymbol, Invt_oh,Supply,SoDemand,Demand,TotalQtyOh,ExcessQty,ExcessValue,ExcessValuePR,UNIQ_KEY,CUSTNAME,MRPDATE
				from @results order by CUSTPARTNO,CUSTREV
		End
	END

end