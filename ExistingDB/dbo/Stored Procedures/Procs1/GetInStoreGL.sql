CREATE PROCEDURE [dbo].[GetInStoreGL] 
	@pcInStoreGL char(13) OUTPUT
AS	
	SELECT @pcInStoreGL= Inst_Gl_No from InvSetup
			







