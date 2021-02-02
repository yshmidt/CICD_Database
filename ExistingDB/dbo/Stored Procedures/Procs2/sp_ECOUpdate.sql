-- =============================================
-- Author:		Vicky Lu
-- Create date: 2011/08/19
-- Description:	Update ECO or BCN for Ecmain.Uniq_key
-- "ECO" - can change product number or not, if change product number - will create another new produect number, if not change, only update cost information
-- "BCN" - Can not change product number, will change BOM of current product number like BOM does
-- 05/31/12	VL	Added U_of_meas into @ZEcdetl and added WHERE clause for updating inventor table
-- 01/23/13 VL comment out next Insert because Ecantiavl should have all necessary records, no need to get from Antiavl from original part again
-- 01/23/13 VL found CAST('' as uniqueidentifier) will cause conversion error, change to CAST(NULL as uniqueidentifier)
-- 01/28/13 VL added to update Dept_id for BCN
-- 06/28/13 VL un-comment out 01/23/13 code again, found Ecantiavl only has the antiavl for entered items, for those items that are not entered in ECO, still need to get from BOM
-- 07/01/13 VL Remove the DetStatu = 'Delete' when getting Antiavl records
-- 07/24/13 VL found a problem that might cause duplicate antiavl records, if user enter same part number multiple times in ECO (with different dept_id), when save it will have same uniq_key, partmfgr, mfgr_pt_no for different UniqEcdet, change code to only save once
-- 08/19/13 VL fixed the @lcEcoEcono to be 20 characters long
-- 07/14/14 YS added new field to inventor table and this code breakes. Have to list columns to avoid braking the code.
-- 08/28/15 VL increase the severity of RAISERROR from 1 to 11, also added detail of error message at the end 
-- 10/07/15 YS need name the columns for the insert into Inventor table
-- 10/07/15 YS need to name columns in the insert part as well as select part of antiavl
-- 05/06/16 VL fixed CustPartno char(15) to char(25)
-- 11/21/16 VL I think for the new part, the lastchangeinit should be @lcUserID, not the one copied from old part
-- 01/26/17 VL Arctronics reported an issue that once an item got deleted, the bom item got eff_dt and Term_dt updated, later, for the same part, the user wants to add back and use "Change Qty" in ECO, but the eff_dt and term_dt never been removed
-- 01/27/17 VL changed to use ECO effective date as Eff_dt
--09/29/17 YS quotdept structure is changed, will check later, disable for now
-- 11/01/17 VL Added to copy bom_det.offset request by Fusion
-- 09/26/19 YS modified part number/customer part number char(25) to char(35) (maybe this sp is not going to be used, but I change it anyway)
-- =============================================

CREATE PROCEDURE [dbo].[sp_ECOUpdate] @gUniqEcNo AS char(10) = ' ', @lcUserID AS char(8)
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;

DECLARE @ZInvtMfhd TABLE (Uniq_key char(10), PartMfgr char(8), Mfgr_pt_no char(30), OldUniqMfgrhd char(10), 
						UniqMfgrHd char(10), Part_Spec char(100), MatlType char(10), AutoLocation bit, OrderPref numeric(2,0),
						MatlTypeValue char(20), lDisAllowBuy bit, lDisAllowKit bit, Sftystk numeric(7,0))

-- 11/01/17 VL Added to copy bom_det.offset request by Fusion
DECLARE @ZBom_det TABLE (Bomparent char(10), Item_no numeric(4,0), Uniq_key char(10), Dept_id char(4), Qty numeric(9,2), 
						Item_note text, Term_dt smalldatetime, Eff_dt smalldatetime, Used_inkit char(1),
						Uniqbomno char(10), OldUniqbomno char(10), Offset numeric(4,0))

DECLARE @ZEcDetlAdd TABLE (UniqEcDet char(10), UniqBomno char(10))							
DECLARE @ZQuotDept TABLE (UniqNumber char(10), OldUniqNumber char(10))	
DECLARE @ZQuotDpdt TABLE (UniqNbra char(10), OldUniqNbra char(10), UniqNumber char(10), OldUniqNumber char(10))	
DECLARE @ZConsgInvt TABLE (Uniq_key char(10), OldUniq_key char(10))
DECLARE @ZNoInvtMfhdinConsgHd TABLE (Uniq_key char(10), UniqMfgrhd char(10))

-- 08/19/13 VL fixed the @lcEcoEcono to be 20 characters long
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @lcEcoUniqEcno char(10), @lcEcoEcono char(20), @lcEcoUniq_key char(10), @lcEcoChangeType char(10),
		@llEcoChgProdNo bit, @llEcoChgRev bit, @llEcoChgLbCost bit, @llEcoChgStdCost bit, 
		@lnEcoNewLbCost numeric(13,5), @lnEcoNewMatlCst numeric(13,5), @lcEcoNewProdNo char(35),
		@lcEcoNewRev char(8), @llEcoChgCust bit, @lcEcoNewCustNo char(10), @lcEcoPart_no char(35),
		@lcEcoRevision char(8), @lcEcoTestPart_no char(35), @lcNewUniq_key char(10), @llEcoChgDescr bit, 
		@lcEcoNewDescr char(45), @llEcoChgSerNo bit, @llEcoNewSerNo bit, @llEcoCopyPhant bit, @llEcoCopyABC bit,
		@llEcoCopyOrdPol bit, @llEcoCopyLeadTm bit, @llEcoCopyNote bit, @lcNewProdNo char(35), @lcWHUniqWh char(10),
		@lcNewUniqMfgrhd char(10), @llEcoCopySpec bit, @llEcoCopyBmNote bit, @ldEcoEffectiveDt smalldatetime,
		@llEcoCopyEffDts bit, @llEcoCopyRefDes bit, @llEcoCopyAltPts bit, @llEcoCopyWkCtrs bit, @llEcoCopydocs bit,
		@llEcoCopyinst bit, @llEcoCopycklist bit, @llEcoCopyssno bit, @llEcoCopyWoList bit, @llEcoCopytool bit, 
		@lcChkUniq_key char(10), @lnTotalNo int, @lnCount int, @lnEcdnRecno int, @lcEcdUniqecdet char(10), 
		@lcEcdUniqecno char(10), @lcEcdUniq_key char(10), @lcEcdDetStatus char(10), @lnEcdOldQty numeric(9,2), 
		@lnEcdNewQty numeric(9,2), @lnEcdItem_no numeric(4,0), @lcEcdDept_id char(4), @lcEcdUniqBomno char(10),
		@lcNewUniqBomno char(10), @lcAntiavlcUniq_key char(10), @lcEcoBomCustno char(10), @lcAnotherSameItem char(10),
		@lcEcdUsed_inKit char(1), @llEcolCopySupplier bit, @llEcolUpdateMPN bit, @ErrorNumber INT, @ErrorMessage   NVARCHAR(4000),@ErrorProcedure NVARCHAR(4000),@ErrorLine INT

