﻿

CREATE PROC [dbo].[ShipViaView] AS SELECT LEFT(TEXT,15) AS ShipVia,left(text2,6) as stime FROM SUPPORT WHERE FIELDNAME = 'SHIPVIA' ORDER BY Number




