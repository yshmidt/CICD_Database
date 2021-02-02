create proc [dbo].[InvtHandRecReasonView]
as
SELECT Invthdef.reason, Invthdef.uniq_field, Invthdef.type
 FROM invthdef
 WHERE  Invthdef.type = 'R'
 ORDER BY Invthdef.reason
