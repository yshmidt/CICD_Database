-- =============================================
-- Author:Satish B
-- Create date: 04/12/2017
-- Description:	Get Packing List Number AutoComplete Data
-- GetPlNoAutoCompleteData
-- =============================================
CREATE PROCEDURE GetPlNoAutoCompleteData
 AS
 BEGIN
	 SET NOCOUNT ON
     SELECT ReceiverHdrId,RecPklNo,ReceiverNo 
	 FROM receiverHeader
END