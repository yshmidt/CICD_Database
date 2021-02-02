-- Modification
   -- 10/30/2017 Rajendra K : Added columns WH_MAP and ALLOW_MX_FIND_LOC_ATRECEV 
CREATE procedure [dbo].[WarehouseDeletedView]
AS 
SELECT Warehous.whno, Warehous.warehouse, Warehous.wh_descr,
  Warehous.wh_gl_nbr, Warehous.wh_note,
  Warehous.[default], Warehous.gldivno,
  Warehous.whstatus, Warehous.lnotautokit, Warehous.is_deleted,
  Warehous.autolocation, Warehous.lremovewhenzero, Warehous.ladd2newavl,
  Warehous.uniqwh,ISNULL(Gl_nbrs.gl_descr,SPACE(30)) gl_descr ,
  Warehous.WH_MAP,Warehous.ALLOW_MX_FIND_LOC_ATRECEV -- 10/30/2017 Rajendra K : Added columns WH_MAP and ALLOW_MX_FIND_LOC_ATRECEV 
  FROM warehous LEFT OUTER JOIN gl_nbrs  ON  Warehous.wh_gl_nbr = Gl_nbrs.gl_nbr 
 WHERE Warehous.is_deleted=1
 ORDER BY Warehous.whno 