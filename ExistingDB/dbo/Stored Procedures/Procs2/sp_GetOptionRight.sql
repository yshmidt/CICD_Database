-- =============================================
-- Author:		Vicky Lu
-- Create date: 12/11/2009
-- Description:	This procedure will get the right of specific module for the user
-- Return '1' means user has right, return '0' means user has no right
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetOptionRight] @cUserID AS char(8) = '',@cSecOptionField AS char(15) = '',@cScreenName AS char(8) = '',@lRight bit OUTPUT
AS
SELECT @lRight = CAST(CASE WHEN UserOption.UserOptionUk IS NULL THEN 0 ELSE 1 END as bit)
	FROM SecOption LEFT OUTER JOIN UserOption
 ON SecOption.SecOptionUK =  UserOption.SecOptionUK 
   AND UserOption.UserId = @cUserID
	WHERE SecOption.SecOptionField = @cSecOptionField
	AND SecOption.ScreenName = @cScreenName
IF @@ROWCOUNT = 0
	SELECT @lRight = 0
