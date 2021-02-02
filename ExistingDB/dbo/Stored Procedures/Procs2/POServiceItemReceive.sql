-- =============================================              
-- Author :  Nitesh B              
-- Create date : 09/09/2019              
-- Description : PO Upload : PO Receiving for service item on approval  
-- exec dbo.POServiceItemReceive '000000000001955' , '49F80792-E15E-4B62-B720-21B360E3108A'              
--- =============================================      
CREATE PROCEDURE dbo.POServiceItemReceive
 --Add the parameters for the stored procedure here 
 (
 @pNum varchar(15) = '',                      
 @userId UNIQUEIDENTIFIER = null 
 )                    
AS              
BEGIN 
 SET NOCOUNT ON; 
	DECLARE @PONUM CHAR(15), @UNIQSUPNO CHAR(10), @OutReceiverHdrId CHAR(10);
	DECLARE @PackingListNumber VARCHAR(50);

	DECLARE @ReceiverNo VARCHAR(10);
	EXEC GetNextGeneralReceiverNo @ReceiverNo out
	SELECT  @ReceiverNo

	DECLARE @REC table(PLNo VARCHAR(50))
	INSERT INTO @REC exec GetNextPackingListNumber
	SELECT @PackingListNumber = PLNo FROM @REC

	--Declare table for @ReceiverTemp
	DECLARE @ReceiverTemp TABLE(UNIQLNNO char(10), UNIQ_KEY char(10) ,PARTMFGR char(8) ,MFGR_PT_NO char(30) ,
				ORD_QTY numeric(10, 2), U_OF_MEAS char(4), PUR_UOFM char(4), UNIQMFGRHD char(10)) 

	--Declare table for @ReceiverDetail
	DECLARE @ReceiverDetail TABLE( receiverHdrId char(10),uniqlnno char(10), Uniq_key char(10) ,Partmfgr char(8) ,mfgr_pt_no char(30) ,
				Qty_rec numeric(10, 2),isinspReq bit ,isinspCompleted bit ,isCompleted bit ,receiverDetId char(10),QtyPerPackage numeric(12, 2) ,GL_NBR char(13)) 

	--Declare table for @porecdtl
	DECLARE @porecdtl TABLE( uniqrecdtl char(10),receiverdetId char(10), uniqlnno char(10), porecpkno char(15), recvdate smalldatetime, ReceivedQty numeric(12, 2),
	FailedQty numeric(12, 2), AcceptedQty numeric(12, 2), U_of_meas char(4), pur_uofm char(4), receiverno char(10), uniqmfgrhd char(10), partmfgr char(8), 
	mfgr_pt_no char(35), IS_PRINTED bit, IS_LABELS bit, sourceDev char(1), FcUsed_uniq char(10), Fchist_key char(10))

 BEGIN TRANSACTION  
	BEGIN TRY
		SELECT TOP 1 @PONUM = PONUM ,@UNIQSUPNO = UNIQSUPNO FROM POMAIN WHERE PONUM = @pNum

		INSERT INTO @ReceiverTemp(UNIQLNNO, UNIQ_KEY, PARTMFGR, MFGR_PT_NO, ORD_QTY, U_OF_MEAS, PUR_UOFM, UNIQMFGRHD) 
		SELECT UNIQLNNO, UNIQ_KEY, PARTMFGR, MFGR_PT_NO, ORD_QTY, U_OF_MEAS, PUR_UOFM, UNIQMFGRHD FROM POITEMS WHERE PONUM = @pNum  AND POITTYPE ='Services'

		SET @OutReceiverHdrId = dbo.fn_GenerateUniqueNumber()    
		INSERT INTO RECEIVERHEADER (receiverHdrId, ReceiverNo, RecPklNo,dockDate,senderType,senderId,recStatus,recvBy,completeBy,completeDate,carrier
					,waybill,ponum,inspectionSource,reason ) 
			VALUES(@OutReceiverHdrId,@ReceiverNo,@PackingListNumber,GETDATE(),'s',@UNIQSUPNO,'Complete',@userId,@userId,GETDATE(),'','',@PONUM,'P','')

		INSERT INTO @ReceiverDetail(receiverHdrId ,uniqlnno , Uniq_key ,Partmfgr ,mfgr_pt_no ,
					Qty_rec ,isinspReq  ,isinspCompleted  ,isCompleted ,receiverDetId ,QtyPerPackage ,GL_NBR)
		SELECT @OutReceiverHdrId,UNIQLNNO ,UNIQ_KEY,PARTMFGR, MFGR_PT_NO, ORD_QTY,0,0,1,dbo.fn_GenerateUniqueNumber(),null,null FROM @ReceiverTemp

		INSERT INTO receiverDetail(receiverHdrId ,uniqlnno , Uniq_key ,Partmfgr ,mfgr_pt_no ,
					Qty_rec ,isinspReq  ,isinspCompleted  ,isCompleted ,receiverDetId ,QtyPerPackage ,GL_NBR) 
		SELECT * FROM @ReceiverDetail
		--SELECT * FROM @ReceiverDetail

		INSERT INTO @porecdtl(uniqrecdtl,receiverdetId,uniqlnno,porecpkno,recvdate,ReceivedQty,FailedQty,AcceptedQty,U_of_meas,pur_uofm,receiverno,	
			uniqmfgrhd,	partmfgr,mfgr_pt_no,IS_PRINTED,IS_LABELS,SourceDev,FcUsed_uniq,Fchist_key)
		SELECT dbo.fn_GenerateUniqueNumber(), r.receiverDetId, t.UNIQLNNO, @PackingListNumber, GETDATE(), ORD_QTY, 0, ORD_QTY, U_OF_MEAS, PUR_UOFM, @ReceiverNo,
			UNIQMFGRHD, t.PARTMFGR, t.MFGR_PT_NO, 0, 0,'' AS SourceDev,'' AS FcUsed_uniq,'' AS Fchist_key 
		FROM @ReceiverTemp t 
		JOIN @ReceiverDetail r ON t.UNIQLNNO = r.uniqlnno
	
		INSERT INTO poRecDtl(uniqrecdtl,receiverdetId,uniqlnno,porecpkno,recvdate,ReceivedQty,FailedQty,AcceptedQty,U_of_meas,pur_uofm,receiverno,	
			uniqmfgrhd,	partmfgr,mfgr_pt_no,IS_PRINTED,IS_LABELS,SourceDev,FcUsed_uniq,Fchist_key) SELECT * FROM @porecdtl	
		--SELECT * FROM poRecDtl	
		
		INSERT INTO PORECLOC (UNIQDETNO ,ACCPTQTY ,LOC_UNIQ ,RECEIVERNO ,SDET_UNIQ ,SINV_UNIQ ,REJQTY ,FK_UNIQRECDTL ,UNIQWH ,LOCATION ,sourceDev )
		SELECT UNIQDETNO,SCHD_QTY,dbo.fn_GenerateUniqueNumber(),@ReceiverNo,'','',0,uniqrecdtl,UNIQWH,LOCATION,'' FROM POITSCHD ps INNER JOIN @porecdtl prc ON ps.UNIQLNNO = prc.uniqlnno AND ps.PONUM = @pNum
																		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			SELECT ERROR_MESSAGE() AS ErrorMessage;
			ROLLBACK TRANSACTION; -- rollback to MySavePoint
		END
	END CATCH
END