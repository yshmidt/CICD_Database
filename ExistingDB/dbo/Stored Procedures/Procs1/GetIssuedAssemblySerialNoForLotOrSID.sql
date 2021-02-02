-- =============================================
-- Author:		Sachin B
-- Create date: 09/11/2016
-- Description:	this procedure will be called from the SF module and get all issued assembly Serial no for lots
-- [dbo].[GetIssuedAssemblySerialNoForLotOrSID] '0000000556','_1EP0LM58C','',null,'',''
-- [dbo].[GetIssuedAssemblySerialNoForLotOrSID] '0000000555','_1EI0NK1ZM','',null,'','',1,'GF029IQ7HG'
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================

CREATE PROCEDURE [dbo].[GetIssuedAssemblySerialNoForLotOrSID] 
	-- Add the parameters for the stored procedure here
	@Wono char(10),
	@UniqKey char(10),
	--02/09/18 YS changed size of the lotcode column to 25 char
	@LotCode nvarchar(25),	
	@ExpDate SMALLDATETIME,	
	@Reference CHAR(12),	
	@PoNum CHAR(15),
	@IsSID bit,
	@IpKeyUniq char(10)
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

IF(@IsSID =0)
	BEGIN
		SELECT serialuniq as AssemblySerialUniq,serialno as AssemblySerialNo,CompToAssemblyUk,assem.uniq_key,Wono,Isnull(PartIpkeyUnique,'') as IpkeyUnique,
		Isnull(PartSerialUnique,'') as SerialUnique,SUBSTRING(Isnull(PartSerialNo,''), PATINDEX('%[^0]%', Isnull(PartSerialNo,'')+'.'), LEN(Isnull(PartSerialNo,''))) as SerialNo,
			  QTYISU ,LOTCODE,EXPDATE,REFERENCE,PONUM,i.PART_NO as PartNo,
			  case COALESCE(NULLIF(i.REVISION,''), '')
			When '' Then  LTRIM(RTRIM(i.PART_NO)) 
			Else LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION 
			END as PartNoWithRev
		FROM SerialComponentToAssembly assem 
		inner join inventor i on i.UNIQ_KEY = assem.uniq_key
		Where WONO = @Wono and assem.uniq_key = @UniqKey and LOTCODE = @LotCode and REFERENCE =@Reference and Isnull(EXPDATE,1) = Isnull(@ExpDate,1) and PONUM = @PoNum and QTYISU > 0
	END
ELSE
	BEGIN
	   SELECT serialuniq as AssemblySerialUniq,serialno as AssemblySerialNo,CompToAssemblyUk,assem.uniq_key,Wono,Isnull(PartIpkeyUnique,'') as IpkeyUnique,
		Isnull(PartSerialUnique,'') as SerialUnique,SUBSTRING(Isnull(PartSerialNo,''), PATINDEX('%[^0]%', Isnull(PartSerialNo,'')+'.'), LEN(Isnull(PartSerialNo,''))) as SerialNo,
			  QTYISU ,LOTCODE,EXPDATE,REFERENCE,PONUM,i.PART_NO as PartNo,
			  case COALESCE(NULLIF(i.REVISION,''), '')
			When '' Then  LTRIM(RTRIM(i.PART_NO)) 
			Else LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION 
			END as PartNoWithRev
		FROM SerialComponentToAssembly assem 
		inner join inventor i on i.UNIQ_KEY = assem.uniq_key
		Where WONO = @Wono and assem.uniq_key = @UniqKey and LOTCODE = @LotCode and REFERENCE =@Reference and Isnull(EXPDATE,1) = Isnull(@ExpDate,1) and PONUM = @PoNum and PartIpkeyUnique = @IpKeyUniq and  QTYISU > 0
	END
END