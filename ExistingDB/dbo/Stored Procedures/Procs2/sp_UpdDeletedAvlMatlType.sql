-- =============================================
-- Author:		Vicky Lu
-- Create date: 09/02/2009
-- Description:	This procedure will update InvtMfhd.MatlType to 'Unk' for deleted matltype in system setup
-- Modified:	10/10/14 YS replaced invtmfhd table with 2 new tables 
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdDeletedAvlMatlType] @cMatlType AS char(10) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
--10/10/14 YS replaced invtmfhd table with 2 new tables 
--UPDATE InvtMfhd SET MatlType = 'Unk' WHERE MatlType = @cMatlType
UPDATE MfgrMaster SET MatlType = 'Unk' WHERE MatlType = @cMatlType
END