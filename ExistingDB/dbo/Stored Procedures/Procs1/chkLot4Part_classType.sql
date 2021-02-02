-- =============================================
-- Author:		Vicky Lu	
-- Create date: <10/15/12>
-- Description:	<Check if any lot code records from passed in record set>
-- =============================================
CREATE PROCEDURE [dbo].[chkLot4Part_classType] 
	-- Add the parameters for the stored procedure here
	@ltPart_noRevision AS tPart_noRevision READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;


SELECT Inventor.Part_no, Inventor.Revision
	FROM @ltPart_noRevision T2, PartType, Inventor
	WHERE T2.Part_no = Inventor.PART_NO
	AND T2.Revision = Inventor.REVISION
	AND Inventor.PART_CLASS = Parttype.PART_CLASS
	AND Inventor.PART_TYPE = PARTTYPE.Part_Type
	AND LOTDETAIL = 1
		
END