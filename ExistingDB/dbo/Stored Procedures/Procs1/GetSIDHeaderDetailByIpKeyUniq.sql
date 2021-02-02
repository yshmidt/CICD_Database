-- =============================================
-- Author:Satish B
-- Create date: 01/19/2017
-- Description:	Get Header Details against SID 
-- GetSIDHeaderDetailByIpKeyUniq '8WMFIOXDHV'  
-- Modified : 05/11/2017 Satish B: Display slash(/) conditionally. If the Revision is exist then display slash between partno and revision else display blank
--          : 09/08/2020 Shivshankar P : Change the INNER JOIN to LEFT JOIN with the PARTTYPE table
-- =============================================
CREATE PROCEDURE GetSIDHeaderDetailByIpKeyUniq
	@ipKeyUniq AS char(10)
AS
DECLARE @IsIpKeyExist varchar(20),@RETURN_VALUE nvarchar(200)
BEGIN
    SET NOCOUNT ON;
	SELECT @IsIpKeyExist=IPKEY.IPKEYUNIQUE FROM IPKEY WHERE IPKEYUNIQUE=@ipKeyUniq
	IF(@IsIpKeyExist IS NOT NULL AND LEN(@IsIpKeyExist) > 0)
		BEGIN
			SELECT DISTINCT
			--05/11/2017 Satish B: Display slash(/) conditionally. If the Revision is exist then display slash between partno and revision else display blank
			  RTRIM(inventor.PART_NO) + CASE WHEN inventor.REVISION IS NULL OR inventor.REVISION='' THEN '' ELSE '/' END + inventor.REVISION AS PARTREV
			 ,inventor.REVISION
			 ,inventor.PART_CLASS
			 ,inventor.PART_TYPE
			 ,inventor.DESCRIPT
			 ,inventor.SERIALYES
			 ,inventor.USEIPKEY
			 ,inventor.UNIQ_KEY
			 ,rcvheader.PONUM
			 ,procdtl.PORECPKNO
			 ,procdtl.RECEIVERNO
			 ,ISNULL(parttype.LOTDETAIL, 0) AS LOTDETAIL
			 ,ipkey.LOTCODE
			 ,ipkey.REFERENCE
			 ,ipkey.EXPDATE
			 ,ipkey.PKGBALANCE
			 ,ipkey.UNIQMFGRHD
			FROM INVENTOR inventor
			INNER JOIN IPKEY ipkey ON ipkey.UNIQ_KEY=inventor.UNIQ_KEY
			-- 09/08/2020 Shivshankar P : Change the INNER JOIN to LEFT JOIN with the PARTTYPE table
			LEFT JOIN PARTTYPE parttype ON parttype.PART_TYPE=inventor.PART_TYPE
			INNER JOIN receiverDetail rcvdtl ON rcvdtl.Uniq_key=inventor.UNIQ_KEY
			INNER JOIN receiverHeader rcvheader  ON rcvheader.receiverHdrId=rcvdtl.receiverHdrId
            INNER JOIN PORECDTL procdtl ON procdtl.receiverdetId=rcvdtl.receiverDetId AND  procdtl.uniqrecdtl=ipkey.RecordId  
			WHERE ipkey.IPKEYUNIQUE=@ipKeyUniq
		END
	ELSE
		BEGIN
			SET @RETURN_VALUE = 'SID does not exist'
			RAISERROR (@RETURN_VALUE, 11,1)
		END
END	

