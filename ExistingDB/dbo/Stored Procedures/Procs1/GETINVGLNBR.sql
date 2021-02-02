


CREATE PROC [dbo].[GETINVGLNBR]
@lw_key  char(10),@lcTransactionType char(1)='R',@lInStoreReturn bit=0, @M_WH_GL_NBR char(13) OUTPUT
-- adding new parameter @lcTransactionType to indicate which transaction type. 'R'- for receiving, 'I' - for issue.
-- for transfer will see later when crossing that bridge
AS
	BEGIN
		DECLARE @lIsInStore bit,@lGLInstalled bit,@lcInStoreGlNbr char(13)
		
		SELECT @lcInStoreGlNbr=CASE WHEN Inst_Gl_No IS NULL THEN SPACE(13) ELSE Inst_Gl_No END from InvSetup
		SELECT @lGLInstalled=Installed from Items where ScreenName='GLREL   '
		SELECT @lIsInStore=Installed from Items where ScreenName='INSTORE   '
		-- right now we will use this procedure for the invt_rec. in-store has to be differently treeted if transferred from in-store to the regular location or issue.
		--- have to think about separate procedure or maybe some additional input parameters. 
		-- when transaction is from Invttrns and in-store is 1 it should be from location. will select instore gl #
		SELECT @M_WH_GL_NBR=
			CASE 
				WHEN @lGLInstalled=0 OR @lGLInstalled IS NULL THEN SPACE(13)
				
				WHEN @lIsInStore=1  AND Invtmfgr.InStore=1 and (@lcTransactionType='R' OR (@lcTransactionType='I' AND @lInStoreReturn=1))  THEN SPACE(13)

				WHEN @lIsInStore=1  AND Invtmfgr.InStore=1 and (@lcTransactionType='I' OR @lcTransactionType='T') THEN @lcInStoreGlNbr

				ELSE Warehous.WH_GL_NBR 
			END 
		from warehous,invtmfgr where invtmfgr.w_key=@lw_key and warehous.uniqwh=invtmfgr.uniqwh

	END
