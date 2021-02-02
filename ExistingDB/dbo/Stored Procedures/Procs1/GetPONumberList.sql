-- =============================================
-- Author: Shivshankar Patil	
-- Create date: <05/09/2017>
-- Description: Get Po Number List 
-- Shivshankar P : 30/05/17 Display only LCANCEL =0 PO's
-- Shivshankar P : 16/08/17 Get based on Supplier and PO Number
-- Shivshankar P : 09/14/17 Display only PO status with 'CLOSED' and 'OPEN'
-- Shivshankar P : 09/27/17 Removed leading zeros 'fRemoveLeadingZeros' taking time with Big DataBase and filtered the condition
-- =============================================
CREATE  PROCEDURE dbo.[GetPONumberList]
@pageNumber int = 0,
@pageSize int=10,
@ponum varchar(15) =' ',
@uniqSup varchar(10)=' ',
@isInvt bit=0

AS 
	BEGIN
	  SET NOCOUNT ON;
	  IF(@isInvt=0)
	     BEGIN
			SELECT DISTINCT poMain.PONUM, poMain.PONum, --dbo.fRemoveLeadingZeros( poMain.PONUM) AS Value,   -- Shivshankar P : 09/27/17 Removed leading zeros 'fRemoveLeadingZeros' taking time with Big DataBase and filtered the condition
			        POUNIQUE AS Id,UNIQSUPNO AS Type,POSTATUS AS STATUS FROM POMAIN 
							JOIN POITEMS ON POMAIN.PONUM  = POITEMS.PONUM AND poItems.POITTYPE <> 'In Store' 
              AND (poMain.POSTATUS = 'CLOSED' OR poMain.POSTATUS = 'OPEN') -- Shivshankar P : 09/14/17 Display only PO status with 'CLOSED' and 'OPEN'
              AND  POITEMS.LCANCEL =0	-- Shivshankar P : 30/05/17 Display only LCANCEL =0 PO's
							WHERE  ((@ponum <> ' ' AND @uniqSup=' ' AND  POMAIN.PONUM  LIKE '%'+ @ponum + '%') OR 
							(@ponum = ' ' AND @uniqSup<>'' AND POMAIN.UNIQSUPNO =@uniqSup)
	                		OR (@ponum = '' AND @uniqSup='')  
							OR (@ponum <> ' '  AND @uniqSup <>' '  AND POMAIN.PONUM  LIKE '%'+ @ponum + '%' AND POMAIN.UNIQSUPNO =@uniqSup))   -- Shivshankar P : 16/08/17 Get based on Supplier and PO Number

			ORDER BY poMain.PONUM
					OFFSET @pageNumber ROWS
					FETCH NEXT @pageSize ROWS ONLY;
			
	     END
	
END