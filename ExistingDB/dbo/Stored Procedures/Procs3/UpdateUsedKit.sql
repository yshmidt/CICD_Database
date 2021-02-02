-- =============================================
-- Author:		Rajendra K	
-- Create date: <07/17/2017>
-- Description:Update Reserved/Issued kit
   --UpdateUsedKit 'UIKKVDYDFB'
CREATE PROCEDURE [dbo].[UpdateUsedKit]
(
@KaSeq CHAR(10)=''
)
AS
BEGIN
	 SET NOCOUNT ON;
     DECLARE @UniqKey CHAR(10) = (SELECT UNIQ_KEY FROM KAMAIN WHERE KASEQNUM = @KaSeq),
	 @QtyAllocated NUMERIC(12,2),
	 @InvtResNo CHAR(10),
	 @NewInvtResNo CHAR(10) =dbo.fn_GenerateUniqueNumber(),
	 @CurrentDate SMALLDATETIME
		 
	 SET @CurrentDate = GETDATE()--Set Date in SMALLDATETIME format

	 --Get InvtRes_No for REFINVTRES column in Invt_Res tabkev
	 SELECT @InvtResNo = IRN.InvtRes_No
	 FROM INVT_RES IR
     JOIN (SELECT InvtRes_No,
         ROW_NUMBER() OVER(ORDER BY DATETIME ASC) AS RowNum
         from INVT_RES WHERE KaSeqnum = @KaSeq) IRN
      ON IR.InvtRes_No = IRN.InvtRes_No AND IRN.RowNum = 1

	    BEGIN
		SET @QtyAllocated = (SELECT SUM(QTYALLOC) FROM INVT_RES WHERE KaSeqnum = @KaSeq)
		--Check if QtyAllocated is not zero
			IF(@QtyAllocated <> 0 )
			  BEGIN
				--Insert record into INVT_RES
				 INSERT INTO INVT_RES
				 SELECT  W_KEY,UNIQ_KEY
						,CAST(GETDATE() AS SMALLDATETIME)
						,-@QtyAllocated
						,WONO
						,@NewInvtResNo
						,SONO
						,UNIQUELN
						,LOTCODE
						,EXPDATE
						,REFERENCE
						,PONUM
						,SAVEINIT
						,@InvtResNo
						,FK_PRJUNIQUE
						,KaSeqnum
						,fk_userid
						,FUNCFCUSED_UNIQ
						,PRFCUSED_UNIQ 
						FROM invt_Res 
						WHERE KaSeqnum = @KaSeq
			  END
	  END

	  --UnReserve component for scenario SERIALYES = 1
	 IF EXISTS(SELECT 1 FROM INVENTOR WHERE UNIQ_KEY = @UniqKey AND SERIALYES = 1)
	  BEGIN
	    DECLARE @Counter INT = 1, @IResSerCount INT
		--Declare table for ContractItem list
		DECLARE @IResSerialTemp TABLE
			( 
				  RowId int identity(1,1) primary key
				 ,ISerialUniq CHAR(10)
				 ,SerialUniq CHAR(10)
			) 

		INSERT INTO @IResSerialTemp(ISerialUniq,SerialUniq) 
		SELECT iResSerUnique
			   ,serialuniq 
		FROM  iReserveSerial
		WHERE kaseqnum = @KaSeq

		DECLARE @iReservedSerial Table
								(
								 iResSerUnique CHAR(10)
								,invtres_no CHAR(10)
								,serialuniq CHAR(10)
								,ipkeyunique CHAR(10)
								,kaseqnum CHAR(10)
								,isDeallocate BIT
								)

		IF EXISTS((SELECT COUNT(1) FROM @IResSerialTemp))
		BEGIN		    
		DECLARE @InvtNo CHAR(10) = dbo.fn_GenerateUniqueNumber()
			SET @IResSerCount = (SELECT COUNT(1) FROM @IResSerialTemp)
			WHILE (@Counter <= @IResSerCount)
			BEGIN 
			 DECLARE @CurrentSerialUniq CHAR(10)= (SELECT serialuniq FROM @IResSerialTemp WHERE RowId = @Counter)
		
			 IF NOT EXISTS(SELECT 1 FROM @iReservedSerial WHERE iResSerUnique = @CurrentSerialUniq) 
			 BEGIN
			  DECLARE @SerAllocateCount INT , @SerDeAllocateCount  INT			  
			  SET @SerAllocateCount = (Select COUNT(1) FROM iReserveSerial WHERE serialuniq =  @CurrentSerialUniq AND isDeallocate = 0)
			  IF EXISTS(Select 1 FROM iReserveSerial WHERE serialuniq = @CurrentSerialUniq AND isDeallocate = 1)
			  BEGIN
				SET @SerDeAllocateCount = (Select COUNT(1) FROM iReserveSerial WHERE serialuniq = @CurrentSerialUniq AND isDeallocate = 1)
			  END
			  ELSE
			  BEGIN
			  SET @SerDeAllocateCount = 0
			  END
			     --Check if current serialNumber record not deallocated
                 IF(@SerAllocateCount <> @SerDeAllocateCount)
				 BEGIN
				 --Insert record into iReserveSerial
					INSERT INTO @iReservedSerial 
								(
								 iResSerUnique
								,invtres_no
								,serialuniq
								,ipkeyunique
								,kaseqnum
								,isDeallocate
								)
						  SELECT dbo.fn_GenerateUniqueNumber()
								,@NewInvtResNo
								,serialuniq
								,ipkeyunique
								,kaseqnum
								,1
						  FROM  iReserveSerial WHERE iResSerUnique =(SELECT ISerialUniq FROM @IResSerialTemp WHERE RowId=@IResSerCount)			
				 END
			  END
			  SET @Counter = @Counter+1
			END
			IF EXISTS(SELECT 1 FROM @iReservedSerial)
			BEGIN
				INSERT INTO iReserveSerial
				SELECT * FROM @iReservedSerial
			END
		END
	 END

	 --UnReserve component for scenario USEIPKEY = 1 aND SERIALYES = 0
	 IF EXISTS(SELECT 1 FROM INVENTOR WHERE UNIQ_KEY = @UniqKey AND USEIPKEY = 1 aND SERIALYES = 0)
	  BEGIN

	    DECLARE @IpKeyCounter INT = 1 , @IResIpKeyCount INT
		--Declare table for IResIpKeyTemp
		DECLARE @IResIpKeyTemp TABLE
			( 
			  RowId int identity(1,1) primary key
			 ,IResIPKey CHAR(10)
			 ,IPKeyUniq CHAR(10)
			)

		DECLARE @IReserveIpKeyTemp TABLE
			(
			  iResIpKeyUnique CHAR(10)
			  ,invtres_no CHAR(10)
			 ,qtyAllocated NUMERIC(12,2)
			  ,qtyOver NUMERIC(12,2)
			  ,ipkeyunique CHAR(10)
			  ,KaSeqnum CHAR(10)
			)
		INSERT INTO @IResIpKeyTemp(IResIPKey,IPKeyUniq) 
		SELECT iResIpKeyUnique
			  ,ipkeyunique 
		FROM  iReserveIpKey
		WHERE KaSeqnum = @KaSeq

		IF EXISTS( (SELECT 1 FROM @IResIpKeyTemp))
		BEGIN
		DECLARE @InvtsNo CHAR(10) = dbo.fn_GenerateUniqueNumber()
			SET @IResIpKeyCount = (SELECT COUNT(1) FROM @IResIpKeyTemp)

			WHILE (@IpKeyCounter <= @IResIpKeyCount)
			BEGIN
				DECLARE @CurrentIpKey CHAR(10)
				SET @CurrentIpKey  = (SELECT IPKeyUniq FROM @IResIpKeyTemp WHERE ROWID = @IpKeyCounter)

				IF NOT EXISTS(SELECT 1 FROM @IReserveIpKeyTemp WHERE ipkeyunique = @CurrentIpKey)
				BEGIN
					DECLARE @IpKeyQtyAllocated NUMERIC(12,2)= (SELECT SUM(qtyAllocated) FROM iReserveIpKey WHERE ipkeyunique = @CurrentIpKey)
					IF(@IpKeyQtyAllocated <> 0)
					BEGIN
						INSERT INTO @IReserveIpKeyTemp
						    (
							 iResIpKeyUnique
							,invtres_no
							,qtyAllocated
							,qtyOver
							,ipkeyunique
							,KaSeqnum
							)
						SELECT dbo.fn_GenerateUniqueNumber()
							,@NewInvtResNo
							,- @IpKeyQtyAllocated
							,0
							,ipkeyunique
							,KaSeqnum
							  FROM  iReserveIpKey WHERE iResIpKeyUnique = 
							(SELECT IResIPKey FROM @IResIpKeyTemp WHERE ROWID = @IResIpKeyCount)
				    END									
				END	
				SET @IpKeyCounter = @IpKeyCounter + 1				
			END
				--Insert record into iReserveIpKey
						INSERT INTO iReserveIpKey
						SELECT * FROM @IReserveIpKeyTemp
		END
	  END	
END