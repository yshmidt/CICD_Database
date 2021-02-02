-- =============================================        
-- Author:Sachin B        
-- Create date: 11/19/2018        
-- Description: this procedure will be called from the EWI Module for getting Reports Data by title    
-- GetReportsInfoByTitle 'Bill of Material by Part Numbers'  
-- GetReportsInfoByTitle 'Job Traveler'  
-- =============================================        
        
CREATE PROCEDURE GetReportsInfoByTitle         
@rptTitle NVARCHAR(1000) = ''              
        
AS        
SET NOCOUNT ON;         
  
SELECT * FROM MnxReports WHERE rptTitle = @rptTitle