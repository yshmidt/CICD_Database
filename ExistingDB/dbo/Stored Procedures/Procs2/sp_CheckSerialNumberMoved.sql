-- =============================================
-- Author:		Vicky Lu
-- Create date: 2014/04/25
-- Description:	Create this sp to check if passed in SN are moved or not, use in shopflwo transfer
-- =============================================
CREATE PROCEDURE [dbo].[sp_CheckSerialNumberMoved] 
	@ltSerialUniq AS tSerialUniq READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT Invtser.SERIALUNIQ, Invtser.Serialno, Invtser.Id_key, Invtser.Id_value 
	FROM INVTSER, @ltSerialUniq tSerialUniq
	WHERE Invtser.SERIALUNIQ = tSerialUniq.SerialUniq	
	AND (Invtser.ID_KEY <> tSerialUniq.Id_key 
	OR Invtser.Id_value <> tSerialUniq.Id_Value)
	
END