-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/25/2013
-- Reports using:  unrcacct
-- Description:	Procedure for Un-Reconciled Receipt Account Value (in vfp report form was UNRCACCT)
-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
-- 05/28/15 YS remove ReceivingStatus
-- 05/29/2015 DRP:  added the /*SUPPLIER LIST*/ to the procedure. 
-- 01/05/2017 VL:   added functional currency fields	
-- 01/07/17 DRP:  added SetupUnReconGL to the results so I can use that to pull in the setup GL Accoutn assigned for Unrecon Receipts.  then changed the name from <<Unrecon_gl_nbr>> to be <<RecptUnReconGL>> this will just reflect what the receipt was associated to for GL Account number. <<will more than likely not be used on the report form.>>
--				These changes came from the fact that the UnreCon should reside under the Liabilites not Assets so we had to make some changes to the setup, and if the user need to make the same changes I needed to update the report to work with these changes. 
-- =============================================
CREATE PROCEDURE [dbo].[rptUnreconciledAcctvalue] 
	-- Add the parameters for the stored procedure here
	@userId uniqueidentifier = null		--03/31/2014 DRP Added
	
AS
BEGIN

/*SUPPLIER LIST*/	--05/29/2015 DRP:   Added
-- 12/03/13 YS get list of approved suppliers for this user
DECLARE  @tSupplier tSupplier
DECLARE @Supplier TABLE (Uniqsupno char(10))
-- get list of Suppliers for @userid with access
INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, 'All' ;
INSERT INTO @Supplier SELECT UniqSupno FROM @tSupplier

-- 01/05/17 VL added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
	;WITH
UnrecRecords
as
(
 -- 01/05/17 VL added presentation currency fields
SELECT  Supinfo.Supname,Poitems.Ponum,Inventor.Part_no,Inventor.Revision,Inventor.Descript,Inventor.Uniq_Key,
			PorecDtl.ReceiverNo,PorecDtl.RecvDate,
			CASE WHEN Porecrelgl.debitrawacct=1 THEN Porecrelgl.TransQty ELSE -Porecrelgl.TransQty END AS TransQty,
			Porecrelgl.UniqRecRel
			,PorecrelGl.Unrecon_gl_nbr as RecptUnReconGL	--01/07/17 DRP:  Changed the name of the field to be RecptUnReconGL.
			,porecrelGl.RAW_GL_NBR ,Inventor.StdCost,invsetup.UNRECON_GL_NO as SetupUnReconGL	--01/07/17 DRP:  added SetupUnReconGL to the results. 
			-- 01/05/17 VL added presentation currency fields
			,CASE WHEN @lFCInstalled = 0 THEN 0.00000 ELSE Inventor.StdCostPR END AS StdCostPR
		FROM Inventor INNER JOIN Poitems ON Inventor.UNIQ_KEY=Poitems.UNIQ_KEY 
		INNER JOIN Porecdtl ON Poitems.UNIQLNNO=porecdtl.UNIQLNNO 
		INNER JOIN Porecloc ON Porecdtl.UNIQRECDTL =porecloc.FK_UNIQRECDTL 
		INNER JOIN Pomain on poitems.PONUM=pomain.ponum
		INNER JOIN Supinfo on pomain.UNIQSUPNO =supinfo.UNIQSUPNO 
		INNER JOIN porecrelgl on Porecloc.LOC_UNIQ=porecrelgl.LOC_UNIQ 
		outer apply invsetup 
		--- make sure only receivers that were complete are selected
		-- 05/28/15 YS remove ReceivingStatus
		--WHERE (PORECDTL.ReceivingStatus='Complete' or PORECDTL.ReceivingStatus=' ')
		where  (Porecloc.Sinv_uniq=' ' OR Porecloc.Sinv_uniq IN (SELECT Sinv_uniq FROM Sinvoice WHERE Sinvoice.is_rel_ap=0))
		and 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @Supplier) THEN 1 ELSE 0  END		--05/29/2015 DRP:  Added
)
SELECT  Supname,Ponum,Part_no,Revision,Descript,Uniq_Key,ReceiverNo,RecvDate,RecptUnReconGL,StdCost,
		SUM(TransQty) AS Sum_transqty,SUM(TransQty)*STDCOST as Extend_amount
		,SetupUnReconGL
		 -- 01/05/17 VL added presentation currency fields
		,StdCostPR, SUM(TransQty)*STDCOSTPR as Extend_amountPR
		FROM UnrecRecords
		GROUP BY Supname,Ponum,Part_no,Revision,Descript,Uniq_Key,ReceiverNo,RecvDate,RecptUnReconGL,StdCost,SetupUnReconGL,StdCostPR
		HAVING SUM(TransQty)*StdCost<>0.00 
		ORDER BY Supname,Ponum,RecvDate,Part_no
		
END