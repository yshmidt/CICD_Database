CREATE PROC [dbo].[ProdSchdView] @lcWono AS char(10) = ''
AS
--07/23/13 YS added new field to save user who schedule the job
SELECT Prod_dts.wono, Prod_dts.start_dts, Prod_dts.compl_dts, Prod_dts.qty, Prod_dts.slackpri, 
	Prod_dts.processtm, Prod_dts.daymin, Prod_dts.prodschunq, Woentry.uniq_key, Woentry.openclos,
	Woentry.due_date, Woentry.bldqty, Woentry.complete, Woentry.balance, Woentry.wonote, Woentry.custno, 
	Woentry.sono,prod_dts.AutoScheduled,prod_dts.fk_aspnetUsers
	FROM Prod_dts, Woentry
	WHERE Woentry.wono = Prod_dts.wono
	AND Woentry.openclos NOT IN ('Closed','Cancel','Closeshrt')
	AND  Prod_dts.wono = @lcWono
	ORDER BY Prod_dts.slackpri, Prod_dts.compl_dts, Prod_dts.wono