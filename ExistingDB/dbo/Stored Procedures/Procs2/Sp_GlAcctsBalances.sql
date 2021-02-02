-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/21/2012
-- Description:	SP used to dipslay GL Balances for three last Fiscal years
-- used in frmglbalances form
-- 06/22/15 YS added new column sequenceNumber
-- =============================================
CREATE PROCEDURE [dbo].[Sp_GlAcctsBalances]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @Periods nvarchar(max)
	;WITH Periods as
	(
	select DISTINCT period from GLFYRSDETL 
	),
	SeqPeriods as
	(SELECT Period,row_number() over(order by period) as nSeq from Periods)

	SELECT @Periods =
		STUFF(
		(SELECT ',[Period_'+cast(Period as char(2))+']'
			FROM SeqPeriods ORDER BY nSeq
			for xml path('')
		),1,1,'')
	--select @Periods		
	DECLARE @SQL nvarchar(max)
	-- 06/22/15 YS added new column sequenceNumber
	SELECT @SQL = N'
	;with FyRn As
	(select FiscalYr,Fy_Uniq,lCurrent,sequenceNumber as nSeq
		FROM GLFISCALYRS 
	)
	,
	CurrentFY AS
	(SELECT * from FyRn A where lCurrent=1)
	SELECT * FROM (SELECT gl_acct.gl_nbr,glfiscalyrs.FiscalYr,End_bal,
					Gl_nbrs.GLTYPE,gl_nbrs.GL_CLASS,Gl_nbrs.GL_DESCR ,gl_nbrs.Status,
					gltypes.GLTYPEDESC ,''Period_''+convert(char(2),glFyrsDetl.Period) as Period
				from gl_acct INNER JOIN glFyrsDetl ON gl_acct.fk_fydtluniq=glFyrsDetl.FyDtlUniq 
				INNER JOIN glFiscalyrs ON  glFyrsDetl.fk_fy_uniq=glFiscalyrs.Fy_uniq
				INNER JOIN GL_NBRS ON Gl_acct.gl_nbr=Gl_nbrs.gl_nbr
				INNER JOIN GLTYPES ON GL_NBRS.GLTYPE =GLTYPEs.GLTYPE 
				WHERE Gl_nbrs.Gl_class=''Posting'' 
				AND glFiscalyrs.FY_UNIQ IN 
					(select FyRn.Fy_uniq  FROM FyRn,CurrentFY WHERE FyRn.nSeq>=CurrentFY.nSeq-2 and FyRn.nSeq<=CurrentFY.nSeq) 
				) tData 
				PIVOT (SUM(End_bal) FOR Period IN ('+@Periods+')) tPivot ORDER BY gl_nbr,FiscalYr' 


	--SELECT @SQL = N'
	--;with FyRn As
	--(select FiscalYr,Fy_Uniq,lCurrent,ROW_NUMBER() OVER(ORDER BY FiscalYr) as nSeq
	--	FROM GLFISCALYRS 
	--)
	--,
	--CurrentFY AS
	--(SELECT * from FyRn A where lCurrent=1)
	--SELECT * FROM (SELECT gl_acct.gl_nbr,glfiscalyrs.FiscalYr,End_bal,
	--				Gl_nbrs.GLTYPE,gl_nbrs.GL_CLASS,Gl_nbrs.GL_DESCR ,gl_nbrs.Status,
	--				gltypes.GLTYPEDESC ,''Period_''+convert(char(2),glFyrsDetl.Period) as Period
	--			from gl_acct INNER JOIN glFyrsDetl ON gl_acct.fk_fydtluniq=glFyrsDetl.FyDtlUniq 
	--			INNER JOIN glFiscalyrs ON  glFyrsDetl.fk_fy_uniq=glFiscalyrs.Fy_uniq
	--			INNER JOIN GL_NBRS ON Gl_acct.gl_nbr=Gl_nbrs.gl_nbr
	--			INNER JOIN GLTYPES ON GL_NBRS.GLTYPE =GLTYPEs.GLTYPE 
	--			WHERE Gl_nbrs.Gl_class=''Posting'' 
	--			AND glFiscalyrs.FY_UNIQ IN 
	--				(select FyRn.Fy_uniq  FROM FyRn,CurrentFY WHERE FyRn.nSeq>=CurrentFY.nSeq-2 and FyRn.nSeq<=CurrentFY.nSeq) 
	--			) tData 
	--			PIVOT (SUM(End_bal) FOR Period IN ('+@Periods+')) tPivot ORDER BY gl_nbr,FiscalYr' 
					

	exec sp_executesql @SQL




END