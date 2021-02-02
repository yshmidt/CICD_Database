-- =============================================
-- Author:		Vicky
-- Create date: 07/10/2013
-- Description:	Function to return the string to access UDF button with user's session id
-- =============================================
CREATE FUNCTION [dbo].[fn_GetUdfURLString] 
(
	-- Add the parameters for the function here
	@lcModule char(8), @lcKey varchar(20), @sID char(36), @lcTitle varchar(100)
)
RETURNS varchar(max)
AS
BEGIN

-- 08/05/13 VL change the URL string, David changed the way how the changes can be saved if user open UDF from desktop, need to add one more parameter title
-- original way example: http://www.manex.com/test/Udf/table/BOM_DET/id/_2VI0YHR4C?reqRole=BOM_Edit?sId=z5vurphgml2qbqlilwl5mjh0
-- new way example:http://www.manex.com/test/Udf/desktop?tableName=BOM_DET&id=_0TQ0N69OA&sid=lc4zrsh1k12v1sgrcvrjgsfs&title=Item%201

-- Declare the return variable here
DECLARE @lcURLString varchar(300)='', @lcCustomRootURL varchar(max)='';
SELECT @sID = CASE WHEN @sID='' THEN null ELSE @sID END

SELECT @lcCustomRootURL = LTRIM(RTRIM(CustomRootURL))
	FROM GENERALSETUP

SELECT @lcURLString = CASE WHEN (@lcCustomRootURL IS NULL OR @lcCustomRootURL ='' OR @sID IS NULL)
							THEN NULL
						ELSE
							-- 08/06/13 VL changed the string
							--@lcCustomRootURL+'Udf/table/'+LTRIM(RTRIM(@lcModule))+'/id/'+LTRIM(RTRIM(@lcKey))+'?sId='+LTRIM(RTRIM(@sID))						
							@lcCustomRootURL+'Udf/desktop?tableName='+LTRIM(RTRIM(@lcModule))+'&id='+LTRIM(RTRIM(@lcKey))+'&sId='+LTRIM(RTRIM(@sID))+'&title='+REPLACE(LTRIM(RTRIM(@lcTitle)),' ','%20')
						END

-- Return the result of the function
RETURN @lcURLString

END