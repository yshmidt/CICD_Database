-- =============================================
-- Author:Rajendra K
-- Create date: 03/16/2017
-- Description:	Save WO Reeservation details
-- Modification
	-- 04/20/2017 Rajendra K : Removed columns LOTCODE ,EXPDATE ,REFERENCE ,PONUM from insert statement when IsLot flag is false(0)
	---03/02/18 YS change size of the lotcode field to 25
-- =============================================

CREATE PROCEDURE [dbo].[SaveWOReservation]
(
	---03/02/18 YS change size of the lotcode field to 25
	@tSerialNumberList tSerialNumber READONLY,
	@Kaseqnum CHAR(10),
    @Uniqkey CHAR(10),
	@Wkey CHAR(10),
	@UniqLotcode CHAR(10),
    @QtyAllocated CHAR(10),
	@Lotcode nvarchar(25)='',
	@Expdate DATETIME=NULL,
	@Reference CHAR(10)='',
	@PoNumber CHAR(10)='',
	@UniqMfgrhd CHAR(10),
	@WONO CHAR(10),
	@SONO CHAR(10),
	@PRJUNIQUE CHAR(10),
	@IpKeyUnique CHAR(10),
	@Scenario VARCHAR(30),
	@IsLot BIT = 0,
	@IsSID BIT = 0,
	@IsSerial BIT = 0,
	@UserId uniqueidentifier= null
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	DECLARE @Invt_Res_No CHAR(10);
	--Declare table variable for InvtResNo
	DECLARE @InvtRes TABLE(
			InvtResNo CHAR(15) NOT NULL
			)

	--Declare "output into table" and use it when insert into invt_res
	DECLARE @TempIReserveSerial table 
					(
					  SerialUniq CHAR(10)
					 ,SerialNo CHAR(10)
					 ,Uniq_Key CHAR(10)
					 ,UniqMfgrHd CHAR(10)
					 ,IpKeyUnique CHAR(10)
					 ,IsChecked BIT
					)
	--Insert record into Invt_Res
	BEGIN TRY
	BEGIN TRANSACTION

	IF(@IsLot =1)
	BEGIN
	 INSERT INTO Invt_Res (
						   KaSeqnum
						   ,W_Key
						   ,UNIQ_KEY
						   ,INVTRES_NO
						   ,QTYALLOC
						   ,WONO
						   ,SONO
						   ,LOTCODE
						   ,EXPDATE
						   ,REFERENCE
						   ,PONUM
						   ,FK_PRJUNIQUE
						   ,fk_userid
						  )
						  OUTPUT inserted.INVTRES_NO INTO @InvtRes
						  SELECT @Kaseqnum 
						   ,@Wkey 
						   ,@Uniqkey 
						   ,dbo.fn_GenerateUniqueNumber()
						   ,@QtyAllocated
						   ,@WONO 
						   ,@SONO 
						   ,LOTCODE
						   ,EXPDATE
						   ,REFERENCE
						   ,PONUM
						   ,@PRJUNIQUE
						   ,@UserId 
						   FROM INVTLOT
						WHERE UNIQ_LOT = @UniqLotcode
    END
	ELSE
	BEGIN
	-- 04/20/2017 Rajendra K : Removed columns LOTCODE ,EXPDATE ,REFERENCE ,PONUM from insert statement when IsLot flag is false(Defaults connstraints availble for these columns in table Invt_Res)
		 INSERT INTO Invt_Res (
						   KaSeqnum
						   ,W_Key
						   ,UNIQ_KEY
						   ,INVTRES_NO
						   ,QTYALLOC
						   ,WONO
						   ,SONO
						   ,FK_PRJUNIQUE
						   ,fk_userid
						  )
						  OUTPUT inserted.INVTRES_NO INTO @InvtRes
						  SELECT @Kaseqnum 
						   ,@Wkey 
						   ,@Uniqkey 
						   ,dbo.fn_GenerateUniqueNumber()
						   ,@QtyAllocated
						   ,@WONO 
						   ,@SONO 
						   ,@PRJUNIQUE
						   ,@UserId 
	END

	 SET @Invt_Res_No = (SELECT  InvtResNo FROM @InvtRes)

	 IF (@IsSerial = 0)
	 BEGIN
	--Insert record into ireserveIpkey
     INSERT INTO ireserveIpkey (
	 	                         invtres_No
								,QtyAllocated
								,qtyOver
								,ipkeyUnique
								,KaSeqnum 
							   )
					    VALUES (
								@Invt_Res_No,
								@QtyAllocated
								,0
								,@IpKeyUnique
								,@Kaseqnum 
					           )

	END

	--Insert records into ireserveserial table
	 IF (@IsSerial = 1)
	 BEGIN
			INSERT INTO ireserveserial (
							    invtres_no
								,serialuniq
								,ipkeyunique
								,kaseqnum
								)
					     SELECT @Invt_Res_No
						        ,SerialUniq
						        ,@IpKeyUnique 
								,@Kaseqnum
						 FROM @tSerialNumberList
	END
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK
			SELECT @ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
	END CATCH	
	IF @@TRANCOUNT>0
		COMMIT 
END

