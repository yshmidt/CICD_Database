﻿CREATE PROCEDURE [dbo].[CmMainViewByCmNo]

           -- Add the parameters for the stored procedure here

           @gcCmemono as char(10) = ' '

AS

BEGIN

           -- SET NOCOUNT ON added to prevent extra result sets from

           -- interfering with SELECT statements.

           SET NOCOUNT ON;



   -- Insert statements for procedure here

           SELECT *

                       from CMMAIN

                       where Cmemono = @gcCmemono

END