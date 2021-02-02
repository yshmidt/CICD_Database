-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/27/2012
-- Description:	get generated auto distribution JE that were not approved for a given period
-- =============================================
CREATE PROCEDURE dbo.GetUnApprovedAD
	-- Add the parameters for the stored procedure here
	@cFy char(4)=' ',@nPeriod int=0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- if parameters are not passed get the current period information
	SELECT @nPeriod = CASE WHEN @nPeriod=0 THEN Glsys.CUR_PERIOD ELSE @nPeriod  END ,
		   @cFy = CASE WHEN @cFy=' ' THEN Glsys.CUR_FY  ELSE @cFy END FROM GLSYS 
	SELECT * from GLJEHDRO WHERE GLJEHDRO.FY =@cFy and GLJEHDRO.PERIOD =@nPeriod AND JETYPE ='AUTO DISTR' AND STATUS='NOT APPROVED'
	   	   
END