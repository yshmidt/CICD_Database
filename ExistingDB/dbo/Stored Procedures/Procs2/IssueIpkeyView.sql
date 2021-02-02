-- =============================================
-- Author:		Vicky Lu
-- Create date: 03/18/20
-- Description:	Created a view to save IssueIpkey records, used in desktop RMArecv form
-- =============================================
CREATE PROCEDURE [dbo].IssueIpkeyView @Invtisu_no AS char(10) = ''

AS
SELECT *
	FROM IssueIpkey
	WHERE invtisu_no = @Invtisu_no