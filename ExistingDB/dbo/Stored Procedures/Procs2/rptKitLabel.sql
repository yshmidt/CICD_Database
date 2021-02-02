-- =============================================
-- Author:Rajendra K
-- Create date: 03/01/2017
-- Description:	Used to print Kit Label
-- 07/07/2017 Rajendra K : Changed datatype of parameter @lcInvtRes
-- 10/09/2017 Rajendra K : Addded logic for Print multiple labels
-- 10/17/2017 Rajendra K : Changed picked quantity from IPKEY table to Ipkey table Reserved Qty
-- 10/17/2017 Rajendra K : Added IpKey table in join condition to get Picked qty from Ipkey table
-- 10/26/2017 Rajendra K : Parameter and temp table name changed as per naming convention used for Store_Proc
-- 10/26/2017 Rajendra K : Added WONO,LotCode,ExpDate,Reference in temptable and select list
-- 10/30/2017 Rajendra K : Added logic to get Allocated qty in case of SID not available 
-- 10/30/2017 Rajendra K : Changed join condition for tables INVTMFGR MfgrMaster,and InvtMpnLink (from left join to Inner join)
-- 10/30/2017 Rajendra K : Changed join condition for tables iReserveIpKey and IPKEY (from Inner join to Left join)
-- 11/03/2017 Rajendra K : Added logic to get reserved qty for non-sid components
-- 11/30/2017 Rajendra K : Removed white space from Part_No
-- 10/26/2017 Rajendra K : Updated length of LotCode
-- 11/02/2018 Rajendra K : Calculated Overage
-- 07/04/2018 Shivshankar p :  Changed the Description data type
-- 05/08/2019 Rajendra K : selected Distinct records
-- 07/24/2019 Rajendra K : Changed the size @lotCode 15 To 25 and @poNum 12 to 15 and added RTRIM to partNo column
-- 07/24/2019 Rajendra K : Changed condition when parttype is null to get description. 
-- 07/31/2019 Rajendra K : Changed 1 To ITAR from inventor  
-- rptKitLabel 'GAZ4RWKQ7B'  
---- 10/11/2019 YS change char(25) to char(35) for part_no
-- =============================================
CREATE PROCEDURE [dbo].[rptKitLabel]   
(
@lcInvtRes NVARCHAR(MAX)='' -- 07/07/2017 Rajendra K : Changed datatype of parameter @lcInvtRes
)
AS
BEGIN
	SET NOCOUNT ON;
	   SET @lcInvtRes = @lcInvtRes + ',';

	   --10/09/2017 Rajendra K : Added Temp table #invtResList to hold InvtResNo list
	   CREATE TABLE #invtResList
	   (
	    RowNum INT Identity(1,1),
	    InvtResNo CHAR(10),
	    InvtRes VARCHAR(MAX)
	   )

	   --10/09/2017 Rajendra K : Added Temp table #labelData to hold result
	   CREATE TABLE #labelData
	   (
	    ITAR BIT,
	    WorkCenter CHAR(4),
		---- 10/11/2019 YS change char(25) to char(35) for part_no
	    PartNo CHAR(45),
	    Description NVARCHAR(250), -- 07/04/2018 Shivshankar p :  Changed the Description data type
	    MatlType VARCHAR(10),
	    PartMfgr VARCHAR(8),
	    MfgrPartNo VARCHAR(30),
	    AllocatedQty NUMERIC(13,2),
	    Required NUMERIC(13,2),
	    Reserve NUMERIC(13,2),
	    Overage NUMERIC(13,2),
	    SID CHAR(10),
	    ResDate SMALLDATETIME,
	    -- 10/26/2017 Rajendra K : Added ,LotCode,ExpDate,Reference
		WONO CHAR(10),
		LotCode CHAR(25), -- 10/26/2017 Rajendra K : Updated length of LotCode
		ExpDate SMALLDATETIME,
		Reference CHAR(12)
 	   )

	   --Get InvtResNo list from comma separeted string
	   ;WITH InvtResNoList AS
		(
			SELECT SUBSTRING(@lcInvtRes,1,CHARINDEX(',',@lcInvtRes,1)-1) AS InvtResNo, SUBSTRING(@lcInvtRes,CHARINDEX(',',@lcInvtRes,1)+1,LEN(@lcInvtRes)) AS InvtRes 
			UNION ALL
			SELECT SUBSTRING(A.InvtRes,1,CHARINDEX(',',A.InvtRes,1)-1)AS InvtResNo, SUBSTRING(A.InvtRes,charindex(',',A.InvtRes,1)+1,LEN(A.InvtRes)) 
			FROM InvtResNoList A WHERE LEN(a.InvtRes)>=1
        ) 

		--10/09/2017 Rajendra K : Insert InvtResNo List from CTE InvtResNoList
		INSERT INTO #invtResList (InvtResNo,InvtRes)
		SELECT InvtResNo,InvtRes FROM InvtResNoList
		
		--10/09/2017 Rajendra K : Declare variables for Count and While loop
		DECLARE @maxId INT, @counter INT
		SET @counter = 1
		
		--10/09/2017 Rajendra K : Get count from #invtResList
		SELECT @maxId = (SELECT COUNT(1) FROM #invtResList)
	
		-- 11/03/2017 Rajendra K : Added new parameters to get reserved qty for non-sid components
  DECLARE @wKey CHAR(10)='',@wONO CHAR(10)='',@lotCode CHAR(25),@expDate SMALLDATETIME=NULL,@reference CHAR(12),  
    @poNum CHAR(15),@kaSeqNum CHAR(10),@allocatedQty DECIMAL(13,5) ;  -- 07/24/2019 Rajendra K : Changed the size @lotCode 15 To 25 and @poNum 12 to 15 and added RTRIM to partNo column 

	    --10/09/2017 Rajendra K : Select record for each InvtRes_No(Repeat for multiple prints)
		
		WHILE (@counter <= @maxId)
		  BEGIN
			
		  	-- 11/03/2017 Rajendra K : Set values for new parameters to get reserved qty for non-sid components
			    SET @lotCode = ''
				SELECT @wKey = W_KEY,@wONO = ir.WONO,@lotCode = ir.LOTCODE,@expDate = ir.EXPDATE,@reference = ir.REFERENCE,@poNum = ir.PONUM,@kaSeqNum = ir.KaSeqnum  
				FROM invt_res ir INNER JOIN #invtResList irl ON ir.INVTRES_NO = irl.InvtResNo 
				WHERE RowNum = @counter

				IF (@lotCode != '')
				BEGIN
				-- 11/03/2017 Rajendra K : Get allocated qty to get reserved qty for Lotted components
					SELECT @allocatedQty = SUM(QTYALLOC)
					FROM INVT_RES IR 
					WHERE IR.WONO = @wONO AND KaSeqNum = @kaSeqNum
					      AND IR.LOTCODE = @lotCode AND IR.EXPDATE = @expDate AND IR.REFERENCE = @reference AND IR.PONUM = @poNum
				END
				ELSE
				BEGIN
				-- 11/03/2017 Rajendra K : Get allocated qty to get reserved qty for Manufacturer components
				    SELECT @allocatedQty = SUM(QTYALLOC)
				    FROM INVT_RES IR 
				    WHERE IR.WONO = @wONO  AND W_KEY = @wKey  AND IR.KaSeqnum = @kaSeqNum
				END

				INSERT INTO #labelData
				SELECT DISTINCT I.ITAR -- 05/08/2019 Rajendra K : selected Distinct records
      ,D.dept_id AS WorkCenter  -- 07/24/2019 Rajendra K : Changed the size @lotCode 15 To 25 and @poNum 12 to 15 and added RTRIM to partNo column
      ,RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) AS PartNo  
      ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE I.PART_CLASS +' / ' END ) + -- 07/24/2019 Rajendra K : Changed condition when parttype is null to get description. 
       (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN ' / '+ I.DESCRIPT ELSE I.PART_TYPE + ' /'+I.DESCRIPT END) AS Descript  
						,MM.MatlType
						,MM.PartMfgr
						,MM.mfgr_pt_no AS MfgrPartNo
						,ISNULL(IP.qtyAllocatedTotal,ISNULL(@allocatedQty,ISNULL(IL.LOTRESQTY,INVTMF.RESERVED))) AS AllocatedQty --Picked Quantity -- 10/17/2017 Rajendra K : Change picked quantity from Ireserve table to Ipkey table Reserved Qty
						        --10/30/2017 Rajendra K : Added logic to get Allocated qty in case of SID not available
								--11/03/2017 Rajendra K : Added @allocatedQty to get Reserved Qty for non-sid  components
						
						,(K.SHORTQTY+(K.ACT_QTY+K.allocatedQty)) AS Required
						,INVTMF.RESERVED AS Reserve
						-- 11/02/2018 Rajendra K : Calculated Overage
						--,0 AS Overage
						,(CASE WHEN
						(ISNULL(IP.qtyAllocatedTotal,ISNULL(@allocatedQty,ISNULL(IL.LOTRESQTY,INVTMF.RESERVED)))) 
						- (K.SHORTQTY+(K.ACT_QTY+K.allocatedQty)) > 0 THEN  
						(ISNULL(IP.qtyAllocatedTotal,ISNULL(@allocatedQty,ISNULL(IL.LOTRESQTY,INVTMF.RESERVED)))) 
						- (K.SHORTQTY+(K.ACT_QTY+K.allocatedQty))
						ELSE 0 END) AS Overage						
						,ISNULL(IRP.ipkeyunique,'') AS SID 
						,IR.DATETIME AS ResDate
						-- 10/26/2017 Rajendra K : Added ,LotCode,ExpDate,Reference
						,IR.WONO 
						,IR.LOTCODE AS LotCode
						,IR.EXPDATE AS ExpDate
						,IR.REFERENCE AS Reference
				FROM invt_res IR 
					   INNER JOIN INVENTOR I ON IR.UNIQ_KEY = I.UNIQ_KEY
					   RIGHT JOIN KAMAIN K ON IR.KaSeqnum = K.KASEQNUM
					   INNER JOIN WOENTRY W ON W.WONO=k.WONO
						 --10/30/2017 Rajendra K : Changed join condition for tables INVTMFGR MfgrMaster,and InvtMpnLink (from left join to Inner join)
					   INNER JOIN INVTMFGR INVTMF ON  IR.W_KEY =  INVTMF.W_KEY
					   INNER JOIN InvtMpnLink IM ON invtMf.UniqMfgrHd = IM.UniqMfgrHd
					   INNER JOIN MfgrMaster MM ON IM.mfgrMasterid = MM.MfgrMasterId
					   LEFT JOIN Depts D ON K.dept_id = D.dept_id
					   INNER JOIN WAREHOUS WH ON invtMf.UNIQWH = WH.UNIQWH
						 --10/30/2017 Rajendra K : Changed join condition for tables iReserveIpKey and IPKEY (from Inner join to Left join)
					   LEFT JOIN iReserveIpKey IRP ON IR.INVTRES_NO = IRP.INVTRES_NO
					   LEFT JOIN IPKEY IP ON IRP.ipkeyunique = IP.IPKEYUNIQUE -- 10/17/2017 Rajendra K : Added IpKey table in join condition to get Pcked qty from Ipkey table
					   LEFT JOIN INVTLOT IL ON IR.LOTCODE = IL.LOTCODE AND IR.EXPDATE = IL.EXPDATE AND IR.REFERENCE = IL.REFERENCE AND IR.PONUM = IL.PONUM
						            --10/31/2017 Rajendra K : Added InvtLot table in join condition to get Reserved qty in case of SID not available
				WHERE  (@lcInvtRes IS NULL OR @lcInvtRes = '' OR IR.INVTRES_NO IN (SELECT InvtResNo FROM #invtResList WHERE RowNum = @counter))
		  SET  @counter = @counter + 1;
		END
		SELECT ITAR--1 AS ITAR   -- 07/31/2019 Rajendra K : Changed 1 To ITAR from inventor  
			  ,WorkCenter
			  ,REPLACE(PartNo, ' ', '') AS PartNo -- 11/30/2017 Rajendra K : Removed white space
			  ,Description
			  ,MatlType
			  ,PartMfgr
			  ,MfgrPartNo
			  ,AllocatedQty
			  ,Required
			  ,Reserve
			  ,Overage
			  ,SID
			  -- 10/26/2017 Rajendra K : Added WONO,LotCode,ExpDate,Reference
			  ,WONO
			  ,LotCode
			  ,CONVERT(VARCHAR(10), ExpDate, 103) AS ExpDate
			  ,Reference
	    FROM #labelData
	    ORDER BY ResDate DESC

	    --10/09/2017 Rajendra K : rop temp tables
	    DROP TABLE #invtResList,#labelData
END	