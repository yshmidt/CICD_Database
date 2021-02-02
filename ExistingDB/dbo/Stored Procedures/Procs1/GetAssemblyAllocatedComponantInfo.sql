-- =============================================
-- Author:		Sachin B
-- Create date: 11/17/2016
-- Description:	this procedure will be called from the SF module and get Allocated componant List to Assembly Serial
-- [dbo].[GetAssemblyAllocatedComponantInfo] '0000000517' , '','','',null,'S0FQLC4D5V'
-- 11/26/16 Sachin b Add part No With Revision column and order by PART_NO,LOTCODE,IpkeyUnique,SerialNo clause and remove leading zero of serial no
-- 06/19/2017 Sachin b Add Parameter @LotCode,@Reference,@PoNum,@ExpDate,@IpKeyUnique and Add in where clause
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================


CREATE PROCEDURE [dbo].[GetAssemblyAllocatedComponantInfo] 
	-- Add the parameters for the stored procedure here
	@wono CHAR(10),
	--02/09/18 YS changed size of the lotcode column to 25 char
	@LotCode nvarchar(25),
	@Reference CHAR(12),
	@PoNum CHAR(15),
	@ExpDate SMALLDATETIME,
	@IpKeyUnique CHAR(10)
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
      --- 11/26/16 Sachin b Add part No With Revision column and order by PART_NO,LOTCODE,IpkeyUnique,SerialNo clause
	  SELECT serialuniq as AssemblySerialUniq,dbo.fRemoveLeadingZeros(serialno) as AssemblySerialNo,CompToAssemblyUk,assem.uniq_key,Wono,Isnull(PartIpkeyUnique,'') as IpkeyUnique,Isnull(PartSerialUnique,'') as SerialUnique,
	  SUBSTRING(Isnull(PartSerialNo,''), PATINDEX('%[^0]%', Isnull(PartSerialNo,'')+'.'), LEN(Isnull(PartSerialNo,''))) as SerialNo,
	  QTYISU ,LOTCODE,EXPDATE,REFERENCE,PONUM,i.PART_NO as PartNo,
	  case COALESCE(NULLIF(i.REVISION,''), '')
	When '' Then  LTRIM(RTRIM(i.PART_NO)) 
	Else LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION 
	END as PartNoWithRev
	  FROM SerialComponentToAssembly assem
	  inner join inventor i on i.UNIQ_KEY = assem.uniq_key
	  -- 06/19/2017 Sachin b Add Parameter @LotCode,@Reference,@PoNum,@ExpDate,@IpKeyUnique and Add in where clause
	  WHERE Wono = @wono and PartIpkeyUnique =@IpKeyUnique and LOTCODE =@LotCode and isnull(EXPDATE,1)=isnull(@ExpDate,1) and REFERENCE=@Reference	and PONUM=@PoNum
	  order by PART_NO,LOTCODE,IpkeyUnique,SerialNo  	   
END