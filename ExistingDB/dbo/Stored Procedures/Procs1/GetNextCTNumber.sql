
CREATE PROCEDURE [dbo].[GetNextCTNumber] 
	@pcNextNumber char(10) OUTPUT
AS	
	SELECT @pcNextNumber = ISNULL(MAX(Ct_no),0)+1 FROM Currtrfr


	
		
	