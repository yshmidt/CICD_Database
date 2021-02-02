
CREATE proc [dbo].[ShipChargeView] AS SELECT LEFT(TEXT,15) as ShipCharge FROM Support WHERE FIELDNAME='SHIPCHARGE' order by Number
