-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[fn_GETINVGLNBR]
(
	-- Add the parameters for the function here
	@lw_key  char(10),@lcTransactionType char(1)='R',@lInstoreReturn bit=0
	--@lw_key - w_key link to the location for receiving parts if @lcTransactionType='R' or issue parts from if @lcTransactionType='I'
	-- @lcTransactionType =R/I/X  - receiving/issue/transfer
	-- @lInstoreReturn flag that issue of the parts from in-store location to the supplier, not to the production line. If =1 no GL transction should be recorded. 
)
RETURNS char(13)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar char(13)
	DECLARE @lIsInStore bit,@lGLInstalled bit,@lcInStoreGlNbr char(13)
		
	SELECT @lcInStoreGlNbr=ISNULL(Inst_Gl_No,SPACE(13)) from InvSetup ;
	SELECT @lGLInstalled=Installed from Items where ScreenName='GLREL   ' ;
	SELECT @lIsInStore=Installed from Items where ScreenName='INSTORE   ' ;
	-- right now we will use this procedure for the invt_rec. in-store has to be differently treeted if transferred from in-store to the regular location or issue.
	--- have to think about separate procedure or maybe some additional input parameters. 
	SELECT @ResultVar=
			CASE 
				WHEN @lGLInstalled=0 OR Inventor.Part_sourc='CONSG' THEN SPACE(13)
				WHEN @lIsInStore=1 AND Invtmfgr.InStore=1 and (@lcTransactionType='R' OR (@lcTransactionType='I' and @lInstoreReturn =1))  THEN SPACE(13)
				WHEN @lIsInStore=1  AND Invtmfgr.InStore=1 and @lcTransactionType='I' THEN @lcInStoreGlNbr
				ELSE Warehous.WH_GL_NBR 
			END 
		from warehous,invtmfgr,inventor where invtmfgr.w_key=@lw_key and warehous.uniqwh=invtmfgr.uniqwh and inventor.uniq_key=invtmfgr.uniq_key

	-- Return the result of the function
	RETURN @ResultVar

END