CREATE PROCEDURE dbo.BarCodeErrorLogSFAdd
(
	@Wono char(10)
   ,@UserId uniqueidentifier
   ,@Dept_Id char(10)
   ,@SerialNo varchar(30)   
   ,@ErrorDetails varchar(500)
)
AS
BEGIN

	INSERT INTO [dbo].[BarCodeErrorLogSF]
           ([Wono]
           ,[UserId]
           ,[Dept_Id]
           ,[SerialNo]
           ,[InsertDate]
           ,[ErrorDetails])
     VALUES
           (@Wono
           ,@UserId
           ,@Dept_Id
           ,@SerialNo
           ,GETDATE()
           ,@ErrorDetails)
END
