-- =============================================
-- Author:		Vicky Lu
-- Create date: 09/02/2009
-- Description:	This procedure will update Inventor.MatlType to 'Unk' for deleted matltype in system setup
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdDeletedInvMatlType] @cMatlType AS char(10) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

UPDATE Inventor SET MatlType = 'Unk' WHERE MatlType = @cMatlType
END