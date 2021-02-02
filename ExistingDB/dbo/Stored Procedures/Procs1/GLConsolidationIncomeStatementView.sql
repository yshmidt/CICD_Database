-- =============================================
-- Author:		<Nilesh Sa>
-- Create date: <27/12/2017>
-- Description:	View for the GL Consolidation For Income Statement
-- exec [dbo].[GLConsolidationIncomeStatementView] '16','10','10'
-- Nilesh Sa 1/5/2018 No need of parameter
-- Nilesh Sa 1/5/2018 Rename the parameter @StartSequenceNumber to @SequenceNumber
-- Nilesh Sa 1/8/2018 Avoid description here grouping issue occures
-- Nilesh Sa 1/8/2018 Created temp table and Added outer apply to display description
-- Nilesh Sa 1/8/2018 set Description as null for grouping issue occures
-- Nilesh Sa 2/1/2018 Change in implementation based on year,month and quarter added following new parameter
-- =============================================
CREATE PROCEDURE [dbo].[GLConsolidationIncomeStatementView]
	--DECLARE
	--@SequenceNumber INT = 0, -- Nilesh Sa 1/5/2018 Rename the parameter @StartSequenceNumber to @SequenceNumber
	--@StartPeriod NUMERIC(2,0) = 0,
	----@EndSequenceNumber INT = 0, -- Nilesh Sa 1/5/2018 No need of @EndSequenceNumber parameter
	--@EndPeriod NUMERIC(2,0) = 0 
	-- Nilesh Sa 2/1/2018 Change in implementation based on year,month and quarter added following new parameter
	 @viewBy VARCHAR(MAX) ='Monthly/Period',
	 @fiscalYear CHAR(4)='',
	 @period NUMERIC(2,0)=0,
	 @quarter NUMERIC(1,0)=0
AS
BEGIN
 SET NOCOUNT ON;
	DECLARE @GLInc1 AS TABLE (Tot_Start CHAR(13),Tot_End CHAR(13),Norm_Bal CHAR(2),GlType CHAR(3),
	gl_descr CHAR(30),gl_class CHAR(7),gl_nbr CHAR(13),glTypeDesc CHAR(20)
						,LONG_DESCR CHAR(52),FiscalYear CHAR(4),Period NUMERIC(2),
						Amt NUMERIC(14,2),EndDate SMALLDATETIME,prcnt NUMERIC(6,3))

    DECLARE @groupedAccountList AS TABLE(AccountNumber NVARCHAR(MAX),GL_DESCR CHAR(30),End_Bal NUMERIC(14,2))

	-- Nilesh Sa 2/1/2018 Change in implementation based on year,month and quarter added following new parameter
	DECLARE @SequenceNumber AS INT,@StartPeriod AS NUMERIC(2,0),@EndPeriod AS NUMERIC(2,0),@FyUniq AS CHAR(10)

	-- Get fiscal year record
	SELECT @FyUniq= FY_UNIQ, @SequenceNumber=sequenceNumber FROM GLFISCALYRS WHERE FISCALYR= @fiscalYear

	IF @viewBy = 'Yearly'
	  BEGIN
		SELECT TOP 1 @StartPeriod = PERIOD FROM GLFYRSDETL WHERE FK_FY_UNIQ= @FyUniq ORDER BY PERIOD -- SELECT First Period
		SELECT TOP 1 @EndPeriod = PERIOD FROM GLFYRSDETL WHERE FK_FY_UNIQ= @FyUniq ORDER BY PERIOD DESC -- SELECT Last Period
	  END
    ELSE IF @viewBy ='Quarterly'
	  BEGIN
	    SELECT TOP 1 @StartPeriod = PERIOD FROM GLFYRSDETL WHERE FK_FY_UNIQ= @FyUniq AND nQtr = @quarter ORDER BY PERIOD -- SELECT First Period
		SELECT TOP 1 @EndPeriod = PERIOD FROM GLFYRSDETL WHERE FK_FY_UNIQ= @FyUniq AND nQtr = @quarter ORDER BY PERIOD DESC -- SELECT Last Period
	  END
    ELSE
	  BEGIN
	    SELECT TOP 1 @EndPeriod =PERIOD, @StartPeriod = PERIOD FROM GLFYRSDETL WHERE FK_FY_UNIQ= @FyUniq AND PERIOD= @period -- SELECT First & last Period
	  END
	-- Nilesh Sa 2/1/2018 Change in implementation based on year,month and quarter added following new parameter

	--This section will gather the gl account detail and insert It into the table above
	INSERT	@GLInc1								
	SELECT	tot_start,tot_end,norm_bal,gltypes.GLTYPE,Gl_descr,Gl_nbrs.Gl_class,Gl_nbrs.Gl_nbr,Gltypes.Gltypedesc,
	gl_nbrs.LONG_DESCR,null AS FiscalYear,null AS Period, CAST (0.00 AS NUMERIC(14,2)) AS Amt,null AS EndDate,0.00
	FROM Gl_nbrs 
	INNER JOIN GLTYPES ON GL_NBRS.GLTYPE = GLTYPEs.GLTYPE AND Gl_nbrs.stmt = 'INC' 
	INNER JOIN gl_acct ON Gl_acct.gl_nbr = Gl_nbrs.gl_nbr
	INNER JOIN glFyrsDetl ON gl_acct.fk_fydtluniq = glFyrsDetl.FyDtlUniq 
	INNER JOIN glFiscalyrs ON  glFyrsDetl.fk_fy_uniq = glFiscalyrs.Fy_uniq  AND sequenceNumber = @SequenceNumber -- Nilesh Sa 1/5/2018 Rename the parameter @StartSequenceNumber to @SequenceNumber
	WHERE 
	DBO.PADL(RTRIM(CAST(Period as CHAR(2))),2,'0')
	BETWEEN DBO.PADL(RTRIM(CAST(@StartPeriod AS CHAR(2))),2,'0')
	AND DBO.PADL(RTRIM(CAST(@EndPeriod AS CHAR(2))),2,'0')
 	ORDER BY gl_nbr
	
	--This section will sum the debit and credit together from the gltransaction information and then update It into the declared table above
	declare @AllTrans as table (FiscalYear char(4),Period numeric(2),gl_nbr char(13),gl_class char(7),Amt numeric(14,2),gl_descr char(30))
  
