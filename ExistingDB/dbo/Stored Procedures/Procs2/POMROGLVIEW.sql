-- ============================================================================================================  
-- Date   : 12/11/2019  
-- Author  : Mahesh B	
-- Description : Used for Get the GL Numbers
-- ============================================================================================================  
CREATE proc [dbo].[POMROGLVIEW]   
AS  
SELECT  Invtgls.gl_nbr,TRIM(Invtgls.descript) AS descript, Gl_nbrs.gl_descr,  
  Invtgls.uniqfield, Invtgls.rec_type  
 FROM   
     invtgls   
    INNER JOIN gl_nbrs   
   ON  Invtgls.gl_nbr = Gl_nbrs.gl_nbr  
 WHERE  Invtgls.rec_type = 'M'  
 ORDER BY Invtgls.gl_nbr