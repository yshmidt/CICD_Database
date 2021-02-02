-- =============================================
-- Author:		Bill Blake
-- Create date: 07/27/2011
-- Description:	<Using in Checks module>
-- =============================================
CREATE PROCEDURE dbo.ApOffsetTest4VoidCk 
-- Add the parameters for the stored procedure here
@gcUniqApHead as char(10) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets

-- interfering with SELECT statements.
SET NOCOUNT ON;

-- Insert statements for procedure here
select *
from APOFFSET
where APOFFSET.UNIQAPHEAD = @gcUniqApHead

END