;With
ZAllTrans as
	(

	SELECT	GLTRANSHEADER.FY,cast (GLTRANSHEADER.PERIOD as CHAR(2)) as Period,GltransHeader.TransactionType,
			gltrans.GL_NBR,GL_NBRS.GL_CLASS,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT
			,case WHEN gltransheader.TransactionType = 'JE' THEN (SELECT rtrim(gljehdr.JETYPE) FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD )
			ELSE CAST('' as varchar(60)) end as JEtype  
	FROM	GLTRANSHEADER  
			INNER JOIN gltrans on gltransheader.GLTRANSUNIQUE = GlTrans.Fk_GLTRansUnique 
			INNER JOIN GlTransDetails on gltrans.GLUNIQ_KEY = GlTransDetails.fk_gluniq_key  
			INNER JOIN GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR   AND gl_nbrs.STMT = 'INC' AND GL_CLASS = 'Posting'
			INNER JOIN gl_acct ON Gl_acct.gl_nbr = Gl_nbrs.gl_nbr
			INNER JOIN glFyrsDetl ON gl_acct.fk_fydtluniq = glFyrsDetl.FyDtlUniq  AND glFyrsDetl.Period = GLTRANSHEADER.PERIOD  
			INNER JOIN glFiscalyrs ON  glFyrsDetl.fk_fy_uniq = glFiscalyrs.Fy_uniq AND glFiscalyrs.FISCALYR = GLTRANSHEADER.FY AND glFiscalyrs.sequenceNumber = @SequenceNumber -- Nilesh Sa 1/5/2018 Rename the parameter @StartSequenceNumber to @SequenceNumber
			WHERE   
			dbo.padl(RTRIM(CAST(glFyrsDetl.Period as CHAR(2))),2,'0')
			BETWEEN  DBO.PADL(RTRIM(CAST(@StartPeriod AS CHAR(2))),2,'0')
			AND DBO.PADL(RTRIM(CAST(@EndPeriod AS CHAR(2))),2,'0')
	) 
		INSERT	@AllTrans 
		SELECT	FY,PERIOD,GL_NBR,gl_Class,SUM(Debit-credit) as Amt,GL_DESCR 
		FROM	ZAllTrans 
		WHERE	JEtype <> 'CLOSE' 
		GROUP BY FY,PERIOD,GL_NBR,gl_Class,GL_DESCR 
		ORDER BY GL_NBR


	--This will update the above @GLInc1 table with the calculated totals
		update @GLinc1 set Amt = (isnull(a1.Amt,0.00)) from  @AllTrans as A1,@GLInc1 as B where A1.gl_nbr = B.gl_nbr 


	--This below section will calculate the Closing values
		;with
		ZGlClosingNbrs as
					(				
					select	GL_NBR,tot_start,Tot_end
					from	@GLInc1 as C 
					where	gl_class = 'Closing'
					)
		,
		ZIncClose as
					(
					select	ZGlClosingNbrs.gl_nbr,SUM(Amt) as TotAmt
					from	@GLInc1 as D,ZGlClosingNbrs
					where	D.gl_nbr between ZGlClosingNbrs.tot_start and ZGlClosingNbrs.tot_end
							and gl_class <> 'Title' 
							and gl_class <> 'Closing'
					GROUP BY ZGlClosingNbrs.gl_nbr		
					)	
				update	@GLInc1 set Amt = ISNULL(zincclose.TotAmt,0.00) 
				from	zglclosingnbrs 
				left outer join ZIncClose on ZGlClosingNbrs.gl_nbr = ZIncClose.gl_nbr 
				inner join @GLInc1 as E on ZGlClosingNbrs.gl_nbr = e.gl_nbr 

	--This below section will calculate the Total value 			
		;with
		ZIncTotNbrs as
					(				
					select	GL_NBR,tot_start,Tot_end
					from	@GLInc1 as F 
					where	gl_class = 'Total'
					)	
					,
		ZIncTotDr as
					(
					select	zIncTotNbrs.gl_nbr,sum(amt) as TotAmtDr
					from	@GLInc1 as G,ZIncTotNbrs
					where	G.gl_nbr between ZIncTotNbrs.tot_start and ZIncTotNbrs.tot_end
							and Norm_Bal = 'DR'
							and gl_class <> 'Total'
							and gl_class <> 'Closing'
					group by zinctotnbrs.gl_nbr
					)		
					,
		zIncTotCr as
					(
					select	zIncTotNbrs.gl_nbr,sum(amt) as TotAmtCr
					from	@GLInc1 as H, ZIncTotNbrs
					where	H.gl_nbr between ZIncTotNbrs.tot_start and ZIncTotNbrs.tot_end
							and Norm_Bal = 'CR'
							and gl_class <> 'Total'
							and gl_class <> 'Closing'
					group by zinctotnbrs.gl_nbr 
					)	

		update	@GLInc1 set Amt = (ISNULL(zinctotdr.TotAmtdr,0.00)) + (ISNULL(zinctotcr.totamtcr,0.00))  
		from	ZIncTotNbrs 
				left outer join ZIncTotDr on ZIncTotNbrs.gl_nbr = ZIncTotDr.gl_nbr
				left outer join zIncTotCr on ZIncTotNbrs.gl_nbr = zinctotcr.gl_nbr
				inner join @GLInc1 as I on ZIncTotNbrs.gl_nbr = I.gl_nbr 

	declare @totallevel table  (gl_nbr char(13),gl_descr char(30),gl_class char(7),GlType char(3),stmt char(3),Tot_Start char(13),Tot_End char(13),glevel int,gPath varchar(max),
	parentTotal char(13),Parenttot_start char(13),parenttotal_end char(13) );
						
	;with glrange
	as
	(select	gl_nbr,gl_descr,gl_class,gltype,stmt,tot_start,tot_end,cast(0 as int) as glevel ,cast(gl_nbrs.gl_nbr as varchar(max)) as gPath  
	 from	gl_nbrs 
	 where	gl_class='Total' AND Gl_nbrs.stmt = 'INC' 
			and status='Active' 
			and not exists (select 1 from gl_nbrs g2 where g2.gl_class='Total'  and g2.status='Active'
							and gl_nbrs.gl_nbr<>g2.GL_NBR and gl_nbrs.tot_start between g2.tot_start and g2.tot_end and gl_nbrs.tot_end between g2.tot_start and g2.tot_end)
	 UNION ALL
	 select	gl_nbrs.gl_nbr,gl_nbrs.gl_descr,gl_nbrs.gl_class,gl_nbrs.gltype,gl_nbrs.stmt,gl_nbrs.tot_start,gl_nbrs.tot_end
			,gr.glevel+1,CAST(RTRIM(LTRIM(gr.gPath))+'/'+gl_nbrs.GL_NBR as varchar(max)) as path 
	 from	gl_nbrs  
			inner join glrange gr on gl_nbrs.gl_nbr<>gr.GL_NBR and gl_nbrs.tot_start between gr.tot_start and gr.tot_end and gl_nbrs.tot_end between gr.tot_start and gr.tot_end
	 where	gl_nbrs.gl_class='Total' AND Gl_nbrs.stmt = 'INC' 
			and gl_nbrs.status='Active'
		)
	
	insert into @totallevel
	select	r.gl_nbr,r.gl_descr,r.gl_class,r.gltype,r.stmt,r.tot_start,r.tot_end,r.glevel,r.gPath,
			right(rtrim(gPath),13) as parentTotal,p.TOT_START as Parenttot_start,p.TOT_END as parenttotal_end 
	from	glrange R 
			inner join gl_nbrs as P on right(rtrim(gPath),13)=p.gl_nbr AND P.stmt = 'INC' 
	where	exists (select 1 from (select gltype,max(glevel) as mlevel from  glrange r2 group by r2.gltype) T where t.gltype=r.gltype and t.mlevel=r.glevel)

