﻿CREATE proc [dbo].[PartSourceView] as SELECT left(text,10) as Part_sourc, Number, UNIQFIELD FROM Support WHERE Fieldname = 'PART_SOURC' Order by Number