
CREATE PROCEDURE [dbo].[CcontactView] 
		@lcType char(1)='', @lcCid AS char(10)= ''
AS
SELECT Ccontact.*
	FROM Ccontact 
	WHERE Type = @lcType
	AND Cid = @lcCid