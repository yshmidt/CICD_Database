﻿CREATE VIEW [dbo].[rptHolidayView]
AS
SELECT     TOP (100) PERCENT HOLIDAY, DATE, CAST(YEAR(DATE) AS char(4)) AS YEAR
FROM         dbo.HOLIDAYS
ORDER BY YEAR
