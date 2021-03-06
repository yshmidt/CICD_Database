﻿
CREATE VIEW [dbo].[View_MrpBomDet]
AS
SELECT        dbo.BOM_DET.UNIQBOMNO, dbo.BOM_DET.ITEM_NO, dbo.BOM_DET.BOMPARENT, dbo.BOM_DET.UNIQ_KEY, dbo.BOM_DET.DEPT_ID, dbo.BOM_DET.QTY, dbo.BOM_DET.ITEM_NOTE, dbo.BOM_DET.OFFSET, 
                         dbo.BOM_DET.TERM_DT, dbo.BOM_DET.EFF_DT, dbo.BOM_DET.USED_INKIT, dbo.INVENTOR.PART_SOURC, dbo.INVENTOR.PHANT_MAKE, dbo.INVENTOR.MAKE_BUY, dbo.INVENTOR.MRP_CODE
FROM            dbo.BOM_DET INNER JOIN
                         dbo.INVENTOR ON dbo.BOM_DET.UNIQ_KEY = dbo.INVENTOR.UNIQ_KEY INNER JOIN
                         dbo.INVENTOR AS BomHead ON BomHead.UNIQ_KEY = dbo.BOM_DET.BOMPARENT
WHERE        (BomHead.BOM_STATUS = 'Active')