/*--09/29/17 YS quotdept structure is changed, will check later, disable for now
BEGIN TRANSACTION
BEGIN TRY;		
	
SELECT @lcEcoUniqEcno = UniqEcno, @lcEcoEcono = Econo, @lcEcoUniq_key = Uniq_key, 
		@lcEcoChangeType = ChangeType, @llEcoChgProdNo = ChgProdNo, @llEcoChgRev = ChgRev, 
		@llEcoChgLbCost = ChgLbCost, @llEcoChgStdCost = ChgStdCost, @lnEcoNewLbCost = NewLbCost,
		@lnEcoNewMatlCst = NewMatlCst, @lcEcoNewProdNo = NewProdNo, @lcEcoNewRev = NewRev, 
		@llEcoChgCust = ChgCust, @lcEcoNewCustNo = NewCustNo, @llEcoChgDescr = CHGDESCR, 
		@lcEcoNewDescr = NEWDESCR, @llEcoChgSerNo = ChgSerNo, @llEcoNewSerNo = NEWSERNO, 
		@llEcoCopyPhant = CopyPhant, @llEcoCopyABC = CopyABC, @llEcoCopyOrdPol = CopyOrdPol,
		@llEcoCopyLeadTm = CopyLeadTm, @llEcoCopyNote = CopyNote, @llEcoCopySpec = CopySpec,
		@llEcoCopyBmNote = CopyBmNote, @ldEcoEffectiveDt = EffectiveDt, @llEcoCopyEffDts = CopyEffDts,
		@llEcoCopyRefDes = CopyRefDes, @llEcoCopyAltPts = CopyAltPts, @llEcoCopyWkCtrs = CopyWkCtrs,
		@llEcoCopydocs = Copydocs, @llEcoCopyinst = Copyinst, @llEcoCopycklist = Copycklist, 
		@llEcoCopyssno = Copyssno, @llEcoCopyWoList = CopyWoList, @llEcoCopytool = Copytool,
		@llEcolCopySupplier = lCopySupplier, @llEcolUpdateMPN = lUpdateMPN
	FROM ECMAIN WHERE UNIQECNO = @gUniqEcNo
	

IF @@ROWCOUNT = 0
	BEGIN
	RAISERROR('Programming error.  Can not find ECO/BCN record. This operation will be cancelled.  Please try again',11,1)
	ROLLBACK TRANSACTION
	RETURN
END

SELECT @lcEcoPart_no = Part_no, @lcEcoRevision = Revision, @lcEcoBomCustno = BomCustno FROM INVENTOR WHERE UNIQ_KEY = @lcEcoUniq_key
IF @@ROWCOUNT = 0
	BEGIN
	RAISERROR('Programming error.  Can not find Inventory record for this ECO/BCN record. This operation will be cancelled.  Please try again',11,1)
	ROLLBACK TRANSACTION
	RETURN
END

SELECT @lcWHUniqWh = UniqWh FROM WAREHOUS WHERE [DEFAULT] = 1
IF @@ROWCOUNT = 0
	BEGIN
	RAISERROR('Programming error.  Can not find default warehouse.  Please set it up in system setup.  This operation will be cancelled.',11,1)
	ROLLBACK TRANSACTION
	RETURN
END
---------------------------------------------------------------------------------------------------
-- Start to update
BEGIN
IF @lcEcoChangeType = 'ECO'
	IF @llEcoChgProdNo = 0 AND @llEcoChgRev = 0
		BEGIN
			-- Not setting up a new inventory record, the only changes can be StdCost and/or Labor cost
			IF @llEcoChgLbCost = 1
				BEGIN
				UPDATE Inventor SET LaborCost = @lnEcoNewLbCost, LabDt = GETDATE() 
						WHERE UNIQ_KEY = @lcEcoUniq_key
			END
			IF @llEcoChgStdCost = 1
				BEGIN
				UPDATE Inventor SET Matl_Cost = @lnEcoNewMatlCst, MatDt = GETDATE(),
									StdCost = @lnEcoNewMatlCst + LaborCost + Overhead + Other_Cost + OtherCost2, 
									StdDt = GETDATE()
						WHERE UNIQ_KEY = @lcEcoUniq_key
			END
		END
	ELSE
		-- ECO, chagne product number, revision, will create new sets of data for new product
		BEGIN
		-- Check if enter product number if checked
		IF @llEcoChgProdNo = 1 AND @lcEcoNewProdNo = ''
			BEGIN
			RAISERROR('Programming error.  You must enter a new product number if you checked the new product check box.  This operation will be cancelled. Please try again',11,1)
			ROLLBACK TRANSACTION
			RETURN
		END	

		-- Check if enter revision if checked	
		IF @llEcoChgRev = 1 AND @lcEcoNewRev = ''
			BEGIN
			RAISERROR('Programming error.  You must enter a new revision number if you checked the new revision check box.  This operation will be cancelled. Please try again',11,1)
			ROLLBACK TRANSACTION
			RETURN
		END
	
		-- Check if enter customer number if checked
		IF @llEcoChgCust = 1 AND @lcEcoNewCustNo = ''
			BEGIN
			RAISERROR('Programming error.  You must select a new customer if you checked the new customer check box.  This operation will be cancelled. Please try again',11,1)
			ROLLBACK TRANSACTION
			RETURN
			-- 08/22/11 VL didn't copy THISFORM.CheckCust() and convert here because if user can check
			-- change customer and enter value, it has been checked
		END	

		-- Check if product number is duplicate
		-- 08/28/15 VL moved next BEGIN after IF..
		--BEGIN
		IF @llEcoChgProdNo = 1 OR @llEcoChgRev = 1
			BEGIN
			SELECT @lcEcoTestPart_no = Part_no
				FROM INVENTOR 
				WHERE PART_NO = CASE WHEN @lcEcoNewProdNo = '' THEN @lcEcoPart_no ELSE @lcEcoNewProdNo END
				AND REVISION =  CASE WHEN @lcEcoNewRev = '' THEN @lcEcoRevision ELSE @lcEcoNewRev END
	
			IF @@ROWCOUNT > 0
				BEGIN
				RAISERROR('Programming error.  The new product number/revision already exists in the inventory tables.  This is a duplicate.  Please Edit the product number or the revision and try again',11,1)
				ROLLBACK TRANSACTION
				RETURN
			END	
		END
		
		-- Start to create new records for new product
		-- Inventor
		--09/07/12 YS Inventor table has new filed ImportId ; added an empty value at the end of the insert
		-- 01/23/13 VL found CAST('' as uniqueidentifier) will cause conversion error, change to CAST(NULL as uniqueidentifier)
		SET @lcNewUniq_key = dbo.fn_GenerateUniqueNumber()
		-- 07/14/14 YS added new field to inventor table and this code breakes. Have to list columns to avoid braking the code.
		-- 10/07/15 YS need name the columns for the insert into Inventor table, not just values part
		-- 11/21/16 VL I think for the new part, the lastchangeinit should be @lcUserID, not the one copied from old part
		INSERT INTO INVENTOR 
		([UNIQ_KEY]
           ,[PART_CLASS]
           ,[PART_TYPE]
           ,[CUSTNO]
           ,[PART_NO]
           ,[REVISION]
           ,[PROD_ID]
           ,[CUSTPARTNO]
           ,[CUSTREV]
           ,[DESCRIPT]
           ,[U_OF_MEAS]
           ,[PUR_UOFM]
           ,[ORD_POLICY]
           ,[PACKAGE]
           ,[NO_PKG]
           ,[INV_NOTE]
           ,[BUYER_TYPE]
           ,[STDCOST]
           ,[MINORD]
           ,[ORDMULT]
           ,[USERCOST]
           ,[PULL_IN]
           ,[PUSH_OUT]
           ,[PTLENGTH]
           ,[PTWIDTH]
           ,[PTDEPTH]
           ,[FGINOTE]
           ,[STATUS]
           ,[PERPANEL]
           ,[ABC]
           ,[LAYER]
           ,[PTWT]
           ,[GROSSWT]
           ,[REORDERQTY]
           ,[REORDPOINT]
           ,[PART_SPEC]
           ,[PUR_LTIME]
           ,[PUR_LUNIT]
           ,[KIT_LTIME]
           ,[KIT_LUNIT]
           ,[PROD_LTIME]
           ,[PROD_LUNIT]
           ,[UDFFIELD1]
           ,[WT_AVG]
           ,[PART_SOURC]
           ,[INSP_REQ]
           ,[CERT_REQ]
           ,[CERT_TYPE]
           ,[SCRAP]
           ,[SETUPSCRAP]
           ,[OUTSNOTE]
           ,[BOM_STATUS]
           ,[BOM_NOTE]
           ,[BOM_LASTDT]
           ,[SERIALYES]
           ,[LOC_TYPE]
           ,[DAY]
           ,[DAYOFMO]
           ,[DAYOFMO2]
           ,[SALETYPEID]
           ,[FEEDBACK]
           ,[ENG_NOTE]
           ,[BOMCUSTNO]
           ,[LABORCOST]
           ,[INT_UNIQ]
           ,[EAU]
           ,[REQUIRE_SN]
           ,[OHCOST]
           ,[PHANT_MAKE]
           ,[CNFGCUSTNO]
           ,[CONFGDATE]
           ,[CONFGNOTE]
           ,[XFERDATE]
           ,[XFERBY]
           ,[PRODTPUNIQ]
           ,[MRP_CODE]
           ,[MAKE_BUY]
           ,[LABOR_OH]
           ,[MATL_OH]
           ,[MATL_COST]
           ,[OVERHEAD]
           ,[OTHER_COST]
           ,[STDBLDQTY]
           ,[USESETSCRP]
           ,[CONFIGCOST]
           ,[OTHERCOST2]
           ,[MATDT]
           ,[LABDT]
           ,[OHDT]
           ,[OTHDT]
           ,[OTH2DT]
           ,[STDDT]
           ,[ARCSTAT]
           ,[IS_NCNR]
           ,[TOOLREL]
           ,[TOOLRELDT]
           ,[TOOLRELINT]
           ,[PDMREL]
           ,[PDMRELDT]
           ,[PDMRELINT]
           ,[ITEMLOCK]
           ,[LOCKDT]
           ,[LOCKINIT]
           ,[LASTCHANGEDT]
           ,[LASTCHANGEINIT]
           ,[BOMLOCK]
           ,[BOMLOCKINIT]
           ,[BOMLOCKDT]
           ,[BOMLASTINIT]
           ,[ROUTREL]
           ,[ROUTRELDT]
           ,[ROUTRELINT]
           ,[TARGETPRICE]
           ,[FIRSTARTICLE]
           ,[MRC]
           ,[TARGETPRICEDT]
           ,[PPM]
           ,[MATLTYPE]
           ,[NEWITEMDT]
           ,[BOMINACTDT]
           ,[BOMINACTINIT]
           ,[MTCHGDT]
           ,[MTCHGINIT]
           ,[BOMITEMARC]
           ,[CNFGITEMARC]
		   ,[UseIpKey])
		SELECT @lcNewUniq_key AS Uniq_key, Part_class, Part_type, Custno, 
			CASE WHEN @llEcoChgProdNo = 1 THEN @lcEcoNewProdNo ELSE Part_no END AS Part_no, 
			CASE WHEN @llEcoChgRev = 1 THEN @lcECoNewRev ELSE Revision END AS Revision, Prod_id, CustPartno, CustRev, 
			CASE WHEN @llEcoChgDescr = 1 THEN @lcEcoNewDescr ELSE DESCRIPT END AS Descript, U_of_meas, Pur_uofm, 
			CASE WHEN @llEcoCopyOrdPol = 0 THEN ' ' ELSE Ord_Policy END AS Ord_Policy, 
			CASE WHEN @llEcoCopyABC = 0 THEN ' ' ELSE Package END AS Package, No_Pkg, 
			CASE WHEN @llEcoCopyNote = 0 THEN ' ' ELSE INV_NOTE END AS Inv_note, 
			CASE WHEN @llEcoCopyABC = 0 THEN ' ' ELSE Buyer_type END AS Buyer_type, 
			(CASE WHEN @llEcoChgStdCost = 1 THEN @lnEcoNewMatlCst ELSE Matl_Cost END +
			CASE WHEN @llEcoChgLbCost = 1 THEN @lnEcoNewLbCost ELSE LaborCost END + 
			Overhead + Other_Cost + OtherCost2) AS Stdcost, 
			CASE WHEN @llEcoCopyOrdPol = 0 THEN 0 ELSE Minord END AS Minord, 
			CASE WHEN @llEcoCopyOrdPol = 0 THEN 0 ELSE Ordmult END AS Ordmult, Usercost, Pull_in, Push_out, 
			Ptlength, Ptwidth, Ptdepth, Fginote, Status, Perpanel, 
			CASE WHEN @llEcoCopyABC = 0 THEN ' ' ELSE Abc END AS Abc, Layer, Ptwt, Grosswt, 
			CASE WHEN @llEcoCopyOrdPol = 0 THEN 0 ELSE ReorderQty END AS Reorderqty, 
			CASE WHEN @llEcoCopyOrdPol = 0 THEN 0 ELSE ReordPoint END AS Reordpoint, Part_spec, Pur_ltime, Pur_lunit, 
			CASE WHEN @llEcoCopyLeadTm = 0 THEN 0 ELSE Kit_Ltime END AS Kit_ltime, 
			CASE WHEN @llEcoCopyLeadTm = 0 THEN ' ' ELSE Kit_Lunit END AS Kit_lunit, 
			CASE WHEN @llEcoCopyLeadTm = 0 THEN 0 ELSE Prod_ltime END AS Prod_ltime, 
			CASE WHEN @llEcoCopyLeadTm = 0 THEN ' ' ELSE Prod_lunit END AS Prod_lunit, Udffield1, Wt_avg, 
			Part_sourc, Insp_req, Cert_req, Cert_type, Scrap, SetupScrap, Outsnote, Bom_status, 
			CASE WHEN @llEcoCopyBmNote = 0 THEN '' ELSE Bom_note END AS Bom_note, GETDATE() AS Bom_lastdt, 
			CASE WHEN @llEcoChgSerNo = 1 THEN @llEcoNewSerNo ELSE SERIALYES END AS Serialyes, Loc_type, 
			CASE WHEN @llEcoCopyOrdPol = 0 THEN 0 ELSE [Day] END AS [DAY], 
			CASE WHEN @llEcoCopyOrdPol = 0 THEN 0 ELSE Dayofmo END AS Dayofmo, 
			CASE WHEN @llEcoCopyOrdPol = 0 THEN 0 ELSE Dayofmo2 END AS Dayofmo2, Saletypeid, Feedback, Eng_note, 
			CASE WHEN @llEcoChgCust = 1 THEN @lcEcoNewCustNo ELSE BOMCUSTNO END AS Bomcustno, 
			CASE WHEN @llEcoChgLbCost = 1 THEN @lnEcoNewLbCost ELSE Laborcost END AS LaborCost, Int_uniq, 0 AS Eau, 
			CASE WHEN @llEcoChgSerNo = 1 THEN @llEcoNewSerNo ELSE Require_sn END AS Require_sn, Ohcost, 
			CASE WHEN @llEcoCopyPhant = 0 THEN 0 ELSE Phant_Make END AS Phant_make,	Cnfgcustno,	Confgdate, Confgnote, 
			Xferdate, Xferby, Prodtpuniq, Mrp_code, Make_Buy, Labor_oh, Matl_oh, 
			CASE WHEN @llEcoChgStdCost = 1 THEN @lnEcoNewMatlCst ELSE Matl_Cost END AS Matl_Cost, Overhead, 
			Other_cost, StdbldQty, Usesetscrp, Configcost, Othercost2, 
			CASE WHEN @llEcoChgStdCost = 1 THEN GETDATE() ELSE Matdt END AS MatDt, 
			CASE WHEN @llEcoChgLbCost = 1 THEN GETDATE() ELSE Labdt END AS Labdt, Ohdt, Othdt, Oth2dt, 
			CASE WHEN @llEcoChgStdCost = 1 THEN  GETDATE() ELSE StdDt END AS StdDt, Arcstat, Is_ncnr, Toolrel, 
			Toolreldt, ToolRelInt, Pdmrel, Pdmreldt, Pdmrelint,	Itemlock, Lockdt, Lockinit, Lastchangedt, 
			-- 11/21/16 VL I think for the new part, the lastchangeinit should be @lcUserID, not the one copied from old part
			@lcUserID AS Lastchangeinit, Bomlock, Bomlockinit, Bomlockdt, Bomlastinit, Routrel, Routreldt, Routrelint, 
			Targetprice, Firstarticle, Mrc, Targetpricedt, Ppm,	Matltype, Newitemdt, Bominactdt, Bominactinit, 
			Mtchgdt, Mtchginit, Bomitemarc, Cnfgitemarc, useIpKey
				FROM INVENTOR 
				WHERE UNIQ_KEY = @lcEcoUniq_key
		
		SET @lcNewProdNo = CASE WHEN @lcEcoNewProdNo = '' THEN @lcEcoPart_no ELSE @lcEcoNewProdNo END 
			
		-- Will use this temp table to update invtmfhd and invtmfgr
		INSERT @ZInvtMfhd 
			SELECT @lcNewUniq_key AS Uniq_key, PartMfgr, 
			CASE WHEN @llEcolUpdateMPN = 1 THEN dbo.PADR(LTRIM(RTRIM(@lcNewProdNo)),30,' ') ELSE MFGR_PT_NO END AS Mfgr_pt_no, 
				UniqMfgrHd AS OldUniqMfgrHd, dbo.fn_GenerateUniqueNumber() AS UniqMfgrHd, Part_Spec,
				MatlType, AutoLocation, OrderPref, MatlTypeValue, lDisAllowBuy, lDisAllowKit, Sftystk
			FROM InvtMfhd
			WHERE Uniq_key = @lcEcoUniq_key
			AND Is_Deleted = 0
		
		IF @@ROWCOUNT > 0
			BEGIN
			-- need to delete duplicate uniq_key+partmfgr+mfgr_pt_no because mfgr_pt_no was created from @lcnewProdNo
			---- use CTE with DELETE statement. This will delete duplicate from underline table 
			WITH DuplMfgr (Partmfgr, Mfgr_pt_no, OldUniqMfgrHd, DuplicateCount)
			AS
			(
				SELECT Partmfgr, Mfgr_pt_no, OldUniqMfgrHd,
				ROW_NUMBER() OVER(PARTITION BY Partmfgr, Mfgr_pt_no ORDER BY OldUniqMfgrHd) AS DuplicateCount
				FROM @ZInvtMfhd
			)
			DELETE
			FROM DuplMfgr
			WHERE DuplicateCount > 1

			-- Insert Invtmfhd
			INSERT INVTMFHD (Uniqmfgrhd, Uniq_key, Partmfgr, Mfgr_pt_no, PART_SPEC,
				MatlType, AutoLocation, OrderPref, MatlTypeValue, lDisAllowBuy, lDisAllowKit, Sftystk)
				SELECT Uniqmfgrhd, Uniq_key, Partmfgr, Mfgr_pt_no, 
				CASE WHEN @llECoCopySpec = 1 THEN Part_Spec ELSE '' END AS Part_Spec,
				MatlType, AutoLocation, OrderPref, MatlTypeValue, lDisAllowBuy, lDisAllowKit, Sftystk
					FROM @ZInvtMfhd

			-- Insert Invtmfgr
			-- 09/12/11 VL also added code to filter out WO-WIP, WIP
			INSERT Invtmfgr (Uniq_key, Netable, W_key, UniqWh, UniqMfgrHd, Location)
				SELECT @lcNewUniq_key AS Uniq_key, 1 AS Netable, dbo.fn_GenerateUniqueNumber() AS W_key,
					UniqWh, ZInvtmfhd.UniqMfgrhd As UniqMfgrHd, Location 
					FROM Invtmfgr, @ZInvtMfhd ZinvtMfhd
					WHERE INVTMFGR.UNIQMFGRHD = ZInvtMfhd.OldUniqMfgrhd
					AND NetAble = 1
					AND Is_Deleted = 0
					AND UniqWh NOT IN 
						(SELECT UniqWh 
							FROM Warehous 
							WHERE WareHouse = 'MRB   ' 
							OR WareHouse = 'WIP   '
							OR WareHouse = 'WO-WIP') 
						
			END							
		ELSE	
			-- If didn't find any invtmfhd records for Ecmain.Uniq_key, need to insert new invtmfhd and invtmfgr for new product number
			BEGIN
			SET @lcNewUniqMfgrhd = dbo.fn_GenerateUniqueNumber()
			INSERT INTO InvtMfhd (UniqMfgrHd, Uniq_key, Partmfgr, Mfgr_pt_no, Matltype, Orderpref)
				VALUES (@lcNewUniqMfgrhd, @lcNewUniq_key, 'GENR', @lcNewProdNo, 'Unk', 99)

			
			INSERT INTO Invtmfgr (Uniq_key, Netable, W_key, UniqWh, UniqMfgrHd)
				VALUES (@lcNewUniq_key, 1, dbo.fn_GenerateUniqueNumber(), @lcWHUniqWh, @lcNewUniqMfgrhd)
			
		END
		-- Supplier
		IF @llEcolCopySupplier = 1
			BEGIN
			INSERT Invtmfsp (UniqMfgrhd, UniqMfsp, UniqSupno, SuplPartNo, Uniq_key, PfdSupl)
				SELECT ZInvtmfhd.UniqMfgrhd As UniqMfgrHd, dbo.fn_GenerateUniqueNumber() AS UniqMfsp, UniqSupno, SuplPartNo, @lcNewUniq_key AS Uniq_key, PfdSupl
					FROM InvtMfsp, @ZInvtMfhd ZinvtMfhd
					WHERE InvtMfsp.UNIQMFGRHD = ZInvtMfhd.OldUniqMfgrhd
					AND InvtMfsp.Is_Deleted = 0
					AND InvtMfsp.Uniq_Key = @lcEcoUniq_Key
		END
		-- Bom_det
		-- 11/01/17 VL Added to copy bom_det.offset request by Fusion
		INSERT @ZBom_det
			SELECT @lcNewUniq_key AS Bomparent, Item_no, Uniq_key, Dept_id, Qty, Item_note, Term_dt, Eff_dt, 
				Used_inkit,	dbo.fn_GenerateUniqueNumber() AS Uniqbomno, UniqBomno AS OldUniqbomno, Offset
				FROM Bom_det
				WHERE BOMPARENT = @lcEcoUniq_key

		-- Update Bom_det if ECO has delete status, replace term_dt with ECO effectiveDt
		-- changed to only update Bom_det_view.Term_dt to EcmainView.EffectiveDt, not deleted per Jerry and approved by Chang
		-- Any NEW part added to an ECO should carry the effectivity date of the ECO effective date. Any part removed by ;
		-- the ECO should still be retained on the new BOM but with an obsolete date of the ECO effective date. If the ;
		-- user does not enter an ECO Effective date, then I think the date the last approval is obtained should be the ;
		-- ECO Effective date.
				
		UPDATE @ZBom_det SET Term_dt = @ldEcoEffectiveDt
			FROM @ZBom_det ZBom_det, ECDETL
			WHERE ZBom_det.OldUniqbomno = ECDETL.UNIQBOMNO
			AND ECDETL.UNIQECNO = @gUniqEcNo
			AND DetStatus = 'Delete'

		-- 01/26/17 VL changed, if user changed the qty, has to make sure eff_dt and term_dt has no date in it
		-- 01/27/17 VL changed to use ECO effective date as Eff_dt
		UPDATE @ZBom_det SET Qty = ECDETL.NewQty, Used_inkit = ECDETL.Used_inkit, Dept_id = ECDETL.Dept_id, 
							Eff_dt = CASE WHEN @ldEcoEffectiveDt IS NULL THEN GETDATE() ELSE @ldEcoEffectiveDt END, Term_dt = NULL
			FROM @ZBom_det ZBom_det, ECDETL
			WHERE ZBom_det.OldUniqbomno = ECDETL.UNIQBOMNO
			AND ECDETL.UNIQECNO = @gUniqEcNo
			AND DetStatus = 'Change Qty'
		
		-- 11/01/17 VL Added to copy bom_det.offset request by Fusion	
		INSERT BOM_DET (Bomparent,Uniq_key, Item_no, Dept_id, Qty, Item_note, Term_dt, Eff_dt, Used_inkit, Uniqbomno, Offset)
			SELECT Bomparent,Uniq_key, Item_no, Dept_id, Qty, Item_note, Term_dt, Eff_dt, Used_inkit, Uniqbomno, Offset
				FROM @ZBom_det
			

		-- Update Bom_det for 'Add' status
		INSERT @ZEcDetlAdd
			SELECT UniqEcDet, dbo.fn_GenerateUniqueNumber() AS Uniqbomno
			FROM EcDetl
			WHERE UniqEcno = @gUniqEcNo
			AND DetStatus = 'Add'
			
		INSERT Bom_det (Bomparent, Uniq_key, Item_no, Dept_id, Qty, Eff_dt, Used_inkit, UniqBomno) 
			SELECT @lcNewUniq_key AS Bomparent, Uniq_key, Item_no, Dept_id, NewQty AS Qty,  
				CASE WHEN @ldEcoEffectiveDt IS NULL THEN GETDATE() ELSE @ldEcoEffectiveDt END AS Eff_dt, 
				Used_inkit,	ZEcDetlAdd.Uniqbomno AS UniqBomno
				FROM EcDetl, @ZEcDetlAdd ZEcDetlAdd
				WHERE EcDetl.UNIQECDET = ZEcDetlAdd.UniqEcDet
	
		-- Update Bom_det for 'Change Qty' status
		IF @llEcoCopyEffDts = 0
			BEGIN
			UPDATE BOM_DET 
				SET Eff_Dt = NULL, Term_Dt = NULL
				WHERE BOMPARENT = @lcNewUniq_key
		END
				
		-- Reference Designators
		IF @llEcoCopyRefDes = 1
			BEGIN
			-- Insert for DetStatus = 'Add' and 'Change Qty' first, these ref_des will get from EcRefDes
			-- Add
			INSERT Bom_ref (UniqBomno, Ref_des, Nbr, Uniqueref)
				SELECT ZEcDetlAdd.Uniqbomno AS UniqBomno, Ref_des, Nbr, dbo.fn_GenerateUniqueNumber() AS Uniqueref
					FROM ECREFDES, @ZEcDetlAdd ZEcDetlAdd
					WHERE ECREFDES.UNIQECDET = ZEcDetlAdd.UniqEcDet
			
			-- Change Qty
			INSERT Bom_ref (UniqBomno, Ref_des, Nbr, Uniqueref)
				SELECT ZBom_det.UniqBomno, Ref_des, Nbr, dbo.fn_GenerateUniqueNumber() AS Uniqueref
					FROM ECREFDES, ECDETL, @ZBom_det ZBom_det
					WHERE ECREFDES.UNIQECDET = ECDETL.UNIQECDET
					AND ZBom_det.OldUniqbomno = ECDETL.UNIQBOMNO
					AND ECDETL.UNIQECNO = @gUniqEcNo
					AND ECDETL.DETSTATUS = 'Change Qty'

									
			-- Now Insert for others that are not changed in ECO, will get from Bom_ref
			INSERT Bom_ref (UniqBomno, Ref_des, Nbr, Uniqueref)
				SELECT ZBom_det.UniqBomno AS UniqBomno, Bom_ref.REF_DES AS Ref_des, Bom_ref.Nbr AS Nbr, 
					dbo.fn_GenerateUniqueNumber() AS Uniqreref
					FROM Bom_ref, @ZBom_det ZBom_det
					WHERE BOM_REF.UNIQBOMNO = ZBom_det.OldUniqbomno
					AND ZBom_det.OldUniqbomno NOT IN 
						(SELECT Uniqbomno
							FROM ECDETL
							WHERE UniqEcno = @gUniqEcno
							AND Uniqbomno <> '') -- Not changed in ECO

		END

		-- Alternate part
		IF @llEcoCopyAltPts = 1
			BEGIN
			INSERT BOM_ALT (BomParent, Alt_for, Uniq_key, BomAltUniq)
				SELECT @lcNewUniq_key AS BomParent, Alt_for, Uniq_key, dbo.fn_GenerateUniqueNumber() AS BomAltUniq
					FROM BOM_ALT
					WHERE BOMPARENT = @lcEcoUniq_key
		END

		IF @llEcoCopyWkCtrs = 1
			BEGIN
			-- Get old, new UniqNumber for later use
			INSERT @ZQuotDept
				SELECT dbo.fn_GenerateUniqueNumber() AS UniqNumber, UniqNumber AS OldUniqNumber
					FROM QUOTDEPT
					WHERE UNIQ_KEY = @lcEcoUniq_key

			-- Get old, new UniqNbra for later use
			INSERT @ZQuotDpdt
				SELECT dbo.fn_GenerateUniqueNumber() AS UniqNbra, UniqNbra AS OldUniqNbra, ZQuotDept.UniqNumber AS UniqNumber, 
					QUOTDPDT.UNIQNUMBER AS OldUniqNumber
					FROM QUOTDPDT, @ZQuotDept ZQuotDept
					WHERE QUOTDPDT.UNIQ_KEY = @lcEcoUniq_key
					AND QUOTDPDT.UNIQNUMBER = ZQuotDept.OldUniqNumber
			
			-- Insert into Quotdept
			INSERT QuotDept
			-- 01/26/17 VL added UniqueRout
			SELECT @lcNewUniq_key AS Uniq_key, Dept_Id, RunTimeSec, Setupsec, Number, ZQuotDept.UniqNumber AS UniqNumber, 
					CASE WHEn @llEcoCopyinst = 1 THEN Std_instr ELSE '' END AS Std_instr,  -- Instruction, Work & Special
					CASE WHEn @llEcoCopyinst = 1 THEN Spec_Instr ELSE '' END AS Spec_Instr, 
					CASE WHEn @llEcoCopyinst = 1 THEN Proc_Note ELSE '' END AS Proc_Note, 
					RevDate, RevInit, PerevNo, Marg_Amt, Tot_Amount, Marg_Perc, WcSetupId, 
					CASE WHEn @llEcoCopyinst = 1 THEN StdIn_Pict ELSE '' END AS StdIn_pict, 
					CASE WHEn @llEcoCopyinst = 1 THEN Spec_Pict ELSE '' END AS Spec_Pict, 
					Certificat, OutsFootNt, PartPerUnt, SerialStrt, 
					CASE WHEN @llEcoCopyssno = 1 THEN Spec_no ELSE '' END AS Spec_no,	-- Standard Specification Number
					UniqueRout
				FROM QuotDept, @ZQuotDept ZQuotDept 
				WHERE QuotDept.UniqNumber = ZQuotDept.OldUniqNumber
				
			-- Insert into QuotDpdt
			INSERT QuotDpdt
			SELECT @lcNewUniq_key AS Uniq_Key, Activ_Id, RunTimaSec, SetupaSec, Numbera, ZQuotDpdt.UniqNumber, 
					CASE WHEn @llEcoCopyinst = 1 THEN Std_instr ELSE '' END AS Std_instr,  -- Instruction, Work & Special
					CASE WHEn @llEcoCopyinst = 1 THEN Spec_Instr ELSE '' END AS Spec_Instr, 
					CASE WHEn @llEcoCopyinst = 1 THEN Proc_Note ELSE '' END AS Proc_Note, 
					CASE WHEn @llEcoCopyinst = 1 THEN StdIn_Pict ELSE '' END AS StdIn_pict, 
					CASE WHEn @llEcoCopyinst = 1 THEN Spec_Pict ELSE '' END AS Spec_Pict, 
					ZQuotDpdt.UniqNbra AS UniqNbra, ActSetTpId 
				FROM QuotDpdt, @ZQuotDpdt ZQuotDpdt
				WHERE QuotDpdt.UniqNbra = ZQuotDpdt.OldUniqNbra

			-- Related Docs, Engineering Notes
			IF @llEcoCopydocs = 1
				BEGIN
				INSERT ASSYDOC (Uniq_key, DocRevNo, DocNo, DocDescr, DocDate, DocNote, Doc_Uniq, DocExec)
					SELECT @lcNewUniq_key AS Uniq_key, DocRevNo, DocNo, DocDescr, DocDate, DocNote, 
						dbo.fn_GenerateUniqueNumber() AS Doc_Uniq, DocExec
					FROM AssyDoc
					WHERE Uniq_key = @lcEcoUniq_key
			END
					
			-- Checklist
			IF @llEcoCopycklist = 1
				BEGIN
				-- for WC
				INSERT WrkCklst (Uniq_key, Dept_activ, Uniqnumber, Number, Chklst_tit, Uniqnbra, WrkCkUniq)
					SELECT @lcNewUniq_key AS Uniq_key, Dept_activ, ZQuotDept.Uniqnumber AS Uniqnumber, Number,
						Chklst_tit, SPACE(10) AS Uniqnbra, dbo.fn_GenerateUniqueNumber() AS WrkCkUniq
					FROM Wrkcklst, @ZQuotdept ZQuotdept
					WHERE Uniq_key = @lcEcoUniq_key
					AND Wrkcklst.Uniqnumber = ZQuotdept.OldUniqnumber
					AND WRKCKLST.Uniqnbra = ''
				
				-- for Activity
				INSERT WrkCklst (Uniq_key, Dept_activ, Uniqnumber, Number, Chklst_tit, Uniqnbra, WrkCkUniq)
					SELECT @lcNewUniq_key AS Uniq_key, Dept_activ, ZQuotDpdt.Uniqnumber AS Uniqnumber, Number,
						Chklst_tit, ZQuotDpdt.Uniqnbra AS Uniqnbra, dbo.fn_GenerateUniqueNumber() AS WrkCkUniq
					FROM Wrkcklst, @ZQuotDpdt ZQuotDpdt
					WHERE Uniq_key = @lcEcoUniq_key
					AND (Wrkcklst.Uniqnbra = ZQuotdpdt.OldUniqNbra
					AND Wrkcklst.Uniqnbra <> '')
			END
		END -- @llEcoCopyWkCtrs

		-- WO Check List
		IF @llEcoCopyWoList = 1
			BEGIN
			INSERT Assychk
				-- 01/26/17 VL added isMnxCheck
				SELECT @lcNewUniq_key AS Uniq_Key, ShopFl_chk, dbo.fn_GenerateUniqueNumber() AS ChkUniq, isMnxCheck
					FROM AssyChk
					WHERE Uniq_Key = @lcEcoUniq_Key
		END
		
		-- Tooling
		IF @llEcoCopytool = 1
			BEGIN
			INSERT Tooling (ToolId, Uniq_Key, Dept_Id, ToolDescr, ToolLoc, ExpireDate)
				SELECT dbo.fn_GenerateUniqueNumber() AS ToolId, @lcNewUniq_Key AS Uniq_Key, Dept_Id, ToolDescr, 
						ToolLoc, ExpireDate
					FROM Tooling
					WHERE Uniq_Key = @lcEcoUniq_Key
		END
		
		-- Anti Avl
		-- From EcAntiAvl first
		-- {07/24/13 VL found a problem that might cause duplicate antiavl records, if user enter same part number multiple times in ECO (with different dept_id), when save it will have same uniq_key, partmfgr, mfgr_pt_no for different UniqEcdet
		--INSERT ANTIAVL
		--	SELECT @lcNewUniq_key AS BomParent, Uniq_key, Partmfgr, Mfgr_pt_no, dbo.fn_GenerateUniqueNumber() AS UniqAnti
		--		FROM ECANTIAVL
		--		WHERE UNIQECNO = @gUniqEcNo
		--		AND UNIQECDET NOT IN 
		--			(SELECT UNIQECDET 
		--				FROM ECDETL
		--				WHERE UNIQECNO = @gUniqEcNo
		--				AND DETSTATUS = 'Delete')

		;
		WITH ZUniAntiAvl AS
		(
			SELECT DISTINCT @lcNewUniq_key AS BomParent, Uniq_key, Partmfgr, Mfgr_pt_no
				FROM ECANTIAVL
				WHERE UNIQECNO = @gUniqEcNo
				AND UNIQECDET NOT IN 
					(SELECT UNIQECDET 
						FROM ECDETL
						WHERE UNIQECNO = @gUniqEcNo
						AND DETSTATUS = 'Delete')	
		)
		--10/07/15 YS need to name columns in the insert part as well as select part of antiavl
		INSERT INTO ANTIAVL
		([BOMPARENT]
           ,[UNIQ_KEY]
           ,[PARTMFGR]
           ,[MFGR_PT_NO]
           ,[UNIQANTI])
			SELECT BomParent, Uniq_key, Partmfgr, Mfgr_pt_no, dbo.fn_GenerateUniqueNumber() AS UniqAnti
				FROM ZUniAntiAvl
		-- 07/24/13 VL End}
					
		-- 06/28/13 VL un-comment out again, found Ecantiavl only has the antiavl for entered items, for those items that are not entered in ECO, still need to get from BOM
		-- 01/22/13 VL comment out next Insert because Ecantiavl should have all necessary records, no need to get from Antiavl from original part again
		-- From Antiavl for other parts, need to filter out Delete status	
		--10/07/15 YS need to name columns in the insert part as well as select part of antiavl
		INSERT INTO ANTIAVL
		([BOMPARENT]
           ,[UNIQ_KEY]
           ,[PARTMFGR]
           ,[MFGR_PT_NO]
           ,[UNIQANTI])
			SELECT @lcNewUniq_key AS BomParent, Uniq_key, Partmfgr, Mfgr_pt_no, dbo.fn_GenerateUniqueNumber() AS UniqAnti
				FROM ANTIAVL
				WHERE BOMParent = @lcEcoUniq_key
				AND Uniq_key+Partmfgr+Mfgr_pt_no NOT IN
					(SELECT Uniq_key+Partmfgr+Mfgr_pt_no
						FROM ECANTIAVL
						WHERE UNIQECNO = @gUniqEcNo)
				AND UNIQ_KEY NOT IN
					(SELECT UNIQ_KEY
						FROM ECDETL
						WHERE UNIQECNO = @gUniqEcNo)
						-- 07/01/13 VL removed the DetStatus = 'Delete' because we should separate two parts, one is get records from Ecantiavl,
						-- then for those parts that didn't get changed, need to get them all from Antiavl, so just filter out those uniq_key that's
						-- found in Ecdetl, don't need to check status
						--AND DETSTATUS = 'Delete')
		 --01/22/13 VL End}				
		
		-- Check if has consigned part
		INSERT @ZConsgInvt
			SELECT dbo.fn_GenerateUniqueNumber() AS Uniq_key, Uniq_key AS OldUniq_key
				FROM INVENTOR 
				WHERE INT_UNIQ = @lcEcoUniq_key
		
		IF @@ROWCOUNT > 0
			BEGIN
			--09/07/12 YS Inventor table has new filed ImportId ; added an empty value at the end of the insert
			-- 01/23/13 VL found CAST('' as uniqueidentifier) will cause conversion error, change to CAST(NULL as uniqueidentifier)
			INSERT INVENTOR 
						(Uniq_key, Part_class, Part_type, Custno, 
			Part_no,Revision ,  Prod_id,CustPartno, CustRev, 
			 Descript, U_of_meas, Pur_uofm, 
			 Ord_Policy , 
			 Package, No_Pkg, 
			 INV_NOTE , 
			Buyer_type, 
			 Stdcost, 
			 Minord, 
			Ordmult, Usercost, Pull_in, Push_out, 
			Ptlength, Ptwidth, Ptdepth, Fginote, [Status], Perpanel, 
			 Abc, Layer, Ptwt, Grosswt, 
			 Reorderqty, 
			 Reordpoint, Part_spec, Pur_ltime, Pur_lunit, 
			 Kit_ltime, 
			 Kit_lunit, 
			 Prod_ltime, 
			 Prod_lunit, Udffield1, Wt_avg, 
			Part_sourc, Insp_req, Cert_req, Cert_type, Scrap, SetupScrap, Outsnote, Bom_status, 
			Bom_note,  Bom_lastdt, 
			 Serialyes, Loc_type, 
			 [DAY], 
			 Dayofmo, 
			 Dayofmo2, Saletypeid, Feedback, Eng_note, 
			 Bomcustno, 
			 LaborCost, Int_uniq, Eau, 
			 Require_sn, Ohcost, 
			 Phant_make,	Cnfgcustno,	Confgdate, Confgnote, 
			Xferdate, Xferby, Prodtpuniq, Mrp_code, Make_Buy, Labor_oh, Matl_oh, 
			 Matl_Cost, Overhead, 
			Other_cost, StdbldQty, Usesetscrp, Configcost, Othercost2, 
			 Matdt , 
			 Labdt, Ohdt, Othdt, Oth2dt, 
			StdDt, Arcstat, Is_ncnr, Toolrel, 
			Toolreldt, ToolRelInt, Pdmrel, Pdmreldt, Pdmrelint,	Itemlock, Lockdt, Lockinit, Lastchangedt, 
			Lastchangeinit, Bomlock, Bomlockinit, Bomlockdt, Bomlastinit, Routrel, Routreldt, Routrelint, 
			Targetprice, Firstarticle, Mrc, Targetpricedt, Ppm,	Matltype, Newitemdt, Bominactdt, Bominactinit, 
			Mtchgdt, Mtchginit, Bomitemarc, Cnfgitemarc, C_log, importid,useIpKey)
			SELECT ZConsgInvt.Uniq_key AS Uniq_key, Part_class, Part_type, Custno, 
					CASE WHEN @llEcoChgProdNo = 1 THEN @lcEcoNewProdNo ELSE Part_no END AS Part_no, 
					CASE WHEN @llEcoChgRev = 1 THEN @lcECoNewRev ELSE Revision END AS Revision, Prod_id, CustPartno, CustRev, 
					CASE WHEN @llEcoChgDescr = 1 THEN @lcEcoNewDescr ELSE DESCRIPT END AS Descript, U_of_meas, 
					CASE WHEN Pur_uofm = '' THEN U_OF_MEAS ELSE PUR_UOFM END AS Pur_uofm, Ord_Policy, 
					Package, No_Pkg, Inv_note, Buyer_type, 0 AS Stdcost, Minord, Ordmult, Usercost, 
					Pull_in, Push_out, Ptlength, Ptwidth, Ptdepth, Fginote, Status, Perpanel, '' AS Abc, 
					Layer, Ptwt, Grosswt, Reorderqty, Reordpoint, Part_spec, Pur_ltime, Pur_lunit, 
					Kit_ltime, Kit_lunit, 0 AS Prod_ltime, '' AS Prod_lunit, Udffield1, 0 AS Wt_avg, 
					'CONSG' AS Part_sourc, Insp_req, 0 AS Cert_req, '' AS Cert_type, Scrap, SetupScrap, 
					Outsnote, '' AS Bom_status, '' AS Bom_note, NULL AS Bom_lastdt, Serialyes, Loc_type, 
					DAY, Dayofmo, Dayofmo2, '' AS Saletypeid, Feedback, Eng_note, '' AS Bomcustno, 
					0 AS LaborCost, @lcNewUniq_key AS Int_uniq, 0 AS Eau, Require_sn, Ohcost, Phant_make,
					Cnfgcustno,	Confgdate, Confgnote, Xferdate, Xferby, Prodtpuniq, Mrp_code, Make_Buy, 
					Labor_oh, Matl_oh, Matl_Cost, Overhead, Other_cost, StdbldQty, Usesetscrp, Configcost, 
					Othercost2, MatDt, Labdt, Ohdt, Othdt, Oth2dt, StdDt, Arcstat, Is_ncnr, 0 AS Toolrel, 
					NULL AS Toolreldt, '' AS ToolRelInt, 0 AS Pdmrel, NULL AS Pdmreldt, '' AS Pdmrelint, 
					0 AS Itemlock, NULL AS Lockdt, '' AS Lockinit, GETDATE() AS Lastchangedt, 
					@lcUserID AS LastChangeInit, 0 AS Bomlock, '' AS Bomlockinit, NULL AS Bomlockdt, 
					'' AS Bomlastinit, 0 AS Routrel, NULL AS Routreldt, '' AS Routrelint, Targetprice, 
					Firstarticle, Mrc, Targetpricedt, Ppm, Matltype, Newitemdt, NULL AS Bominactdt, 
					'' AS Bominactinit, NULL AS Mtchgdt, '' AS Mtchginit, 0 AS Bomitemarc, Cnfgitemarc, C_log, 
					CAST(NULL as uniqueidentifier) AS importid,useIpKey
				FROM INVENTOR, @ZConsgInvt ZConsgInvt
				WHERE Inventor.Uniq_key = ZConsgInvt.OldUniq_key


			-- Will use this temp table to update invtmfhd and invtmfgr
			DELETE FROM @ZInvtMfhd WHERE 1=1
			
			INSERT @ZInvtMfhd 
				SELECT ZConsgInvt.Uniq_key AS Uniq_key, PartMfgr, dbo.PADR(LTRIM(RTRIM(@lcNewProdNo)),30,' ') AS Mfgr_pt_no, 
					UniqMfgrHd AS OldUniqMfgrHd, dbo.fn_GenerateUniqueNumber() AS UniqMfgrHd, Part_Spec,
					MatlType, AutoLocation, OrderPref, MatlTypeValue, lDisAllowBuy, lDisAllowKit, Sftystk
				FROM InvtMfhd, @ZConsgInvt ZConsgInvt
				WHERE InvtMfhd.Uniq_key = ZConsgInvt.OldUniq_key
				AND Is_Deleted = 0
			
			IF @@ROWCOUNT > 0
				BEGIN
				-- need to delete duplicate uniq_key+partmfgr+mfgr_pt_no because mfgr_pt_no was created from @lcnewProdNo
				---- use CTE with DELETE statement. This will delete duplicate from underline table 
				WITH DuplMfgr (Partmfgr, Mfgr_pt_no, OldUniqMfgrHd, DuplicateCount)
				AS
				(
					SELECT Partmfgr, Mfgr_pt_no, OldUniqMfgrHd,
					ROW_NUMBER() OVER(PARTITION BY Partmfgr, Mfgr_pt_no ORDER BY OldUniqMfgrHd) AS DuplicateCount
					FROM @ZInvtMfhd
				)
				DELETE
				FROM DuplMfgr
				WHERE DuplicateCount > 1

				-- Insert Invtmfhd
				INSERT INVTMFHD (Uniqmfgrhd, Uniq_key, Partmfgr, Mfgr_pt_no, MatlType, AutoLocation, OrderPref, MatlTypeValue, 
					lDisAllowBuy, lDisAllowKit, Sftystk)
					SELECT Uniqmfgrhd, Uniq_key, Partmfgr, Mfgr_pt_no, MatlType, AutoLocation, OrderPref, MatlTypeValue, 
						lDisAllowBuy, lDisAllowKit, Sftystk
						FROM @ZInvtMfhd

				-- Insert Invtmfgr
				INSERT Invtmfgr (Uniq_key, Netable, W_key, UniqWh, UniqMfgrHd, Location)
					SELECT ZinvtMfhd.Uniq_key, 1 AS Netable, dbo.fn_GenerateUniqueNumber() AS W_key,
						UniqWh, ZInvtmfhd.UniqMfgrhd As UniqMfgrHd, Location 
						FROM Invtmfgr, @ZInvtMfhd ZinvtMfhd
						WHERE INVTMFGR.UNIQMFGRHD = ZInvtMfhd.OldUniqMfgrhd
						AND NetAble = 1
						AND Is_Deleted = 0
						AND UniqWh NOT IN 
							(SELECT UniqWh 
								FROM Warehous 
								WHERE WareHouse = 'MRB   ' 
								OR WareHouse = 'WIP   '
								OR WareHouse = 'WO-WIP') 								
							
			END					
			
			-- Now check if any	@ZConsgInvt uniq_key not in @ZInvtmfhd, then need to insert invtmfhd and invtmfgr
			INSERT @ZNoInvtMfhdinConsgHd
				SELECT Uniq_key, dbo.fn_GenerateUniqueNumber() AS Uniqmfgrhd
					FROM @ZConsgInvt
					WHERE Uniq_key NOT IN 
						(SELECT Uniq_key FROM @ZInvtMfhd)						
			
			IF @@ROWCOUNT > 0
				-- If didn't find any invtmfhd records for Consign Uniq_key, need to insert new invtmfhd and invtmfgr for new consigned part
				BEGIN
				INSERT INVTMFHD	(UniqMfgrHd, Uniq_key, Partmfgr, Mfgr_pt_no, Matltype, Orderpref)
					SELECT ZNoInvtMfhdinConsgHd.UniqMfgrHd AS UniqMfgrhd, ZNoInvtMfhdinConsgHd.Uniq_key AS Uniq_key, 
							'GENR' AS Partmfgr, @lcNewProdNo AS Mfgr_pt_no, 'Unk' AS MatlType, 99 AS Orderpref
						FROM @ZNoInvtMfhdinConsgHd ZNoInvtMfhdinConsgHd
					
				INSERT INTO Invtmfgr (Uniq_key, Netable, W_key, UniqWh, UniqMfgrHd)
					SELECT ZNoInvtMfhdinConsgHd.Uniq_key AS Uniq_key, 1 AS Netable, 
							dbo.fn_GenerateUniqueNumber() AS W_key, @lcWHUniqWh AS UniqWh,  	
							ZNoInvtMfhdinConsgHd.UniqMfgrhd AS UniqMfgrHd
						FROM @ZNoInvtMfhdinConsgHd ZNoInvtMfhdinConsgHd
		
			END
			
		END -- End of @@ROWCOUNT of @ZConsgInvt

		EXEC [sp_UpdEcoSo] @gUniqEcno, @lcNewUniq_key, @lcUserId
		
		EXEC [sp_UpdEcoWo] @gUniqEcno, @lcNewUniq_key, @lcUserId
		
		-- Update NRE tooling
		INSERT TOOLING
			SELECT dbo.fn_GenerateUniqueNumber() AS Toolid, @lcNewUniq_Key AS Uniq_key, Dept_id, Text AS ToolDescr, 
			' ' AS Toolloc, TerminatDt AS ExpireDate, EcNre.Uniqfield 
				FROM Ecnre, Support 
				WHERE Ecnre.Uniqfield = Support.UniqField 
				AND ECNRE.UNIQECNO = @gUniqEcNo

		END	-- End of ECO
	
		
ELSE
	BEGIN
-- @lcEcoChangeType = 'BCN' now
	-- 05/31/12 VL added U_of_meas char(4)
	-- 05/06/16 VL fixed CustPartno char(15) to char(25)
	DECLARE @ZEcdetl TABLE (nRecno int identity, Uniqecdet char(10), Uniqecno char(10), Uniq_key char(10), DetStatus char(10), 
		OldQty numeric(9,2), NewQty numeric(9,2), Used_inkit char(1), Part_class char(8), Part_type char(8), Custno char(10),
		Part_no char(25), Revision char(8), CustPartno char(25), Custrev char(8), Descript char(45), Part_sourc char(10),
		ChgAmt numeric(13,5), Item_no numeric(4,0), Scrapitem bit, Stdcost numeric(13,5), Dept_id char(4),
		UniqBomno char(10), Status char(8), U_of_meas char(4))

	INSERT @ZEcdetl EXEC [EcDetlView] @gUniqEcno
	
	SET @lnTotalNo = @@ROWCOUNT;
	IF (@lnTotalNo>0)
	BEGIN
		SET @lnCount=0;
		WHILE @lnTotalNo>@lnCount
		BEGIN	
			SET @lnCount=@lnCount+1;
			SELECT @lcEcdUniqecdet = Uniqecdet, @lcEcdUniq_key = Uniq_key, @lcEcdDetStatus = DetStatus,
				@lnEcdOldQty = OldQty, @lnEcdNewQty = NewQty, @lnEcdItem_no = Item_no, 
				@lcEcdDept_id = Dept_id, @lcEcdUniqBomno = UniqBomno, @lcEcdUsed_inKit = Used_inKit
				FROM @ZEcdetl WHERE nrecno = @lnCount	
			IF (@@ROWCOUNT<>0)
			BEGIN
				IF @lcEcdDetStatus = 'Add'
					BEGIN
					
					SET @lcNewUniqBomno = dbo.fn_GenerateUniqueNumber()
					
					-- Bom_det
					INSERT BOM_DET (Bomparent, Uniq_key, Item_no, Dept_id, Qty, Eff_dt, Used_inkit, Uniqbomno)
						VALUES (@lcEcoUniq_key, @lcEcdUniq_key, @lnEcdItem_no, @lcEcdDept_id, @lnEcdNewQty, @ldEcoEffectiveDt, 
							@lcEcdUsed_inKit, @lcNewUniqBomno)
						
					-- AntiAvl
					--10/07/15 YS need to name columns in the insert part as well as select part of antiavl
					INSERT INTO ANTIAVL
						([BOMPARENT]
						,[UNIQ_KEY]
						,[PARTMFGR]
						,[MFGR_PT_NO]
						,[UNIQANTI])
						SELECT @lcEcoUniq_key AS BomParent, Uniq_key, Partmfgr, Mfgr_pt_no, dbo.fn_GenerateUniqueNumber() AS UniqAnti
							FROM ECANTIAVL
							WHERE UNIQEcDet = @lcEcdUniqecdet

					-- Bom Ref
					INSERT Bom_ref (UniqBomno, Ref_des, Nbr, Uniqueref)
							SELECT @lcNewUniqBomno AS UniqBomno, Ref_des, Nbr, dbo.fn_GenerateUniqueNumber() AS Uniqueref
								FROM ECREFDES
								WHERE UNIQEcDet = @lcEcdUniqecdet
				END -- End of @lnEcdDetStatus = 'Add'
			
				IF @lcEcdDetStatus = 'Delete'
					BEGIN
						IF @lcEcoBomCustno <> '' AND @lcEcoBomCustno <> '000000000~'
							BEGIN
							SELECT @lcAntiavlcUniq_key = Uniq_key
								FROM Inventor
								WHERE Int_uniq = @lcEcdUniq_key
								AND Custno = @lcEcoBomCustno
								AND Part_sourc = 'CONSG     '
							
							IF @@ROWCOUNT = 0
								SET @lcAntiavlcUniq_key = @lcEcdUniq_key
							END
						ELSE
							BEGIN
								SET @lcAntiavlcUniq_key = @lcEcdUniq_key
							END
					-- Delete Bom_ref
 				 	DELETE FROM Bom_ref WHERE UniqBomno = @lcEcdUniqBomno

					-- Check to see if the same part is in the BOM with another item_no, don't delete alternate parts & AVL if found
					SELECT @lcAnotherSameItem = UniqBomno 
						FROM BOM_DET 
						WHERE BOMPARENT = @lcEcoUniq_key 
						AND UNIQ_KEY = @lcEcdUniq_key
						AND UniqBomno <> @lcEcdUniqBomno
						
					IF @@ROWCOUNT > 0
						BEGIN
						DELETE FROM BOM_ALT
							WHERE BOMPARENT = @lcEcoUniq_key
							AND UNIQ_KEY = @lcEcdUniq_key

						DELETE FROM AntiAvl 
							WHERE Bomparent = @lcEcoUniq_key
							AND Uniq_key = @lcAntiavlcUniq_key
					END	

					-- Delete Bom_det_View
					UPDATE BOM_DET
						SET TERM_DT = @ldEcoEffectiveDt
						WHERE UNIQBOMNO = @lcEcdUniqBomno
														
				END -- End of @lnEcdDetStatus = 'Delete'
				IF @lcEcdDetStatus = 'Change Qty'
					BEGIN
					-- 01/28/13 VL added to update Dept_id
					-- 01/26/17 VL changed, if user changed the qty, has to make sure eff_dt and term_dt has no date in it
					-- 01/27/17 VL changed to use ECO effective date as Eff_dt
							UPDATE BOM_DET SET QTY = @lnEcdNewQty,
										Used_inkit = @lcEcdUsed_inKit,
										DEPT_ID = @lcEcdDept_id,
										Eff_dt = CASE WHEN @ldEcoEffectiveDt IS NULL THEN GETDATE() ELSE @ldEcoEffectiveDt END, 
										Term_dt = NULL
						WHERE UNIQBOMNO = @lcEcdUniqBomno
					
					IF @lcEcoBomCustno <> '' AND @lcEcoBomCustno <> '000000000~'
						BEGIN
						SELECT @lcAntiavlcUniq_key = Uniq_key
							FROM Inventor
							WHERE Int_uniq = @lcEcdUniq_key
							AND Custno = @lcEcoBomCustno
							AND Part_sourc = 'CONSG     '
						
						IF @@ROWCOUNT = 0
							SET @lcAntiavlcUniq_key = @lcEcdUniq_key
						END
					ELSE
						BEGIN
							SET @lcAntiavlcUniq_key = @lcEcdUniq_key
						END

				
					-- Update Antiavl
					DELETE FROM AntiAvl 
					WHERE Bomparent = @lcEcoUniq_key
					AND Uniq_key = @lcAntiavlcUniq_key

					--10/07/15 YS need to name columns in the insert part as well as select part of antiavl
					INSERT INTO ANTIAVL
					([BOMPARENT]
					   ,[UNIQ_KEY]
					   ,[PARTMFGR]
					   ,[MFGR_PT_NO]
					   ,[UNIQANTI])
						SELECT @lcEcoUniq_key AS BomParent, Uniq_key, Partmfgr, Mfgr_pt_no, dbo.fn_GenerateUniqueNumber() AS UniqAnti
							FROM ECANTIAVL
							WHERE UNIQECDET = @lcEcdUniqecdet
					
					-- Update Bom Ref
					DELETE FROM Bom_Ref WHERE UniqBomno = @lcEcdUniqbomno
					
					INSERT Bom_ref (UniqBomno, Ref_des, Nbr, Uniqueref)
							SELECT @lcEcdUniqBomno AS UniqBomno, Ref_des, Nbr, dbo.fn_GenerateUniqueNumber() AS Uniqueref
								FROM ECREFDES
								WHERE Uniqecdet = @lcEcdUniqEcDet
									
				END -- End of @lnEcdDetStatus = 'Change Qty'
			END
		END -- End of WHILE @lnTotalNo>@lnCount
	END -- of (@lnTotalNo>0)

	-- Not setting up a new inventory record, the only changes can be StdCost and/or Labor cost
	IF @llEcoChgLbCost = 1
		BEGIN
		UPDATE Inventor SET LaborCost = @lnEcoNewLbCost, LabDt = GETDATE() 
				WHERE UNIQ_KEY = @lcEcoUniq_key
	END
	IF @llEcoChgStdCost = 1
		BEGIN
		UPDATE Inventor SET Matl_Cost = @lnEcoNewMatlCst, MatDt = GETDATE(),
							StdCost = @lnEcoNewMatlCst + LaborCost + Overhead + Other_Cost + OtherCost2, 
							StdDt = GETDATE()
				WHERE UNIQ_KEY = @lcEcoUniq_key
	END
	
	-- 05/31/12 VL added WHERE UNIQ_KEY = @lcEcoUniq_key
	UPDATE INVENTOR SET Bom_LastDt = GETDATE(),
					 	BomLastInit	= @lcUserID
			WHERE UNIQ_KEY = @lcEcoUniq_key
		 	
		 	
	END -- End of @lcEcoChangeType = 'BCN'
END -- END of update ECO and BCN		

UPDATE ECMAIN SET	EcStatus = 'Completed', 
					UpdatedDt = GETDATE()
		WHERE UNIQECNO = @gUniqEcno

-- Check if any inactive part is added, will update status
SELECT @lcChkUniq_key = Uniq_key
	FROM INVENTOR
	WHERE UNIQ_KEY IN 
		(SELECT UNIQ_KEY 
			FROM ECDETL
			WHERE UNIQECNO = @gUniqEcNo
			AND DETSTATUS <> 'Delete')
	AND STATUS = 'Inactive'
IF @@ROWCOUNT > 0
	UPDATE INVENTOR SET STATUS = 'Active', LASTCHANGEDT = GETDATE(), LASTCHANGEINIT = @lcUserID
		WHERE UNIQ_KEY IN 
		(SELECT UNIQ_KEY 
			FROM ECDETL
			WHERE UNIQECNO = @gUniqEcNo
			AND DETSTATUS <> 'Delete')
		AND STATUS = 'Inactive'
END TRY

BEGIN CATCH
	SELECT @ErrorNumber = ERROR_NUMBER(),
			   @ErrorMessage = ERROR_MESSAGE(),
			   @ErrorProcedure= ERROR_PROCEDURE(),
			   @ErrorLine= ERROR_LINE()

      RAISERROR ('Error occurred in updating ECO records. This operation will be cancelled. 
                  Error Number        : %d
                  Error Message       : %s  
                  Affected Procedure  : %s
                  Affected Line Number: %d'
                  , 16, 1
                  , @ErrorNumber, @ErrorMessage, @ErrorProcedure,@ErrorLine)
       
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
	
*/
END