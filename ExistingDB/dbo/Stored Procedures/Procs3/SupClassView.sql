-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- Modified: 08/01/17 YS moved part class setup from "support" table to "partClass" table
-- =============================================
CREATE PROC [dbo].[SupClassView] (@lcUniqSupno char(10) ='')
AS
--08/01/17 YS moved part class setup from "support" table to "partClass" table
SELECT Unqsupclas, UniqSupno, Supclass.Part_class, partClass.ClassDescription
FROM Supclass INNER JOIN Part_class
ON  Supclass.Part_class = partClass.Part_class
AND UniqSupno = @lcUniqSupno
ORDER BY Part_class
