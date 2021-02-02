-- Author:  Vijay G                                                                           
-- Create date: 20/10/2018                                                                      
-- DescriptiON: Used to display open sales orders
-- Modified Vijay G: 24/02/2020 Added two different block of code one is for before completing ECO and another for display data after completed ECO
CREATE PROC [dbo].[OpenSalesOrders4Uniq_keyView1] @gUniq_key AS char(10) =' ', @gUniqEcNo AS char(10) = ' '      
AS  
BEGIN    
DECLARE @status VARCHAR(200)    
SELECT @status=ECSTATUS FROM ECMAIN WHERE UNIQECNO=@gUniqEcNo    
-- Modified Vijay G: 24/02/2019 Added two different block of code one is for before completing ECO and another for display data after completed ECO   
IF(@status<>'Completed')    
BEGIN    
SELECT sodet.Sono, sodet.Uniqueln, sodet.Line_no , sodet.Balance, Is_Rma as RMA,     
    CAST(CASE WHEN ECSO.CHANGE IS NULL THEN 0 ELSE 1 END AS BIT) AS Change, ECSO.UNIQECSONO      
 FROM  Somain so  
 Inner join Sodetail sodet on sodet.Sono = so.Sono   
 LEFT OUTER JOIN ECSO on so.SONO = ECSO.SONO AND ECSO.UNIQECNO = @gUniqEcNo   
 WHERE Uniq_key = @gUniq_key   
 AND Uniq_key <> ''  
 AND (Status <> 'Cancel'  
 AND Status <> 'Closed')  
 AND sodet.Balance > 0  
 ORDER BY sodet.Sono, Line_no
 END    
 IF(@status='Completed')    
 BEGIN    
 ;WITH ZAllOpenSO       
AS      
(      
 SELECT sodet.Sono, sodet.Uniqueln, sodet.Line_no , sodet.Balance, Is_Rma as RMA,     
    CAST(CASE WHEN ECSO.CHANGE IS NULL THEN 0 ELSE 1 END AS BIT) AS Change, ECSO.UNIQECSONO      
 FROM  Somain so      
 Inner join Sodetail sodet on sodet.Sono = so.Sono       
 LEFT OUTER JOIN ECSO on so.SONO = ECSO.SONO AND ECSO.UNIQECNO = @gUniqEcNo       
 WHERE Uniq_key = @gUniq_key       
 AND Uniq_key <> ''      
 AND (Status <> 'Cancel'      
 AND Status <> 'Closed')      
 AND sodet.Balance > 0      
     
    
 UNION    
 SELECT sodet.Sono, sodet.Uniqueln, sodet.Line_no , sodet.Balance, Is_Rma as RMA,     
    CAST(CASE WHEN ECSO.CHANGE IS NULL THEN 0 ELSE 1 END AS BIT) AS Change, ECSO.UNIQECSONO      
    FROM    
 Somain so      
 Inner join Sodetail sodet on sodet.Sono = so.Sono       
 Inner join ECSO on so.SONO = ECSO.SONO AND sodet.LINE_NO=ECSO.LINE_NO AND ECSO.UNIQECNO = @gUniqEcNo     
 )    
    
 SELECT * FROM ZAllOpenSO  ORDER BY Sono, Line_no    
 END    
    
 END