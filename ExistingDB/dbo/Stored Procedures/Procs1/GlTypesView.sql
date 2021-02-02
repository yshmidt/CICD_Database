-- =============================================
-- Author:		<Bill Blake>
-- Create date: <09/10/09>
-- Description:	[GlTypesView]
--Modified: 02/19/16 YS added cashActCode
--Modified: 08/09/2017 NileshSa added left join on mnxcashFlowActivities to fetch cashActName
-- =============================================
CREATE proc [dbo].[GlTypesView]
as
SELECT Gltypes.gltype, Gltypes.uniqgltype, Gltypes.gltypedesc,
  Gltypes.lo_limit, Gltypes.hi_limit, Gltypes.gtnote, Gltypes.stmt,
  Gltypes.norm_bal, Gltypes.company ,Gltypes.cashFlowActCode, MnxCFA.cashActName
 FROM gltypes Gltypes left join mnxcashFlowActivities MnxCFA on Gltypes.cashFlowActCode = MnxCFA.cashFlowActCode ;