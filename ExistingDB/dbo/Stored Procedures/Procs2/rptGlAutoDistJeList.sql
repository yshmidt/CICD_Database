-- =============================================
-- Author:		Debbie
-- Create date: 05/18/2012
-- Description:	Created for the Defined Journal Entry for Automatic Distribution Journal Entry
-- Reports Using Stored Procedure:  gladlist.rpt
-- =============================================
create PROCEDURE [dbo].[rptGlAutoDistJeList]
@userid uniqueidentifier = null
as
begin

select	gladhdr.*,gladdet.GL_NBR,debit,credit,gl_descr
from	GLADHDR,GLADDET,GL_NBRS
where	gladhdr.GLAHDRKEY=gladdet.FKGLAHDR
		and gl_nbrs.GL_NBR = gladdet.GL_NBR
		
end