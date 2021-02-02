-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <2010/11/01>
-- Description:	<Return a cursor that has last PO information for supplier>
-- =============================================
CREATE FUNCTION [dbo].[fn_GetLastPO4Supplier] 
(	
	@lcUniqSupNo char(10)=' '
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT TOP 1 Ponum, PoDate, PoTotal
		FROM Pomain
		WHERE UniqSupno= @lcUniqSupNo 
		ORDER BY Podate DESC

);