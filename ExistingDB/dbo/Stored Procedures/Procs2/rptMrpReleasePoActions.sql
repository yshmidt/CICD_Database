/*
-- =============================================
-- Author:			Debbie 
-- Create date:		09/09/2019
-- Description:		TEMP QUICK VIEW THAT COULD BE USED TO TAKE THE MRP SUGGESTED RELEASE PO ACTIONS AND EXPORT THEM OUT DIRECTLY INTO A FORMAT THAT WOULD WORK FOR THE PO UPLOAD.
--					**intended to be removed from manex after the MRP Release PO feature has been completed.**
-- Reports:			
-- Modifications:	
-- 08/05/20 VL Nate found the "ORD_QTY" sum group by uniq_key, it should also consider AVL
-- 10/07/20 DRP/VL CAPA 3144 should conver the "ord_qty" from stock uom to purchase uom
-- 10/08/20 DRP:  I forgot to inform Vicky that we also needed to make sure that the Schedule qty also converted to the Puom value. 
-- 12/21/20 DRP:  Modified BUYER to pull from the inventor table the buyer that is associated to the inventory part. 
--                Also added the other MRP parameters that have been used on other reports.  This will give the end users the ability to filter the results down to a specific buyer and/or Product.  This has been requested for some time now by end users. 
-- =============================================
*/
CREATE PROCEDURE  [dbo].[rptMrpReleasePoActions]

--declare
				--12/21/2020 DRP:  added all of the MRP parameters to this quickview.  
				@lcUniqBomParent char(10)=''	-- this is the Bom Parent Part.  This too will be populated by the MRP Filter Screen.
				,@lcUniq_keyStart char(10)=''
				,@lcUniq_keyEnd char(10)=''
				,@lcLastAction as smalldatetime = null	
				,@lcClass as varchar (max) = 'All'		--user would select to include all Classes or select from selection list.
				,@lcBuyer varchar(max) = 'ALL'			-- user would select to include ALL buyers or Select from Selection list. 
				--,@lcBuyer varchar(max) = 'CCAB0EB7-F8F6-48B1-8BAF-80158F16F21D,768A2B43-21DE-400A-94CB-B22FDA5FAADC'			-- user would select to include ALL buyers or Select from Selection list. 
				, @userId uniqueidentifier=null 	
				,@lcPartType as varchar(max) = 'All'	--11/24/15 DRP:
	
as 
begin

--12/21/2020 DRP:  added to work with the added parameters above
/*PART RANGE*/
SET NOCOUNT ON;
--11/24/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
-- 09/26/19 YS changed part no and cust part no from char(25) to char(35)
declare @lcPartStart char(35)='',@lcRevisionStart char(8)='',
	@lcPartEnd char(35)='',@lcRevisionEnd char(8)=''
		
		--11/24/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key	
		IF  @lcUniq_keyStart IS NULL or  @lcUniq_keyStart ='' 
			SELECT @lcPartStart=' ', @lcRevisionStart=' '
		ELSE
		SELECT @lcPartStart = ISNULL(I.Part_no,' '), 
			@lcRevisionStart = ISNULL(I.Revision,' ') 
		FROM Inventor I where Uniq_key=@lcUniq_keyStart
		
		-- find ending part number
		IF  @lcUniq_keyEnd IS NULL or  @lcUniq_keyEnd ='' 
			SELECT @lcPartEnd = REPLICATE('Z',25), @lcRevisionEnd=REPLICATE('Z',8)
		ELSE
			SELECT @lcPartEnd =ISNULL(I.Part_no,' '), 
				@lcRevisionEnd = ISNULL(I.Revision,' ') 
			FROM Inventor I where Uniq_key=@lcUniq_keyEnd	
				
		-- if no @lcLastAction provided use default	
			if @lcLastAction is null
			SELECT @lcLastAction=DATEADD(Day,Mpssys.VIEWDAYS,getdate()) FROM MPSSYS 
			 
		--declaring the table so that it can be populated using Yelena Stored Procedured called MrpFullActionView
		-- 09/26/19 YS changed part no and cust part no from char(25) to char(35)
			Declare @MrpActionView as table (Uniq_key char(10),Part_class char(8),Part_Type char(8),Part_no char(35),Revision char(8)
											,CustPartNo char(35),CustRev char(8),Descript char(45),Part_sourc char(10),UniqMrpAct char(10))

			-- 09/26/19 YS changed part no and cust part no from char(25) to char(35)
			DECLARE @lcBomParentPart char(35)='',@lcBomPArentRev char(8) =''
			if @lcUniqBomParent is null OR @lcUniqBomParent=''
				SELECT @lcBomParentPart ='',@lcBomPArentRev =''
			else
				SELECT @lcBomParentPart = I.Part_no,@lcBomPArentRev =I.Revision FROM INVENTOR I where UNIQ_KEY=@lcUniqBomParent 
				--SELECT @lcBomParentPart ,@lcBomPArentRev
			
			Insert into @MrpActionView exec MrpFullActionView @lcBomParentPart=@lcBomParentPart,@lcBomPArentRev=@lcBomPArentRev		
			--SELECT * FROM @MrpActionView
			 
