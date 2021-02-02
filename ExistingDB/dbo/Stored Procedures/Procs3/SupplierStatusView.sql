CREATE PROCEDURE [dbo].[SupplierStatusView]
AS SELECT LEFT(Text,20) as SuplStatus,LEFT(Text2,20) as DefStatus FROM Support WHERE Fieldname = 'SUPPL_STAT' ORDER BY Text2
/****** Object:  StoredProcedure [dbo].[SupplierStatusSetupView]    Script Date: 08/14/2009 09:47:59 ******/
SET ANSI_NULLS ON
