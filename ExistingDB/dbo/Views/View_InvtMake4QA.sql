﻿
CREATE VIEW [dbo].[View_InvtMake4QA]
AS
SELECT DISTINCT I.UNIQ_KEY, I.PART_NO + ' ' + I.REVISION AS [Part Number], I.PART_NO, I.REVISION, dbo.WOENTRY.CUSTNO
FROM         dbo.QAINSP INNER JOIN
                      dbo.WOENTRY ON dbo.QAINSP.WONO = dbo.WOENTRY.WONO INNER JOIN
                      dbo.INVENTOR AS I ON dbo.WOENTRY.UNIQ_KEY = I.UNIQ_KEY