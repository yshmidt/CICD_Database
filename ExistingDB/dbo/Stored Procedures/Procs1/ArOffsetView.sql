CREATE PROCEDURE [dbo].[ArOffsetView]
        -- Add the parameters for the stored procedure here
        @pcUNIQ_AROFF as char(10) = ' '
AS
BEGIN
        -- SET NOCOUNT ON added to prevent extra result sets from
        -- interfering with SELECT statements.
        SET NOCOUNT ON;
    -- Insert statements for procedure here
        SELECT AROFFSET.*
                from ArOffset
                where AROFFSET.UNIQ_AROFF = @pcUniq_aroff

END
