CREATE PROCEDURE [dbo].[ArWoView]
       -- Add the parameters for the stored procedure here
       @gcArWoUnique as char(10) = ' '
AS
BEGIN
       -- SET NOCOUNT ON added to prevent extra result sets from
       -- interfering with SELECT statements.
       SET NOCOUNT ON;

   -- Insert statements for procedure here
       SELECT AR_WO.*,ACCTSREC.INVNO,ACCTSREC.CUSTNO 
               from AR_WO,AcctsRec
               where ARWOUNIQUE = @gcArWoUnique and ACCTSREC.uniquear=AR_WO.UniqueAR

END