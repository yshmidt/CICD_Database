-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <04/12/2011>
-- Description:	<Procedure to find allocation information>
-- this procedure will return 2 SQL results ; header and details
-- modified: 10/08/14 YS replace invtmfhd table with 2 new tables
--- 04/14/15 YS change "location" column length to 256
--02/02/17 YS removed serialno from invt_res table
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================
CREATE PROCEDURE [dbo].[GetAllocation4Project]
	-- Add the parameters for the stored procedure here
	@lcPrjUnique char(10) =' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--DECLARE @tAllocHeader Table (Uniq_key char(10),Wono char(10),PrjNumber char(10),Fk_PrjUnique char(10),Part_no char(25),Revision char(8),Part_class char(8),
	--							Part_Type char(8),Descript char(45), Part_Sourc char(10),U_of_meas char(4)) ;	
	--- 04/14/15 YS change "location" column length to 256
	--02/09/18 YS changed size of the lotcode column to 25 char
	DECLARE @tAllocDet Table ( Qtyalloc Numeric(12,2),Uniq_Key char(10),DateTime smalldatetime, Saveinit char(8), Invtres_no char(10),
								partmfgr char(8),mfgr_pt_no char(30),whno char(3),location varchar(256), w_key char(10),uniqwh char(10),
								RefInvtRes char(10),AvailQty numeric(12,2),lotcode nvarchar(25),expdate smalldatetime,reference char(12),
	  							Ponum char(15),LotResQty numeric(12,2),warehouse char(6),
	  							Fk_PrjUnique char(10),wono char(10),SerialNo char(30),SerialUniq char(10),OldQtyAlloc numeric(12,2)) ; 
	  							
-- 10/08/14 YS replace invtmfhd table with 2 new tables	  							
  INSERT INTO @tAllocDet SELECT R.Qtyalloc,R.Uniq_Key, R.DateTime, R.Saveinit, R.Invtres_no, 
				M.partmfgr, M.mfgr_pt_no, Warehous.whno, Invtmfgr.location, Invtmfgr.w_key,INVTMFGR.UNIQWH, 
				R.RefInvtRes,
				CASE WHEN Invtlot.lotqty IS NULL THEN Invtmfgr.qty_oh-Invtmfgr.reserved ELSE Invtlot.lotqty-Invtlot.lotresqty END AS AvailQty, 
	  			R.LOTCODE,R.expdate,R.reference,R.PONUM,R.QtyAlloc as LotResQty,
	  			Warehous.warehouse, 
	  			R.Fk_PrjUnique,R.wono,R.SerialNo,R.SerialUniq, R.QtyAlloc AS OldQtyAlloc 
		--02/02/17 YS removed serialno from invt_res table
		FROM (SELECT Qtyalloc,a.Uniq_Key,a.DateTime, a.Saveinit, A.Invtres_no,a.LOTCODE,a.EXPDATE,a.REFERENCE,a.PONUM,a.wono,a.FK_PRJUNIQUE,isnull(invtser.SERIALNO,space(30)) as serialno,
			isnull(rs.serialuniq,space(10)) as serialuniq,w_key,RefInvtRes
	  	 	FROM Invt_res A left outer join ireserveSerial RS on A.invtres_no=rs.invtres_no
			left outer join invtser on rs.serialuniq=invtser.serialuniq
	  	 	WHERE Fk_PrjUnique = @lcPrjUnique
	  	 	AND RefInvtRes=' '
	  	 	AND NOT EXISTS (SELECT RefInvtRes from INVT_RES as U where U.Fk_PrjUnique=@lcPrjUnique and u.REFINVTRES = A.INVTRES_NO )) as R INNER JOIN INVTMFGR ON INVTMFGR.W_KEY=R.W_KEY 
			--INNER JOIN INVTMFHD ON INVTMFGR.UNIQMFGRHD = INVTMFHD.UNIQMFGRHD 
			INNER JOIN InvtMPNLink L ON INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD 
			INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
			INNER JOIN Warehous ON INVTMFGR.UNIQWH = WAREHOUS.UNIQWH 
			LEFT OUTER JOIN invtlot ON R.W_key= Invtlot.W_key 
			and R.lotcode=Invtlot.lotcode
			and R.expdate=Invtlot.expdate
			and R.reference=Invtlot.reference
			and R.Ponum=Invtlot.Ponum 
		WHERE  R.Fk_PrjUnique = @lcPrjUnique
	  
	  -- this is SQLResult generates detail records
	  select * from @tAllocDet					
	  -- this is SqlResult1 - generates header records	
	  SELECT DISTINCT D.Uniq_key, D.wono,PjctMain.PrjNumber,Fk_PrjUnique,Inventor.Part_No, 
			Inventor.Revision, Inventor.Part_Class, Inventor.Part_Type, 
			Inventor.Descript, Part_Sourc, Inventor.U_of_meas
			FROM @tAllocDet D INNER JOIN PjctMain ON D.Fk_PrjUnique =PJCTMAIN.PRJUNIQUE 
			INNER JOIN  Inventor ON D.Uniq_Key = Inventor.Uniq_key  
			
		
END