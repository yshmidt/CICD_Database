-- =============================================    
-- Author:  Satish B    
-- Create date: 7/05/2018    
-- Description: Update PO Upload address detail    
-- Modified: Vijay G 07/18/2019 Change address type value Invoice to InvAdd and update IlinkAdd  
-- =============================================    
CREATE PROCEDURE [dbo].[ImportPOAddressUpdate]    
 -- Add the parameters for the stored procedure here    
      @importId uniqueidentifier    
   ,@moduleId varchar(10)=''    
   ,@addressType varchar(10)=''    
   ,@iLink varchar(10)=''    
   ,@cLink varchar(10)=''    
   ,@bLink varchar(10)=''    
   ,@rLink varchar(10)=''    
   ,@shipVia varchar(20)=''    
   ,@fob varchar(20)=''    
   ,@shipCharge varchar(20)=''    
   ,@ShipChrgAmt varchar(20)=''    
   ,@Is_ScTax bit=0    
   ,@Sc_TaxPct varchar(20)=''    
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
    
    -- Insert statements for procedure here    
    DECLARE @iLinkId uniqueidentifier,@cLinkId uniqueidentifier,@bLinkId uniqueidentifier,@rLinkId uniqueidentifier,@shipViaId uniqueidentifier,@fobId uniqueidentifier,    
   @shipChargeId uniqueidentifier,@Is_ScTaxId uniqueidentifier,@Sc_TaxPctId uniqueidentifier    
     
 DECLARE @user varchar(10)='03user'    
     
 --Update ImportPOMain table address fields    
 IF (@addressType='RcvAdd')    
  BEGIN    
   UPDATE ImportPOMain SET     
     ILINK=@iLink,    
     BLINK=@bLink,    
     ShipVia=@shipVia,    
     ShipCharge=@shipCharge,    
     Fob=@fob,    
     ShipChgAMT=@ShipChrgAmt,    
     Sc_TaxPct=@Sc_TaxPct,    
     IS_SCTAX=@Is_ScTax    
   WHERE POImportId=@importId    
        END    
     ELSE IF (@addressType='RemmitAdd')    
  BEGIN    
   UPDATE ImportPOMain SET     
     CLINK=@cLink,    
     RLINK=@rLink    
   WHERE POImportId=@importId    
        END    
-- Modified:  Vijay G 07/18/2019 Change address type value Invoice to InvAdd and update IlinkAdd  
  ELSE IF (@addressType='InvAdd')    
  BEGIN    
   UPDATE ImportPOMain SET     
     ILINK=@iLink    
   WHERE POImportId=@importId    
        END     
    
 --Get ID values for each field type     
 SELECT @shipChargeId =fieldDefId    FROM ImportFieldDefinitions  WHERE fieldName = 'SHIPCHARGE' AND ModuleId=@moduleId    
 SELECT @fobId   =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'FOB'   AND ModuleId=@moduleId    
 SELECT @shipViaId  =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'SHIPVIA'  AND ModuleId=@moduleId    
     
 --Update fields with new values    
 UPDATE ImportPODetails SET adjusted = @shipCharge,[status]='',[validation]=@user,[message]='' WHERE fkFieldDefId = @shipChargeId AND fkPOImportId = @importId AND adjusted<>@shipCharge    
 UPDATE ImportPODetails SET adjusted = @fob,[status]='',[validation]=@user,[message]=''   WHERE fkFieldDefId = @fobId AND fkPOImportId = @importId AND adjusted<>@fob    
 UPDATE ImportPODetails SET adjusted = @shipVia,[status]='',[validation]=@user,[message]=''  WHERE fkFieldDefId = @shipViaId AND fkPOImportId = @importId AND adjusted<>@shipVia    
     
 --Recheck Validations    
 EXEC ImportPOVldtnCheckValues @importId    
END 