-- =============================================

-- Author: Yelena Shmidt

-- Create date: 07/11/2013

-- Description: Procedure will return a list of work orders along with the deptkey or w_key if in FGI

-- 07/15/2013 YS added another parameter to @dept_id - use this parameter to find "my department" key and number
-- 08/14/13 YS fixed the issue when serial number is assigned to multiple jobs, only one job was showing
-- =============================================

CREATE PROCEDURE [dbo].[SpGetSerialNumberLocation]

-- Add the parameters for the stored procedure here

@Serialno char(30) = NULL,

@dept_id char(4)=NULL

AS

BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from

-- interfering with SELECT statements.

SET NOCOUNT ON;

-- Insert statements for procedure here

;WITH

Jobs AS

(

SELECT Serialno,SERIALUNIQ ,invtSer.WONO,ID_KEY,ID_VALUE,LOTCODE,EXPDATE,REFERENCE,

Dept_qty.Dept_id,Dept_qty.Deptkey,Dept_qty.Number

from INVTSER INNER JOIN DEPT_QTY ON INVTSER.WONO=Dept_qty.WONO

where SERIALNO=@serialno

and invtser.WONO<>''

and (ID_KEY='W_KEY' or ID_KEY='DEPTKEY')

AND dept_qty.DEPT_ID=CASE WHEN ID_KEY='W_KEY' THEN 'FGI' ELSE Dept_qty.DEPT_ID END

AND dept_qty.DEPTKEY=CASE WHEN ID_KEY='W_KEY' THEN Dept_qty.DEPTKEY ELSE Invtser.ID_VALUE END

),

--SELECT * from Jobs order by Wono,NUMBER

NextMyWc

as(
-- 08/14/13 YS if multiple jobs with the same serial number the top 1 will remove one of the jobs, need to filter the first record for each job in the CombSteps
--SELECT TOP 1 J.Wono,J.NUMBER as FromNumber,J.DEPTKEY as FromDeptKey,J.DEPT_ID as FromDept_id,
SELECT J.Wono,J.NUMBER as FromNumber,J.DEPTKEY as FromDeptKey,J.DEPT_ID as FromDept_id,
	D.Number as myNumber,D.Dept_id as MyDept,D.Deptkey as myDeptKey,
	ROW_NUMBER() OVER (partition by j.wono ORDER BY D.Number) as Dlist,'N' as Typeseq
	 from Jobs J LEFT OUTER join DEPT_QTY D on J.WONO=D.WONO AND D.DEPT_ID=@dept_id and D.NUMBER>=J.NUMBER 
	-- ORDER BY ROW_NUMBER() OVER (partition by j.wono ORDER BY D.Number)
)
,
PriorMyWc
as(
--SELECT TOP 1 J.Wono,J.NUMBER as FromNumber,J.DEPTKEY as FromDeptKey,J.DEPT_ID as FromDept_id,
SELECT J.Wono,J.NUMBER as FromNumber,J.DEPTKEY as FromDeptKey,J.DEPT_ID as FromDept_id,
	D.Number as myNumber,D.Dept_id as MyDept,D.Deptkey as myDeptKey,
	ROW_NUMBER() OVER (partition by j.wono ORDER BY D.Number) as Dlist,'P' as Typeseq
	 from Jobs J LEFT OUTER join DEPT_QTY D on J.WONO=D.WONO AND D.DEPT_ID=@dept_id and D.NUMBER<J.NUMBER 
	-- ORDER BY ROW_NUMBER() OVER (partition by j.wono ORDER BY D.Number) DESC
 )
,
CombSteps as
(
-- 08/14/13 YS now filter the first record for each job
SELECT N.Wono,N.FromNumber,N.FromDeptKey,N.FromDept_id,
	  CASE when N.MyNumber IS null THEN P.MyNumber ELSE N.MyNumber END as MyNumber,
	   CASE when N.MyDeptKey IS null THEN P.MyDeptKey ELSE N.MyDeptKey END as MyDeptKey,
	   CASE WHEN N.MyDept is null then p.MyDept else n.mydept end as MyDept
	   from NextMyWc N LEFT OUTER JOIN PriorMyWc P on N.Wono=p.wono and N.FromNumber=p.FromNumber and N.FromDeptKey=P.FromDeptKey 
	   WHERE n.Dlist =1 and isnull(p.dlist,1)=1
)
--Return to front
select * from CombSteps

END