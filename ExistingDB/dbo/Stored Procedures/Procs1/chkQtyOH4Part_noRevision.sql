-- =============================================
-- Author:		Vicky Lu	
-- Create date: <10/12/12>
-- Description:	<Get Invtmfgr records that Qty_oh>0 or Reserved > 0 with passed in table variables (Part_no, Revision)>
-- =============================================
CREATE PROCEDURE [dbo].[chkQtyOH4Part_noRevision] 
	-- Add the parameters for the stored procedure here
	@ltPart_noRevision AS tPart_noRevision READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

WITH ZPart AS
(
	SELECT Inventor.Part_no, Inventor.Revision, Uniq_key
		FROM Inventor, @ltPart_noRevision T2
			WHERE Inventor.Part_no = T2.Part_no 
			AND Inventor.Revision = T2.Revision 
)
SELECT ZPart.*, Qty_OH, Reserved
	FROM ZPart, Invtmfgr
	WHERE ZPart.Uniq_key = Invtmfgr.Uniq_key
	AND (Qty_OH <> 0 
	OR Reserved <> 0) 
END