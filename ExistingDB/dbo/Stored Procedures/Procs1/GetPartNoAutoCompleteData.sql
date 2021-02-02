-- =============================================
-- Author:Satish B
-- Create date: 04/12/2017
-- Description:	Get Part Number AutoComplete Data
-- GetPartNoAutoCompleteData
-- =============================================
CREATE PROCEDURE GetPartNoAutoCompleteData
 AS
 BEGIN
	 SET NOCOUNT ON
     SELECT Uniq_Key,Part_No,Revision 
	 FROM INVENTOR 
	 WHERE STATUS='Active' AND CUSTNO=''
END