-- =============================================
-- Author:		David Sharp
-- Create date: 4/16/2014
-- Description:	get BOM Import records
-- Modification:
-- 08/17/20 VL added customer filter
-- =============================================
CREATE PROCEDURE [dbo].[rptImportBomRecordsGet] 
	-- Add the parameters for the stored procedure here
	@userId uniqueidentifier = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- 08/17/20 VL added customer filter
	DECLARE  @tCustomer as tCustomer    
	INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;  

    -- Insert statements for procedure here
	SELECT importId,COALESCE(custname,'')custname,assyNum,assyRev,assyDesc,startDate,startedBy,ih.[status],completeDate,isValidated 
		FROM importBOMHeader ih LEFT OUTER JOIN customer c ON ih.custno=c.custno
		-- 08/17/20 VL added customer filter
		WHERE EXISTS (SELECT 1 FROM @tCustomer T WHERE T.Custno = c.Custno)
END