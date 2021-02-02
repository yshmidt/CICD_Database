
-- =============================================
-- Author:		<Debbie> 
-- Create date: <07/28/2011>
-- Description:	<compiles the total Qty on hand for particular Part number>
-- Reports:     <used on invtrpt4.rpt>
-- Modified:  01/15/2014 DRP:  added the @userid parameter for WebManex
-- =============================================

CREATE PROCEDURE [dbo].[rptInvtPartQtyOHView]
      -- Add the parameters for the stored procedure here
      --@lcUniq_key as char(10) = ' '
      	@userId uniqueidentifier=null
AS
BEGIN

select	part_no, revision, inventor.UNIQ_KEY, MATLTYPE,INSTORE,SUM(qty_oh) as QtyOh

from	INVENTOR 
		left outer join INVTMFGR on INVENTOR.UNIQ_KEY = INVTMFGR.UNIQ_KEY

--WHERE	INVENTOR.UNIQ_KEY = @lcUniq_key

group by PART_NO,REVISION,inventor.UNIQ_KEY, MATLTYPE, INSTORE
END