-- =============================================
-- Author:		David Sharp
-- Create date: 4/18/2012
-- Description:	get import list values
--- 08/01/17 YS moved part_class infor from support table to partClass (new Table)
-- =============================================
CREATE PROCEDURE [dbo].[importBOMFullListValuesGet] 
	@userId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- Get all customers and customer numbers (accessible for the user)
	EXEC aspmnxSP_GetCustomers4User @userId
	-- Get part sources
	SELECT text AS partSource FROM SUPPORT WHERE FIELDNAME = 'PART_SOURC '
	-- Get unit of measures
	SELECT text AS u_of_m FROM SUPPORT WHERE FIELDNAME = 'U_OF_MEAS '
	-- Get Part Class
	--- 08/01/17 YS moved part_class infor from support table to partClass (new Table)
	--SELECT text2 AS partClass FROM SUPPORT WHERE FIELDNAME = 'part_class'
	Select Part_class AS partClass from PartClass
	--David Sharp 5/14/2012
	--Moved to its own sp. importBOMListValuePartClassGet
	---- Get Part Types
	--SELECT part_type AS partType, part_class AS partClass FROM PARTTYPE
	-- Get Warehouse
	SELECT warehouse FROM WAREHOUS WHERE WHSTATUS = 'active'
	---- Get Departments
	--SELECT text AS dept FROM SUPPORT WHERE FIELDNAME = 'dept'
	-- Get MFGs
	SELECT TEXT2 AS mfg, text AS manufacturer FROM SUPPORT WHERE FIELDNAME = 'partmfgr'
	-- Get Work Centers
	SELECT DEPT_ID as workCenter, RTRIM(DEPT_ID) + ' - ' + RTRIM(DEPT_NAME) AS workCenter FROM DEPTS 
	--Get Material Types
	SELECT AVLMATLTYPE AS matlType FROM AVLMATLTP
END