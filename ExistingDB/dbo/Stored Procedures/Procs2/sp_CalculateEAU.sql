-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/03/2009
-- Description:	This stored procedure is used to calculate Estimated Anual Usage 
-- and is called by the ABC code setup
-- Modification
-- 01/22/16 VL found in the last update, should not update EAU = 0 for those parts having issue records between @ldStartDate and @ldHorzDt, should update EAU = 0 
-- for those inventory parts that are not in the SQL select
-- 01/26/16 VL found @lnEauFactor variable has numeric(3,0), so all digits after decimal point became 0, changed to numeric(3,3)
-- 05/02/17 VL changed @lnEauFactor numeric(3,3) to @lnEauFactor numeric(4,3) so if user set up 100 EAU, won't get numeric overflow error
-- 06/05/17 VL In old code, if no invt_isu records in last month, the code never update inventor.eau, changed back to work the old way (VFP version) and update EAU with prior EAU * @lnEauFactor
-- 06/06/17 VL Change the EAU, if negative, set to 0, request by Arctronics
-- =============================================
CREATE PROCEDURE [dbo].[sp_CalculateEAU] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRAN
	-- 05/02/17 VL changed @lnEauFactor numeric(3,3) to @lnEauFactor numeric(4,3) so if user set up 100 EAU, won't get numeric overflow error
	DECLARE @ldStartDate smalldatetime,@ldHorzDt smalldatetime,@lnEauFactor numeric(4,3);
	SET @ldStartDate=GETDATE()-31;
	SELECT @lnEauFactor=EauFactor/100,@ldHorzDt=GETDATE()-EauExclDay FROM ABCSetup;

	--- I am using CTE (common table expression was introduced in SQL 2005)
	-- find all records that were issued in the past 31 day

	WITH InvtIssuSumm AS
	(
	SELECT Inventor.Uniq_Key, SUM(QtyIsu) AS TotQtyIsu 
		FROM Inventor, Invt_Isu 
		WHERE Inventor.Uniq_Key = Invt_Isu.Uniq_Key 
		AND (Inventor.Part_Sourc = 'BUY' OR Inventor.Part_Sourc = 'MAKE') 
		AND Invt_Isu.DATE >= @ldStartDate 
		GROUP BY Inventor.Uniq_Key
	)
	-- 06/05/17 VL found from very original code/spec from Jerry, will change how the EAU is calculated
	--*!*	IF lnEauFactor = 1.0
	--*!*			REPLACE ALL Eau WITH INT(ZEau1.TotQtyIsu * 12)  
	--*!*	ELSE
	--*!*			REPLACE ALL Eau WITH IIF(EOF('ZEau1'),INT(Eau * lnEauFactor),; 
	--*!*			MAX(0, INT(Eau * (1 - lnEauFactor)) + (ZEau1.TotQtyIsu * 12) *nEauFactor))
	--*!*	ENDIF
	-- 06/05/17 VL changed, becuse the next update won't update inventor.EAU if no issue records in last month (no record in InvtIssuSumm)
	--UPDATE Inventor SET Eau = CAST(Inventor.Eau*(1-@lnEauFactor)+(InvtIssuSumm.TotQtyIsu*12)*@lnEauFactor as Int) FROM InvtIssuSumm WHERE InvtIssuSumm.Uniq_key=Inventor.Uniq_key;
	UPDATE Inventor SET EAU = 
		CASE WHEN @lnEauFactor = 1 THEN CASE WHEN CAST(ISNULL(InvtIssuSumm.TotQtyIsu*12,0.00) AS Int) > 0 THEN CAST(ISNULL(InvtIssuSumm.TotQtyIsu*12,0.00) AS Int) ELSE 0 END ELSE
			CASE WHEN InvtIssuSumm.TotQtyIsu IS NULL THEN CASE WHEN CAST(EAU * @lnEauFactor AS Int) > 0 THEN CAST(EAU * @lnEauFactor AS Int) ELSE 0 END ELSE 
				CASE WHEN CAST(EAU * (1-@lnEauFactor)+(InvtIssuSumm.TotQtyIsu*12)*@lnEauFactor AS Int) > 0 THEN CAST(EAU * (1-@lnEauFactor)+(InvtIssuSumm.TotQtyIsu*12)*@lnEauFactor AS Int) ELSE 0 END END END
		FROM Inventor LEFT OUTER JOIN InvtIssuSumm
		ON Inventor.Uniq_key = InvtIssuSumm.Uniq_key


	-- 01/22/16 VL comment out code and should update inventor.EAU = 0 for those records that not in the SQL select
	-- find all records that had issue date between @ldStartDate and @ldHorzDt and replace EAU for those with 0
	--UPDATE inventor SET Eau = 0 FROM Invt_isu WHERE Invt_isu.uniq_key=Inventor.Uniq_key and (Inventor.Part_sourc='BUY' or Inventor.Part_sourc='MAKE') and 
	--	((Invt_isu.Date<@ldStartDate and Invt_isu.Date>=@ldHorzDt) OR Inventor.Eau<0);
	;WITh ZHaveIssueRec AS
		(SELECT Inventor.Uniq_key 
			FROM Inventor, Invt_isu
			WHERE Invt_isu.uniq_key=Inventor.Uniq_key
			AND (Inventor.Part_sourc='BUY' or Inventor.Part_sourc='MAKE')
			AND Invt_isu.Date>=@ldHorzDt)
	
	UPDATE Inventor SET Eau = 0 WHERE Uniq_key NOT IN (SELECT Uniq_key from ZHaveIssueRec) 
	-- 01/22/16 VL End}

	-- Update last date calculated EAU
	UPDATE AbcSetup SET LastEau=GETDATE();
	COMMIT TRAN
	
    
END