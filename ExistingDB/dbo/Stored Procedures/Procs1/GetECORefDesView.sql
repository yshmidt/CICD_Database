-- =============================================      
-- Author:  Sachin B    
-- Create date: 07/18/2018      
-- Description: GET ECO Refrence Desg data  
-- [GetECORefDesView] '_4D00U8WRY','_1EI0NK1ZM'  
-- =============================================      
    
CREATE PROCEDURE [dbo].[GetECORefDesView]    
     
@UniqEcNo CHAR(10)=' '  , @UniqEcDet CHAR(10)=' '       
      
AS      
BEGIN      
    
-- SET NOCOUNT ON added to prevent extra result sets from      
-- interfering with SELECT statements.      
SET NOCOUNT ON;      
      
SELECT UniqBomNo, Ref_des, Nbr, Uniqecdet,Uniqecrfno, Uniqecno,CAST(0 AS BIT) AS IsAdded      
 FROM Ecrefdes  
 WHERE Ecrefdes.UniqEcNo = @UniqEcNo AND UNIQECDET =@UniqEcDet  
 ORDER BY Nbr  
      
END    