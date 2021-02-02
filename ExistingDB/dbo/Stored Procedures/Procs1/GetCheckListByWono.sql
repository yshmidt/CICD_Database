-- =============================================
-- Author:	Sachin B
-- Create date: 05/13/2016
-- Description:	this procedure will be called from the SF module and Pull check list for the work order
-- Sachin B Remove temp table and get check list saved information and add @deptId parameter
-- GetCheckListByWono '0000000427'
-- =============================================
CREATE PROC [dbo].[GetCheckListByWono] 
@wono AS CHAR(10) = '',
@deptId AS CHAR(10) = ''
AS
SET NOCOUNT ON; 

SELECT WONO,SHOPFL_CHK as CheckListName,CHKFLAG,CHKINIT,CHKDATE,JBSHPCHKUK  
FROM JbshpChk WHERE Wono = @Wono and isMnxCheck =1