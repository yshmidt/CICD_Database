-- =============================================
-- Author:	Sachin B
-- Create date: 01/10/2016
-- Description:	this procedure will be called from the SF module and save check list
-- [SaveCheckList] '0000000516','STAG',1,1,1,1,'CA','2017-01-11 14:08:00'
-- =============================================
CREATE PROC [dbo].[SaveCheckList] 
@wono AS CHAR(10) = '',
@deptId AS CHAR(10) = '',
@number AS numeric(4,0) = '',
@toolsReleased bit,
@workInstruction bit,
@qualityInstruction bit,
@initials char(8),
@chkDate smalldatetime
AS

declare @deptKey char(10)
set @deptKey = (select DEPTKEY from DEPT_QTY where WONO =@wono and NUMBER =@number)

SET NOCOUNT ON; 
IF NOT EXISTS(select * from JBSHPCHK where wono =@wono and DEPTKEY = @deptKey and SHOPFL_CHK ='Tools/Fixture Details' and isMnxCheck = 1)
   BEGIN
   INSERT INTO JBSHPCHK(WONO,SHOPFL_CHK,CHKFLAG,CHKINIT,CHKDATE,isMnxCheck,chkUserId,DEPTKEY,JBSHPCHKUK)values(@wono,'Tools/Fixture Details',0,'',null,1,NULL,@deptKey,dbo.fn_GenerateUniqueNumber())
   END
IF NOT EXISTS(select * from JBSHPCHK where wono =@wono and DEPTKEY = @deptKey and SHOPFL_CHK ='Work Instruction' and isMnxCheck = 1)
   BEGIN
    INSERT INTO JBSHPCHK(WONO,SHOPFL_CHK,CHKFLAG,CHKINIT,CHKDATE,isMnxCheck,chkUserId,DEPTKEY,JBSHPCHKUK)values(@wono,'Work Instruction',0,'',null,1,NULL,@deptKey,dbo.fn_GenerateUniqueNumber())
   END
IF NOT EXISTS(select * from JBSHPCHK where wono =@wono and DEPTKEY = @deptKey and SHOPFL_CHK ='Quality Information for previous Work Order' and isMnxCheck = 1)
   BEGIN
    INSERT INTO JBSHPCHK(WONO,SHOPFL_CHK,CHKFLAG,CHKINIT,CHKDATE,isMnxCheck,chkUserId,DEPTKEY,JBSHPCHKUK)values(@wono,'Quality Information for previous Work Order',0,'',null,1,NULL,@deptKey,dbo.fn_GenerateUniqueNumber())
   END

IF(@toolsReleased =1)
	BEGIN
		UPDATE JBSHPCHK set CHKFLAG =1,CHKINIT =@initials,CHKDATE =@chkDate where wono =@wono and SHOPFL_CHK ='Tools/Fixture Details' and isMnxCheck = 1 and DEPTKEY = @deptKey
	END
ELSE
    BEGIN
	   UPDATE JBSHPCHK set CHKFLAG =0,CHKINIT ='',CHKDATE =null where wono =@wono and SHOPFL_CHK ='Tools/Fixture Details' and isMnxCheck = 1 and DEPTKEY = @deptKey
	END

if(@workInstruction =1)
	BEGIN
		update JBSHPCHK set CHKFLAG =1,CHKINIT =@initials,CHKDATE =@chkDate where wono =@wono and SHOPFL_CHK ='Work Instruction' and isMnxCheck = 1 and DEPTKEY = @deptKey
	END
ELSE
    BEGIN
	   UPDATE JBSHPCHK set CHKFLAG =0,CHKINIT ='',CHKDATE =null where wono =@wono and SHOPFL_CHK ='Work Instruction' and isMnxCheck = 1 and DEPTKEY = @deptKey
	END

if(@qualityInstruction =1)
	BEGIN
		update JBSHPCHK set CHKFLAG =1,CHKINIT =@initials,CHKDATE =@chkDate where wono =@wono and SHOPFL_CHK ='Quality Information for previous Work Order' and isMnxCheck = 1 and DEPTKEY = @deptKey
	END
ELSE
    BEGIN
	   UPDATE JBSHPCHK set CHKFLAG =0,CHKINIT ='',CHKDATE =null where wono =@wono and SHOPFL_CHK ='Quality Information for previous Work Order' and isMnxCheck = 1 and DEPTKEY = @deptKey
	END