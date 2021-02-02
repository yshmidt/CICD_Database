--================================================================================
-- Author:  Shivshankar P
-- Create date: <30/11/2017>
-- Description:	Return PO Line Items
-- [GetPORecFilteredData] @filterType=3,@filterValue=' '
-- Nilesh Sa 2/27/2018 Avoid empty pack list number
-- Nilesh Sa 2/28/2018 Added inspectionSource to distingwish PL number 
-- Nilesh Sa 3/5/2018 Remove white spaces from selection columns
-- Shiv P : 04/27/2018 Get data order by dockDate
--================================================================================
CREATE PROCEDURE [GetPORecFilteredData]
(
	@pageNumber int = 0,
	@pageSize int=10,
	@filterValue nvarchar(100) = ' ',
	@filterType int=1,
	@isIsnpection bit =0,
	@inspectionSource char(1)='p'
) 
AS 
   BEGIN
       SET NOCOUNT ON; 
        IF(@filterType = 1)  --Get SUPINFO
	                  SELECT DISTINCT RTRIM(LTRIM(SUPINFO.SUPNAME))  AS Value,SUPINFO.UNIQSUPNO AS Id  -- Nilesh Sa 3/5/2018 Remove white spaces from selection columns
					         FROM SUPINFO LEFT JOIN receiverHeader ON UNIQSUPNO=senderId LEFT JOIN  receiverDetail ON  receiverDetail.receiverHdrId = receiverHeader.receiverHdrId
		                     WHERE (((@filterValue IS NULL OR @filterValue =' ' AND UNIQSUPNO=UNIQSUPNO) OR (@filterValue <> '' AND SUPNAME  LIKE '%' + @filterValue +'%'))
							          AND (@isIsnpection =1 AND  receiverDetail.isinspCompleted=1 and receiverDetail.isCompleted = 0 
									  OR  @isIsnpection = 0 AND receiverDetail.isinspCompleted=receiverDetail.isinspCompleted))
									      			ORDER BY Value -- Nilesh Sa 3/5/2018 Remove white spaces from selection columns
															OFFSET @pageNumber ROWS
															FETCH NEXT @pageSize ROWS ONLY;
       ELSE  IF(@filterType = 2)  --Get PO Number  
			 BEGIN
	               -- SET @filterValue = CASE WHEN @filterValue <> ' ' THEN dbo.PADL(@filterValue,15,0) else '' END
					SELECT DISTINCT dbo.fRemoveLeadingZeros(POMAIN.PONUM) AS Value,POMAIN.POUNIQUE AS Id
					      FROM POMAIN LEFT JOIN receiverHeader ON POMAIN.ponum=receiverHeader.ponum 
					                  LEFT JOIN  receiverDetail ON  receiverDetail.receiverHdrId = receiverHeader.receiverHdrId
		                     WHERE (((@filterValue IS NULL OR @filterValue ='' AND UNIQSUPNO=UNIQSUPNO) OR 
							          (@filterValue <> ' ' AND POMAIN.PONUM LIKE '%' + @filterValue +'%'))
							          AND (@isIsnpection =1 AND  receiverDetail.isinspCompleted=1 and receiverDetail.isCompleted = 0 
									  OR  @isIsnpection = 0 AND receiverDetail.isinspCompleted=receiverDetail.isinspCompleted)) AND POSTATUS <> 'NEW'
									      			ORDER BY dbo.fRemoveLeadingZeros(POMAIN.PONUM)
															OFFSET @pageNumber ROWS
															FETCH NEXT @pageSize ROWS ONLY;
			END

       ELSE  IF(@filterType = 3)  --Get Supplier Packing List
					SELECT DISTINCT RTRIM(LTRIM(receiverHeader.recPklNo))  AS Value,receiverHeader.receiverHdrId AS Id -- Nilesh Sa 3/5/2018 Remove white spaces from selection columns
					     , receiverHeader.dockDate FROM  receiverHeader INNER JOIN  receiverDetail ON  receiverDetail.receiverHdrId = receiverHeader.receiverHdrId
		                     WHERE (((ISNULL(@filterValue,'') = ' ' AND receiverHeader.recPklNo = receiverHeader.recPklNo) 
							          OR (@filterValue <> '' AND recPklNo  LIKE '%' + @filterValue +'%'))
							          AND (@isIsnpection =1 AND  receiverDetail.isinspCompleted=1 and receiverDetail.isCompleted = 0 
									  OR  @isIsnpection = 0 AND receiverDetail.isinspCompleted=receiverDetail.isinspCompleted))
									  AND recPklNo <> '' -- Nilesh Sa 2/27/2018 Avoid empty pack list number
									  AND inspectionSource = @inspectionSource  -- Nilesh Sa 2/28/2018 Added inspectionSource to distingwish PL number 
									      			ORDER BY receiverHeader.dockDate  desc
													 -- Nilesh Sa 3/5/2018 Remove white spaces from selection columns
													 -- Shiv P : 04/27/2018 Get data order by dockDate
															OFFSET @pageNumber ROWS 
															FETCH NEXT @pageSize ROWS ONLY;

       ELSE  IF(@filterType = 4)   --Get Part Number / Rev
					SELECT DISTINCT PART_NO,RTRIM(LTRIM(INVENTOR.PART_NO)) + '/' + RTRIM(LTRIM(REVISION))  AS Value, -- Nilesh Sa 3/5/2018 Remove white spaces from selection columns
					INVENTOR.UNIQ_KEY AS Id ,PART_NO AS Type ,REVISION AS Status 
					      FROM   INVENTOR LEFT JOIN receiverDetail ON  receiverDetail.Uniq_key = INVENTOR.UNIQ_KEY
						                   LEFT JOIN receiverHeader ON receiverDetail.receiverHdrId = receiverHeader.receiverHdrId
		                     WHERE (((@filterValue IS NULL OR @filterValue ='' AND INVENTOR.PART_NO = INVENTOR.PART_NO) 
							          OR (@filterValue <> '' AND RTRIM(LTRIM(INVENTOR.PART_NO)) + '/' + RTRIM(LTRIM(REVISION)) LIKE '%' + @filterValue +'%'))
							          AND (@isIsnpection =1 AND  receiverDetail.isinspCompleted=1 and receiverDetail.isCompleted = 0 
									  OR  @isIsnpection = 0 AND receiverDetail.isinspCompleted=receiverDetail.isinspCompleted))
									      			ORDER BY PART_NO
															OFFSET @pageNumber ROWS
															FETCH NEXT @pageSize ROWS ONLY;


       ELSE  IF(@filterType = 5)     --Get MFGR Part No.
					SELECT  DISTINCT RTRIM(LTRIM(MfgrMaster.mfgr_pt_no)) AS Value --,MfgrMaster.PartMfgr AS Id -- Nilesh Sa 3/5/2018 Remove white spaces from selection columns
					      FROM   MfgrMaster LEFT JOIN receiverDetail ON  receiverDetail.PartMfgr =  MfgrMaster.PartMfgr AND  receiverDetail.mfgr_pt_no = MfgrMaster.mfgr_pt_no
						                   LEFT JOIN receiverHeader ON receiverDetail.receiverHdrId = receiverHeader.receiverHdrId
		                     WHERE (((@filterValue IS NULL OR @filterValue ='' AND MfgrMaster.mfgr_pt_no = MfgrMaster.mfgr_pt_no) 
							          OR (@filterValue <> '' AND MfgrMaster.mfgr_pt_no LIKE '%' + @filterValue +'%'))
							          AND (@isIsnpection =1 AND  receiverDetail.isinspCompleted=1 and receiverDetail.isCompleted = 0 
									  OR  @isIsnpection = 0 AND receiverDetail.isinspCompleted=receiverDetail.isinspCompleted))
									      			ORDER BY Value
															OFFSET @pageNumber ROWS
															FETCH NEXT @pageSize ROWS ONLY;



   END