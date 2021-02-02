-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/15/2013
-- Description:	Purchase Order Default information
-- =============================================
CREATE PROCEDURE [dbo].[GetPurchaseDefault] 
	-- Add the parameters for the stored procedure here
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [DEFOVRG]
      ,[TIMEOUTDOC]
      ,[LINKOUT]
      ,[SIGNATURES]
      ,[LOWGL]
      ,[HIGL]
      ,[LASTTEMPNO]
      ,[NUMOFCOPY]
      ,[AUTODMR]
      ,[LASTDMR]
      ,[LASTPLN]
      ,[APPRVVALUE]
      ,[APPRVDATE]
      ,[LINSAVE]
      ,[LINSAVEDT]
      ,[LINSAVEINFO]
      ,[ISDOCK]
      ,[LAVLCHANGEUPONREC]
      ,[NDEARLYREC]
      ,[AUTOAPPR4UPLOAD]
      ,[LASSIGNNEWCO]
      ,[LALLOWPARTSCHD]
      ,[LPRINTEACHRECEIPT]
      ,[LPRINTIPKEYLBL]
      ,[CIPKEYLBLSIZE]
      ,[NIPKEYLBL]
      ,[LPRINTBOMADDENDUM]
      ,[NLASTRECEIVTRANSNO]
      ,[UNIQUEREC]
  FROM [PODEFLTS]
END
