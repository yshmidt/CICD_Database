-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/24/2011
-- Description:	Get Ar Write OFF information four release
-- 06/22/15 YS use  [dbo].[AllFYPeriods]
-- 09/24/15 VL added AtdUniq_key for FC used in GetAllGlReleased
-- 10/14/15 VL Added Currency field
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 12/14/16 VL: added functional and presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[GetArWO4Release] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 06/22/15 YS use [dbo].[AllFYPeriods]
	--declare @T TABLE (FiscalYr char(4),fk_fy_uniq char(10),Period Numeric(2,0),StartDate smalldatetime,EndDate smallDateTime,
	--	fyDtlUniq uniqueidentifier)
	
	declare @t as [dbo].[AllFYPeriods]
    insert into @T EXEC GlFyrstartEndView
-- 10/13/15 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()


IF @lFCInstalled = 0
	BEGIN    
	
    ;WITH D as
    (
    SELECT WoDate as Trans_Dt, ArWoUnique,CAST(0.00 as numeric(14,2)) as Debit,
		CAST('Invoice Number: '+acctsrec.INVNO as varchar(50))as DisplayValue,
		Wo_Amt as Credit,CAST(' ' as CHAR(8)) as Saveinit,
		CAST('ARWO' as varchar(50)) as TransactionType,    -- assign the same value as in glpostdef.PostType
		CAST('AR_WO' as varchar(25)) as SourceTable,
		'ArWoUnique' as cIdentifier,
		ArWoUnique as cDrill,
		CAST('ACCTSREC' as varchar(25)) as SourceSubTable,
		'UNIQUEAR' as cSubIdentifier,
		AR_WO.Uniquear as cSubDrill,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
		ArSetup.Ar_Gl_No,ArSetup.Al_Gl_No
		FROM Ar_Wo CROSS JOIN ARSETUP
		OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(AR_WO.WoDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN AcctsRec on Ar_wo.Uniquear=AcctsRec.UniqueAr
		WHERE Ar_WO.is_Rel_Gl =0 ),
		FinalArWo as
		(
		SELECT cast(0 as bit) as lSelect,Trans_dt,Debit,Credit,Saveinit,TransactionType,DisplayValue,
		SourceTable ,cIdentifier ,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill,
		FY,Period,fk_fyDtlUniq,
			Ar_Gl_No as GL_NBR,gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key  
		FROM D INNER JOIN GL_NBRS on D.Ar_GL_NO = Gl_nbrs.GL_NBR 
		UNION ALL
		SELECT cast(0 as bit) as lSelect,Trans_dt,Credit As Debit,Debit as Credit,Saveinit,TransactionType ,DisplayValue,
		SourceTable ,cIdentifier ,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill,
		FY,Period,fk_fyDtlUniq,
			Al_Gl_No as GL_NBR ,gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key 
		FROM D INNER JOIN GL_NBRS on D.AL_GL_NO = Gl_nbrs.GL_NBR )
		SELECT FinalArWo.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalArWo ORDER BY cDrill
	END
ELSE
	BEGIN	
    ;WITH D as
    (
    SELECT WoDate as Trans_Dt, ArWoUnique,CAST(0.00 as numeric(14,2)) as Debit,
		CAST('Invoice Number: '+acctsrec.INVNO as varchar(50))as DisplayValue,
		Wo_Amt as Credit,CAST(' ' as CHAR(8)) as Saveinit,
		CAST('ARWO' as varchar(50)) as TransactionType,    -- assign the same value as in glpostdef.PostType
		CAST('AR_WO' as varchar(25)) as SourceTable,
		'ArWoUnique' as cIdentifier,
		ArWoUnique as cDrill,
		CAST('ACCTSREC' as varchar(25)) as SourceSubTable,
		'UNIQUEAR' as cSubIdentifier,
		AR_WO.Uniquear as cSubDrill,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
		ArSetup.Ar_Gl_No,ArSetup.Al_Gl_No, 
		-- 12/14/16 VL added presentation currency fields
		CAST(0.00 as numeric(14,2)) as DebitPR,Wo_AmtPR as CreditPR,
		FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency, TF.Symbol AS Transaction_Currency,
		Ar_wo.FuncFcused_uniq, Ar_wo.PrFcused_uniq 
		FROM Ar_wo
			INNER JOIN Fcused TF ON Ar_wo.Fcused_uniq = TF.Fcused_uniq
	  		INNER JOIN Fcused PF ON Ar_wo.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON Ar_wo.FuncFcused_uniq = FF.Fcused_uniq
		CROSS JOIN ARSETUP
		OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(AR_WO.WoDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN AcctsRec on Ar_wo.Uniquear=AcctsRec.UniqueAr
		WHERE Ar_WO.is_Rel_Gl =0 ),
		FinalArWo as
		(
		-- 12/14/16 VL added presentation currency fields
		SELECT cast(0 as bit) as lSelect,Trans_dt,Debit,Credit,Saveinit,TransactionType,DisplayValue,
		SourceTable ,cIdentifier ,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill,
		FY,Period,fk_fyDtlUniq,
			Ar_Gl_No as GL_NBR,gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key, 
			DebitPR,CreditPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq 
		FROM D INNER JOIN GL_NBRS on D.Ar_GL_NO = Gl_nbrs.GL_NBR 
		UNION ALL
		SELECT cast(0 as bit) as lSelect,Trans_dt,Credit As Debit,Debit as Credit,Saveinit,TransactionType ,DisplayValue,
		SourceTable ,cIdentifier ,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill,
		FY,Period,fk_fyDtlUniq,
			Al_Gl_No as GL_NBR ,gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key, 
			CreditPR As DebitPR,DebitPR as CreditPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq 
		FROM D INNER JOIN GL_NBRS on D.AL_GL_NO = Gl_nbrs.GL_NBR )
		SELECT FinalArWo.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalArWo ORDER BY cDrill
	END
END