--SELECT * FROM @MrpActionView

			-- added code to handle buyer list
			DECLARE @BuyerList TABLE (BUYER_TYPE uniqueidentifier)
			--12/03/13 YS use 'All' in place of ''
			IF @lcBuyer is not null and @lcBuyer <>'' and @lcBuyer <>'All'
				INSERT INTO @BuyerList SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcBuyer,',')
				

			--  added code to handle class list
			DECLARE @PartClass TABLE (part_class char(8))
			-- use 'All' in place of ''
			IF @lcClass is not null and @lcClass <>'' and @lcClass <>'All'
				INSERT INTO @PartClass SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcClass,',')


/*RECORD SELECTION SECTION*/
SELECT	'' AS PONUM, '' AS SUPNAME
		,CASE WHEN I.AspnetBuyer = '00000000-0000-0000-0000-000000000000' THEN '' ELSE U.USERNAME END AS BUYER	--12/21/20 DRP:  modified buyer to display the buyer name if associated to the inventor part --, ''AS BUYER
		,DENSE_RANK()OVER(ORDER BY I.PART_CLASS,I.PART_TYPE,I.PART_NO,I.REVISION,LEFT(PREFAVL,9),RIGHT(PREFAVL,31),M.Uniq_key) AS ITEMNO
		,'Invt Part' as POITTYPE, I.PART_NO as PARTNO,I.REVISION, I.DESCRIPT
		,LEFT(PREFAVL,9) AS PARTMFGR, RIGHT(PREFAVL,31) AS MFGR_PT_NO
		-- 08/05/20 VL Nate found the "ORD_QTY" sum group by uniq_key, it should also consider AVL
		--,sum(reqqty) over(partition by m.uniq_key order by m.Uniq_key) as ORD_QTY
		-- 10/07/20 DRP/VL CAPA 3144 should conver the "ord_qty" from stock uom to purchase uom
		--,sum(reqqty) over(partition by m.uniq_key, PREFAVL order by m.Uniq_key) as ORD_QTY
		-- Debbie's original code, VL changed to use fn_ConverQtyPUOM()
		--,case when i.U_OF_MEAS <> I.PUR_UOFM then ceiling((sum(reqqty) over(partition by m.uniq_key, PREFAVL order by m.Uniq_key))/u.FORMULA) else sum(reqqty) over(partition by m.uniq_key, PREFAVL order by m.Uniq_key) end as new_ord_Qty  
		,dbo.fn_ConverQtyPUOM(I.PUR_UOFM,i.U_OF_MEAS,sum(reqqty) over(partition by m.uniq_key, PREFAVL order by m.Uniq_key)) AS ORD_QTY
		,I.PUR_UOFM,I.STDCOST AS COSTEACH
		,'' AS TAXABLE, '' AS TAXID,CAST(M2.REQDATE AS DATE) AS SCHDDATE,CAST(M2.REQDATE AS DATE) AS ORIGCOMMITDT
		--10/08/20 DRP the Schedule qty also needed to be converted for the Puom
		--, M.REQQTY AS SCHDQTY
		,dbo.fn_ConverQtyPUOM(I.PUR_UOFM,i.U_OF_MEAS,reqqty ) AS SCHDQTY
		,'' AS WAREHOUSE,'' AS [LOCATION],'' AS WOPRJNUM,'' AS REQUESTTP, ''AS REQUESTOR, '' AS GLNBR 
		, '' AS ISFIRM, '' AS PUR_LTIME,'' AS PUR_LUNIT, '' AS MINORD, '' AS ORDMULT, '' AS FIRSTARTICLE, '' AS INSPEXCEPT, '' AS INSPEXCEPTION, '' AS INSPEXNOTE
		, ''AS PONOTE, '' AS TERMS, '' AS[PRIORITY],'' AS CONFTO, '' AS SHIPCHGAMOUNT, ''AS IS_SCTAX,'' AS SCTAXPCT,'' AS SHIPCHARGE
		,'' AS FOB, '' AS SHIPVIA, ''AS LFREIGHTINCLUDED, '' AS ITEMNOTE 
		
FROM	@MrpActionView M
		INNER JOIN INVENTOR I ON M.UNIQ_KEY = I.UNIQ_KEY
		INNER JOIN MRPACT M2 ON M.UNIQMRPACT = M2.UNIQMRPACT
		left outer join aspnet_users U on I.AspnetBuyer = U.UserId  --12/21/20 DRP:  added the aspnet_user table in order to get the buyer name
where	M2.[action] = 'release PO'
		and m.Part_no>= case when @lcPartStart='' then m.Part_no else @lcPartStart END	--12/21/20 DRP
		and m.PART_NO<= CASE WHEN @lcPartEnd='' THEN m.PART_NO ELSE @lcPartEnd END	--12/21/20 DRP:
		AND 1= CASE WHEN @lcClass ='All' THEN 1    -- any class
				WHEN m.Part_class IN (SELECT Part_class FROM @PartClass) THEN 1 ELSE 0  END	--12/21/20 DRP:
		AND 1= CASE WHEN @lcBuyer ='All' THEN 1   
				WHEN I.ASPNETBUYER  IN (SELECT BUYER_TYPE FROM @BuyerList) THEN 1 ELSE 0  END  --12/21/20 DRP
		and (DATEDIFF(Day,M2.DTTAKEACT,@lcLastAction)>=0 or M2.DTTAKEACT is null)	--12/21/20 DRP:
order by I.PART_CLASS,I.PART_TYPE,I.PART_NO,I.REVISION,PARTMFGR,MFGR_PT_NO,SCHDDATE

end
