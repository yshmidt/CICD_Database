-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/06/2009
-- Description:	Populate TempAbc Table based on EAU calculation
-- Called from sp_CalcAbcCode
-- =============================================
CREATE PROCEDURE [dbo].[sp_AbcBasedEAU] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    BEGIN TRY
		BEGIN TRAN
		
		delete from tempabc where 1=1;
		-- Find out ExtCost and Rank according to percent off the total cost in each category (Buy and make) 
		INSERT INTO TEMPABC (Uniq_Key, Part_Sourc, ExtCost, PurLtDays, ProdLtDays ,RankPct,Abc, Reason) 
			SELECT Inventor.Uniq_key,Inventor.Part_Sourc, ROUND(Inventor.eau*Inventor.StdCost,0) as ExtCost, 
			CASE WHEN (Pur_Lunit = 'MO') THEN Pur_Ltime * 20
			WHEN (Pur_Lunit = 'WK') THEN Pur_Ltime * 5
			WHEN (Pur_Lunit = 'DY') THEN Pur_Ltime 
			ELSE CAST(0 as numeric(4)) END AS PurLtDays,
			CAST(0 as numeric(4,0)) as ProdLtDays,
		CASE WHEN (InvtBuy.nBuyTotal<>0) THEN ROUND((ROUND(Inventor.EAU*Inventor.StdCost,0)/InvtBuy.nBuyTotal)*100,0)
			ELSE CAST(0 as numeric(10,0)) END as RankPct,' ' as Abc, 'EAU' AS Reason
		FROM Inventor JOIN 
			(SELECT B.Part_sourc,SUM(ROUND(b.EAU*b.StdCost,0)) as nBuyTotal FROM Inventor B where B.Part_sourc='BUY' GROUP BY b.PART_SOURC) as InvtBuy
			ON Inventor.Part_sourc=InvtBuy.Part_sourc
		UNION 
		SELECT Inventor.Uniq_key,Inventor.Part_Sourc, ROUND(Inventor.EAU*Inventor.StdCost,0) as ExtCost,CAST(0 as numeric(4,0)) as PurLtDays, 
			CASE WHEN (Prod_Lunit = 'MO') THEN Prod_Ltime * 20
			WHEN (Prod_Lunit = 'WK') THEN Prod_Ltime * 5
			WHEN (Prod_Lunit = 'DY') THEN Prod_Ltime 
			ELSE CAST(0 as numeric(4)) END AS ProdLtDays,
		CASE WHEN (InvtMake.nMakeTotal<>0) THEN ROUND((ROUND(Inventor.EAU*Inventor.StdCost,0)/InvtMake.nMakeTotal)*100,0)
			ELSE CAST(0 as numeric(10,0)) END as RankPct,' ' as Abc, 'EAU' AS Reason
		FROM Inventor JOIN 
			(SELECT M.Part_sourc,SUM(ROUND(M.EAU*M.StdCost,0)) as nMakeTotal FROM Inventor M where M.Part_sourc='MAKE' GROUP BY M.PART_SOURC) as InvtMake
			ON InvtMake.Part_sourc=Inventor.Part_sourc
	
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
	END CATCH
END