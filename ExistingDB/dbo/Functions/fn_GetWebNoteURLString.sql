-- =============================================
-- Author:		Vicky
-- Create date: 05/23/2014
-- Description:	Function to return the string to access wbNote button with user's session id
-- Modification:
-- 06/29/15 VL added @sId into the @lcURLString string
-- =============================================
CREATE FUNCTION [dbo].[fn_GetWebNoteURLString] 
(
	-- Add the parameters for the function here
	@lcRecordType varchar(50), @lcRecordId varchar(100), @sID char(36), @lcTitle varchar(100)
)
RETURNS varchar(max)
AS
BEGIN

-- example how it looks like
--{root}/Note/GetNotes?recordId={recordId}&recordType={record type}&sortOrder=1&isForFullView=true&displayTitle=[Title]&isDeskTop=true
--http://www.manex.com/test/Note/GetNotes?recordId=_0TQ0MOGPO&recordType=BOM&sortOrder=1&isForFullView=true&displayTitle=BOM:%20910-1001&isDeskTop=true

-- Declare the return variable here
DECLARE @lcURLString varchar(500)='', @lcCustomRootURL varchar(max)='';
SELECT @sID = CASE WHEN @sID='' THEN null ELSE @sID END

SELECT @lcCustomRootURL = LTRIM(RTRIM(CustomRootURL))
	FROM GENERALSETUP

SELECT @lcURLString = CASE WHEN (@lcCustomRootURL IS NULL OR @lcCustomRootURL ='' OR @sID IS NULL)
							THEN NULL
						ELSE
							--@lcCustomRootURL+'Note/GetNotes?recordId='+LTRIM(RTRIM(@lcRecordId))+'&recordType='+LTRIM(RTRIM(@lcRecordType))+'&sortOrder=1&isForFullView=true&displayTitle='+LTRIM(RTRIM(@lcTitle))+'&isDeskTop=true'
							@lcCustomRootURL+'Note/GetNotes?recordId='+LTRIM(RTRIM(@lcRecordId))+'&recordType='+LTRIM(RTRIM(@lcRecordType))+'&sortOrder=1&isForFullView=true&displayTitle='+LTRIM(RTRIM(@lcTitle))+'&isDeskTop=true&sId='+LTRIM(RTRIM(@sID))
						END

-- Return the result of the function
RETURN @lcURLString

END