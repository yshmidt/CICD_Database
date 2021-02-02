-- =============================================
-- Author:		Vicky Lu
-- Create date: 03/18/20
-- Description:	Created a view to save IssueSerial records, used in desktop RMArecv form
-- =============================================
CREATE PROCEDURE [dbo].IssueSerialView @Invtisu_no AS char(10) = ''

AS
SELECT *
	FROM issueSerial
	WHERE invtisu_no = @Invtisu_no
	ORDER BY Serialno