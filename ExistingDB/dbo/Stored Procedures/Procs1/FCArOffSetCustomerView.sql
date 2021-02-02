-- =============================================
-- Author:		Vicky Lu
-- Create date: 06/04/15
-- Description:	In AR offset add by a customer/fcused_uniq (if FC is installed)
-- =============================================
CREATE PROC [dbo].[FCArOffSetCustomerView] AS 
SELECT DISTINCT Customer.Custname, Customer.Custno, acctsrec.fcused_uniq, fcused.symbol 
      FROM Customer, Acctsrec, fcused 
      WHERE Customer.Custno = Acctsrec.Custno
      AND Acctsrec.Invtotal <> Acctsrec.Arcredits
      AND acctsrec.fcused_uniq = fcused.fcused_uniq
      ORDER BY Customer.Custname
  