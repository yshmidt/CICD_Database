-- =============================================
-- Author:		Satish Bhosle
-- Create date: 7/01/2016
-- Description:	Add uniq section name in to mnxUdfSections table
-- Modification
   --Nitesh B 10/24/2018 : Defined columns in Insert query
-- =============================================
CREATE PROCEDURE AddUdfSectionAndMainTable 
	-- Add the parameters for the stored procedure here
	@section varchar(200),
	@mainTable varchar(200),
	@role varchar(200)
AS BEGIN
	  IF EXISTS(SELECT section FROM MnxUdfSections WHERE section=@section)
		BEGIN
			SELECT '403' as msgCode,'Section Name Already Exists In The Table' as msg
		END
	 ELSE
	    BEGIN
		--Nitesh B 10/24/2018 : Defined columns in Insert query
			INSERT INTO MnxUdfSections (section,mainTable,role) VALUES(@section,@mainTable,@role)
		END
END