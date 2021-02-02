
CREATE proc [dbo].[SupplierActiveView] AS 
 SELECT Supname,Supid,UniqSupNo
			FROM Supinfo
		WHERE Status<>'INACTIVE'
		AND Status<>'DISQUALIFIED'
		ORDER BY Supname
		

