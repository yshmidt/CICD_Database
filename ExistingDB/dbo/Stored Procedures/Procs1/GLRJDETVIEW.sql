-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <06/30/2011>
-- Description:	<General JE module>
-- Modification
-- 03/27/17 VL added functional currency and separate FC and non FC
-- 05/24/17 VL change the sequence of the fields debitFC and creditFC to be after debit and credit, so in the form, no need to add extra code to assign grid controlsource
-- =============================================
CREATE PROCEDURE [dbo].[GLRJDETVIEW]
	-- Add the parameters for the stored procedure here
	@pcGlRHdrKey as char(10)=' '  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
IF dbo.fn_IsFCInstalled()=0
	SELECT [GlRjDet].[gl_nbr]
		,Gl_nbrs.gl_descr
      ,[debit]
      ,[credit]
      ,[glrdetkey]
      ,[fkglrhdr]
  FROM [dbo].[GlRjDet]
  LEFT OUTER JOIN gl_nbrs 
   ON  [GlRjDet].gl_nbr = Gl_nbrs.gl_nbr
     WHERE  [fkglrhdr] = ( @pcGlRHdrKey )
ELSE
	SELECT [GlRjDet].[gl_nbr]
		,Gl_nbrs.gl_descr
      ,[debit]
      ,[credit]
      -- 03/27/17 VL added functional currency
	  ,debitFC
	  ,creditFC
	  ,debitPR
	  ,creditPR
	  ,[glrdetkey]
      ,[fkglrhdr]
  FROM [dbo].[GlRjDet] 
	LEFT OUTER JOIN gl_nbrs 
		ON  [GlRjDet].gl_nbr = Gl_nbrs.gl_nbr
     WHERE  [fkglrhdr] = ( @pcGlRHdrKey )
END