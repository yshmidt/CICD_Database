create proc [dbo].[InvtHandExpReasonView]
as SELECT Invthdef.reason, Invthdef.uniq_field, Invthdef.type
 FROM invthdef WHERE  Invthdef.type = 'E'
