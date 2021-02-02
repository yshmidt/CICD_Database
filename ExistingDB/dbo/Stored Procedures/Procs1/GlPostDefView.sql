create proc [dbo].[GlPostDefView] 
as SELECT Glpostdef.uniqrecord, Glpostdef.disporder, Glpostdef.posttype,
  Glpostdef.directpost
 FROM 
     glpostdef;
