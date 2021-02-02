create proc [dbo].[UdfprogView] 
AS SELECT Udfprog.buttncapto, Udfprog.formname, Udfprog.buttncaptu,
  Udfprog.progname, Udfprog.uniquenum
 FROM udfprog
