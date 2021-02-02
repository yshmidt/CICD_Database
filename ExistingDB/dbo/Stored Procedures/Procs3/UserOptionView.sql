
CREATE PROC [dbo].[UserOptionView] @pSecur_UserID AS CHAR(8) = ''
 AS
	SELECT SecOptionField, SecOptionDesc, ScreenName, ISNULL(UserOption.UserOptionUK,SPACE(10)) UserOptionUK, 
		CAST(CASE WHEN UserOption.UserOptionUk IS NULL THEN 0 ELSE 1 END as bit) AS lChk,
		SecOption.SecOptionUk,ISNULL(Useroption.userid,SPACE(8)) AS userid 
	 FROM SecOption LEFT OUTER JOIN UserOption
	 ON SecOption.SecOptionUK =  UserOption.SecOptionUK 
	   AND UserOption.UserId = @pSecur_UserID



