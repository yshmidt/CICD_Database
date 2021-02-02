CREATE PROCEDURE [dbo].[sp_Test] @importID uniqueidentifier
---@Wono char(10)
AS
BEGIN
DECLARE @tAvlAll tImportBomAvl 
-- [ImportBomGetAvlToComplete] contains INSERT INTO ... EXEC <SP>
-- this insert will produce an error 
--Msg 8164, Level 16, State 1, Procedure ImportBomGetAvlToComplete, Line 51
--An INSERT EXEC statement cannot be nested.
INSERT INTO @tAvlAll EXEC [ImportBomGetAvlToComplete] @importID 


--DECLARE @WO TABLE (Wono char(10), BldQty numeric(7,0))

--INSERT @WO EXEC [sp_test2] @Wono

-- Try function already, can not use dynamic SQL in funtion
--SELECT Wono FROM dbo.fn_Test2() 

--SELECT * FROM @Wo

END