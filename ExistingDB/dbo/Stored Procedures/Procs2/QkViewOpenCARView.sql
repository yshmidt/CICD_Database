CREATE PROCEDURE [dbo].[QkViewOpenCARView]
@userid uniqueidentifier = null
AS
BEGIN

SET NOCOUNT ON;

SELECT NewDue_dt, DATEDIFF(day, NewDue_dt, GETDATE()) AS DaysLate, Carno, Prob_type, Orignatr, Descript 
	FROM Craction 
	WHERE Compdate IS NULL
	ORDER BY NewDue_dt 
   
END
