-- =========================================================================================================
-- Author:		Shivshankar P
-- Create date: 09/13/2017
-- Description:	 Get WMShelf and WMBin Data by UniqRack / UniqShelf
-- =========================================================================================================
CREATE PROCEDURE [dbo].[GetWMShelfBindDetail]
@uniqueId CHAR(10),  -- UniqRack / UniqShelf
@isShelf  bit =0

 AS 
  BEGIN
       SET NOCOUNT ON;
        IF(@isShelf=1)
		  BEGIN
				  SELECT * FROM dbo.WMShelf where UniqRack = @uniqueId
						   ORDER BY LEFT(Name,PATINDEX('%[0-9]%',Name)-1), -- alphabetical sort
									CONVERT(INT,SUBSTRING(name,PATINDEX('%[0-9]%',name),LEN(name)))
		  END

		ELSE
		    BEGIN
			      SELECT * FROM dbo.WMBin where UniqShelf = @uniqueId
						   ORDER BY LEFT(Name,PATINDEX('%[0-9]%',Name)-1), -- alphabetical sort
									CONVERT(INT,SUBSTRING(name,PATINDEX('%[0-9]%',name),LEN(name)))
			
			END
			     
  END