INSERT INTO @groupedAccountList
	SELECT AccountNumber,NUll AS GL_DESCR ,SUM(END_BAL) AS END_BAL   -- Nilesh Sa 1/8/2018 set Description as null for grouping issue occures
	FROM(
			SELECT DBO.PADL(RTRIM(CAST(I.gl_nbr AS CHAR(7))),7,'0') AS AccountNumber
				,CASE WHEN I.gl_class = 'Posting' THEN -Amt ELSE
					CASE WHEN  I.Norm_Bal = 'DR' and I.gl_class = 'Total  ' THEN -Amt ELSE 
						CASE WHEN I.Norm_Bal = 'CR' and I.gl_class ='Total' THEN abs(Amt) ELSE
							CASE WHEN I.Norm_Bal = 'DR' and I.gl_class  = 'Closing' THEN Amt ELSE
								CASE WHEN I.Norm_Bal = 'CR' and I.gl_class = 'Closing' THEN -Amt ELSE
									cast(0.00 as numeric(14,2)) END END END END END AS End_Bal
			from @GLInc1 I
				OUTER APPLY (SELECT	t.*,abs(i2.amt) AS totamt 
									 FROM	@totallevel t 
											INNER JOIN @GLInc1 I2 on t.parentTotal=i2.gl_nbr  
									 WHERE	i.gltype=t.GlType AND i.gl_nbr BETWEEN t.Parenttot_start AND t.parenttotal_end 
											AND i.gl_class<>'Total') L	
	) Accounts 
	-- OUTER APPLY(SELECT TOP 1 * FROM GL_NBRS g1 WHERE g1.GL_NBR = CONCAT(Accounts.AccountNumber,'-','00','-','00')) GL_NBRS_Desc 	-- Get the description of 00-00  accounts
	GROUP BY AccountNumber --,ISNULL(gldescript,GL_NBRS_Desc.GL_DESCR)  	-- Nilesh Sa 1/8/2018 Avoid description here grouping issue occures

	 -- Nilesh Sa 1/8/2018 Created temp table and Added outer apply to display description
	 UPDATE @groupedAccountList
	 SET  GL_DESCR = Descrption.GL_DESCR
	 FROM @groupedAccountList  
	 OUTER APPLY (SELECT Top 1 GL_DESCR FROM GL_NBRS  WHERE GL_NBR like '%'+ AccountNumber +'%' order by GL_NBR)  AS Descrption  
 
	 SELECT * FROM @groupedAccountList ORDER BY AccountNumber
END