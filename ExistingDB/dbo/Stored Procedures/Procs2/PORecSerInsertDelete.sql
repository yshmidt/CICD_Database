-- =============================================
-- Author:  Shivshankar P
-- Create date: 08/03/17
-- Description:	Insert IReserveSerial
-- 14/09/17 Shisvshankar P : Get 'PORECSER' Table serial number list contains in '@tPoRecser' with Range
-- 10/27/2017 Shivshankar P : Prevent to insert duplicate serial no against the part
-- 11/01/2017 Shivshankar P :  Changed Error Message
-- 11/14/17 Shivshankar P : Get all the serial number which are received against the multiple Schedule
--Shivshankar P : 12/08/17 Get all the serial number which are received against the multiple Schedule against line Item
-- =============================================
CREATE PROCEDURE  [dbo].[PORecSerInsertDelete]
(
@tPoRecser tPoRecser READONLY, 
@uniqKey char(10) = ' ',
@locUniq char(10) = ' ',
@receiverNo char(15) =' ',
@isAdd bit=0,
@fkUniqRecdtl char(10)=' ' 
--@receiverNo CHAR(10),
--@locUniq CHAR(10)
)
AS

BEGIN
	SET NOCOUNT ON;
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;

 BEGIN TRANSACTION
	   BEGIN TRY
	        IF(@isAdd=1)
	        	BEGIN
				-- 10/27/2017 Shivshankar P : Prevent to insert duplicate serial no against the part
			         IF EXISTS (select 1 from INVTSER where serialno in (select serialno from @tPoRecser) and UNIQ_KEY =  @uniqKey)
			         BEGIN
					      RAISERROR ('Serial Number already exists.', -- Message text.  -- 11/01/2017 Shivshankar P :  Changed Error Message
							   16, -- Severity.
								1 -- State.
							);
					 		ROLLBACK transaction
							return
					 END 
			     ELSE 
			          BEGIN
						   insert into PORECSER(POSERUNIQUE,LOC_UNIQ,LOT_UNIQ,serialno,RECEIVERNO,FK_SERIALUNIQ,ipkeyunique,SERIALREJ,[SourceDev])
						   select dbo.fn_GenerateUniqueNumber(),res.Loc_Uniq,res.Lot_Uniq,res.[SerialNo],res.[ReceiverNo],res.[FK_SerialUniq],[IpkeyUnique],0,[SourceDev] 
						   from @tPoRecser res 
					  END
			    END
			   ELSE
			      BEGIN
			          IF EXISTS ( SELECT 1 FROM PORECSER  INNER JOIN
					             @tPoRecser porecse ON PORECSER.serialNo >= dbo.PADL(porecse.Start_range,30,'0') and PORECSER.serialNo <= dbo.PADL(porecse.End_range,30,'0')  -- 14/09/17 Shisvshankar P : Get 'PORECSER' Table serial number list contains in '@tPoRecser' with Range
					             INNER JOIN invtser invt on invt.SERIALUNIQ = PORECSER.FK_SERIALUNIQ --Shivshankar P : 12/08/17 Get all the serial number which are received against the multiple Schedule against line Item
								 WHERE ISRESERVED =1
								 and PORECSER.RECEIVERNO = @receiverNo AND PORECSER.LOC_UNIQ IN (SELECT LOC_UNIQ FROM PORECLOC where FK_UNIQRECDTL =@fkUniqRecdtl))
			         BEGIN
					      RAISERROR ('Some Qty is Reserved.', -- Message text.
							   16, -- Severity.
								1 -- State.
							);
					 		ROLLBACK transaction
							return
					 END 
			     ELSE 
			          BEGIN
					      DELETE from PORECSER where PoserUnique in ( SELECT PORECSER.PoserUnique FROM PORECSER  INNER JOIN
					             @tPoRecser porecse ON PORECSER.serialNo >= dbo.PADL(porecse.Start_range,30,'0') 
								 and PORECSER.serialNo <= dbo.PADL(porecse.End_range,30,'0')   -- 14/09/17 Shisvshankar P : Get 'PORECSER' Table serial number list contains in '@tPoRecser' with Range
					             INNER JOIN invtser invt on invt.SERIALUNIQ = PORECSER.FK_SERIALUNIQ --Shivshankar P : 12/08/17 Get all the serial number which are received against the multiple Schedule against line Item
								 WHERE  PORECSER.RECEIVERNO = @receiverNo and PORECSER.RECEIVERNO = @receiverNo AND PORECSER.LOC_UNIQ IN (SELECT LOC_UNIQ FROM PORECLOC where FK_UNIQRECDTL =@fkUniqRecdtl))
					  END

			        END
	    END TRY	
		
				BEGIN CATCH
					 IF @@TRANCOUNT <>0
						 ROLLBACK TRAN ;
						SELECT @ErrorMessage = ERROR_MESSAGE(),
							   @ErrorSeverity = ERROR_SEVERITY(),
							   @ErrorState = ERROR_STATE();
						RAISERROR (@ErrorMessage, -- Message text.
								   @ErrorSeverity, -- Severity.
								   @ErrorState -- State.
								   );

				END CATCH	

	IF @@TRANCOUNT>0
	COMMIT TRANSACTION	
END


--declare @p1 dbo.tPoRecser
--insert into @p1 values(NULL,NULL,NULL,N'000000000000000000005985725240',NULL,N'False',NULL,NULL,N'5985725240',N'5985725245')
--insert into @p1 values(NULL,NULL,NULL,N'000000000000000000002598575620',NULL,N'False',NULL,NULL,N'2598575620',N'2598575629')

--exec PORecSerInsertDelete @tPoRecser=@p1,@uniqKey=N'_1LR0NALBB',@locUniq=N'C7FQLYFURO',@receiverNo=N'0000001410',@isAdd=0