CREATE PROC [dbo].[SupplierRemitView] 
	@lcSupId AS char(10)=''
AS SELECT * FROM Shipbill WHERE Custno = @lcSupId AND Recordtype='R'