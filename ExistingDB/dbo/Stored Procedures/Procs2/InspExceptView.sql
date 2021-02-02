-- =============================================
-- Author:	MaheshB
-- Create date: 12/10/2019
-- Description:	Procedure fetch the inspection exception data
-- =============================================

CREATE PROC [dbo].[InspExceptView]     
AS  
 SELECT TRIM(INSPEXCEPTION) AS INSPEXCEPTION,TRIM(EXCEPTUNIQUE) AS EXCEPTUNIQUE FROM InspExcept ORDER BY InspException  