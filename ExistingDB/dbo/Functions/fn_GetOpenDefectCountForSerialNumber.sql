
-- =============================================
-- Author:  	Aloha Dev 1
-- Create date: 05/15/2013
-- Description:	Get the number (count) of open defects for Serial Number
-- =============================================
CREATE FUNCTION [dbo].[fn_GetOpenDefectCountForSerialNumber]
(	
	@lcSerialUniq char(10) = ' '
)
RETURNS int
AS
BEGIN	
	
	DECLARE @lReturn int
	SELECT @lReturn= count(*)
		FROM Qadef
		WHERE SerialUniq = @lcSerialUniq
	RETURN isnull(@lReturn,0)
END