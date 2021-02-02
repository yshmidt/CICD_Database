-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <2010/11/01>
-- Description:	<Return a cursor that has lot code setting for parameter uniq_key>
-- Modification:
-- 03/09/15 VL changed to use LEFT OUTER JOIN for parttype, otherwise if inventor.part_type is empty, it won't be selected
-- =============================================
CREATE FUNCTION [dbo].[fn_IsLotcodePart] 
(	
	@gUniq_key char(10)=' '
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	--SELECT LotDetail, FgiExpDays, AutoDt 
	--	FROM Parttype, Inventor 
	--	WHERE Parttype.Part_class = Inventor.Part_class 
	--	AND Parttype.Part_type = Inventor.Part_type 
	--	AND Inventor.Uniq_key = @gUniq_key
	SELECT ISNULL(LotDetail,0) AS LotDetail, ISNULL(FgiExpDays,0) AS FgiExpDays, ISNULL(AutoDt,0) AS AutoDt
		FROM Inventor LEFT OUTER JOIN Parttype
		ON Inventor.Part_class = Parttype.Part_class
		AND Inventor.Part_type = Parttype.Part_type
		WHERE Inventor.Uniq_key = @gUniq_key
);
