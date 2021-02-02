CREATE PROC [dbo].[SodetailNoWKeyView] @lcUniq_key AS char(10) = ''
AS
SELECT DISTINCT SoDetail.Sono,SoDetail.Line_no,sodetail.balance,
			w_key,UniqueLn
			FROM  Sodetail
			WHERE SoDetail.Uniq_key=@lcUniq_key 
			AND Sodetail.Status<>'Closed'
			AND Status<>'Cancel'
			AND Balance>0 AND SoDetail.W_key=' '
			ORDER BY Sono,Line_No


