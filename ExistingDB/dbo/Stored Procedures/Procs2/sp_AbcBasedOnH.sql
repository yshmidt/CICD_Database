-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/06/2009
-- Description:	Populate TempAbc Table based on On Hand qty calculation
-- Called from sp_CalcAbcCode
	-- 08/24/15 ys added truncate
	-- 09/16/15 VL Change the RankPct to be ROUND(2), it was ROUND(0)
	-- 09/17/15 VL Found even with ROUND(2), if the total value of all parts are relly big, the part value/total part vale saved in RankPct might become 0.00 
	--				Will need to increase Tempabc.RankPct to ROUND(5) to have more acurate result
-- =============================================
CREATE PROCEDURE [dbo].[sp_AbcBasedOnH]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lNotInStore as bit;
	SELECT @lNotInStore=AbcSetup.NotInStore FROM AbcSetup;
	
	BEGIN TRY;
		BEGIN TRAN;
		-- use CTE name ZExtCost
		--08/24/15 ys added truncate
		truncate table TempAbc;
		WITH ZExtCost AS
			(SELECT Part_sourc,Inventor.Uniq_key, ROUND(SUM(Qty_oh * StdCost),0) AS ExtCost 
				FROM Inventor, InvtMfgr 
				WHERE (Part_Sourc = 'BUY' 
                OR Part_Sourc = 'MAKE') 
				AND InvtMfgr.Uniq_Key = Inventor.Uniq_Key 
				AND Invtmfgr.Is_Deleted<>1 
				AND  Invtmfgr.InStore=CASE WHEN (@lNotInStore=1) THEN 0	ELSE (Invtmfgr.InStore) END
				GROUP BY Part_sourc,Inventor.Uniq_Key),
			InvtBuy AS
			(SELECT Part_sourc,SUM(ExtCost) AS nBuyTotal
				FROM ZExtCost
				WHERE Part_sourc='BUY' GROUP BY Part_sourc),
			InvtMake AS
			(SELECT Part_sourc,SUM(ExtCost) AS nMakeTotal
				FROM ZExtCost
				WHERE Part_sourc='MAKE' GROUP BY Part_sourc)
			INSERT INTO TEMPABC (Uniq_Key, Part_Sourc, ExtCost, PurLtDays, ProdLtDays ,RankPct,Abc, Reason) 
			SELECT Inventor.Uniq_key,Inventor.Part_Sourc,ZExtCost.ExtCost, 
				CASE WHEN (Pur_Lunit = 'MO') THEN Pur_Ltime * 20
					WHEN (Pur_Lunit = 'WK') THEN Pur_Ltime * 5
					WHEN (Pur_Lunit = 'DY') THEN Pur_Ltime 
					ELSE CAST(0 as numeric(4)) END AS PurLtDays,
				CAST(0 as numeric(4,0)) as ProdLtDays,
				CASE WHEN (InvtBuy.nBuyTotal<>0) THEN ROUND((ZExtCost.ExtCost/InvtBuy.nBuyTotal)*100,5)
					ELSE CAST(0 as numeric(10,0)) END as RankPct,' ' as Abc, 'Inventory Value' AS Reason
				FROM Inventor JOIN ZExtCost ON Inventor.Uniq_key=ZExtCost.Uniq_key
					 JOIN InvtBuy ON Inventor.Part_sourc=InvtBuy.Part_sourc
			UNION 
			SELECT Inventor.Uniq_key,Inventor.Part_Sourc, ZExtCost.ExtCost,
				CAST(0 as numeric(4,0)) as PurLtDays, 
				CASE WHEN (Prod_Lunit = 'MO') THEN Prod_Ltime * 20
					WHEN (Prod_Lunit = 'WK') THEN Prod_Ltime * 5
					WHEN (Prod_Lunit = 'DY') THEN Prod_Ltime 
					ELSE CAST(0 as numeric(4)) END AS ProdLtDays,
				CASE WHEN (InvtMake.nMakeTotal<>0) THEN ROUND((ZExtCost.ExtCost/InvtMake.nMakeTotal)*100,5)
					ELSE CAST(0 as numeric(10,0)) END as RankPct,' ' as Abc, 'Inventory Value' AS Reason
			FROM Inventor JOIN ZExtCost ON Inventor.Uniq_key=ZExtCost.Uniq_key
					JOIN InvtMake ON Inventor.Part_sourc=InvtMake.Part_sourc  
		COMMIT TRAN	
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
	END CATCH 
END