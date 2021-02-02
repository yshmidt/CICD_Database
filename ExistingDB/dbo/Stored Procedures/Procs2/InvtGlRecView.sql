-- =========================================================================================================
-- Author:		
-- Create date: 
-- Description:	 Get Inventory Handling GL Defaults.
--Shivshsnkar P :02/08/17 Get GlType
-- =========================================================================================================
CREATE proc [dbo].[InvtGlRecView]
AS 
 SELECT Invtgls.uniqfield, Invtgls.descript, Invtgls.gl_nbr,
  			Invtgls.rec_type, Gl_nbrs.gl_descr ,Gl_nbrs.GlType
 		FROM invtgls INNER JOIN gl_nbrs 
   		ON  Invtgls.gl_nbr = Gl_nbrs.gl_nbr
 		WHERE  Invtgls.rec_type = 'R'
		ORDER BY Invtgls.gl_nbr