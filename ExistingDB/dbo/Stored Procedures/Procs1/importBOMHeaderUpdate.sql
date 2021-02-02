-- =============================================    
-- Author:  David Sharp    
-- Create date: 4/18/2012    
-- Description: update import Header    
-- 11/14/13 DS Added @userId param to allow for customer check on the final HeaderGet    
-- 7/31/15 Raviraj Added useSetUp and StdBldQty in importBomheader table for Assembly    
-- 09/17/15 DS expanded assembly revision field length    
-- 10/15/18 YS part_no is 35 characters not 23    
-- 01/21/2019 Sachin B Update the Customer if the BOM_Det Table Don't have component  
-- 05/21/2019 Vijay G Convert @completedBy varchar to uniqueidentifier
-- =============================================    
CREATE PROCEDURE [dbo].[importBOMHeaderUpdate]     
 -- Add the parameters for the stored procedure here   
 -- 05/21/2019 Vijay G Convert @completedBy varchar to uniqueidentifier 
 @importId uniqueidentifier, @partSource varchar(10), @status varchar(10),@completeDate smalldatetime = '',@completedBy uniqueidentifier = NULL,@custNo varchar(10),    
 -- 10/15/18 YS part_no is 35 characters not 23    
 @assyNo varchar(35),@assyRev varchar(8),@assyDesc varchar(45),@partClass varchar(8),@partType varchar(8),@uniq_key varchar(10) = '',@useSetUp bit, @stdBldQty numeric(8,0),    
 @userId uniqueidentifier=null    
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
    
    -- Insert statements for procedure here    
/* Check to see if complete date is provided, if not, keep it at the current value. */    
IF @completeDate = '' SELECT @completeDate = completeDate, @completedBy=completedBy FROM [importBOMHeader] WHERE importId = @importId    
        
/* Match existing records */    
DECLARE @eUniq_key varchar(10),@eCustno varchar(10),@msg varchar(MAX)=''   
   
SELECT @eUniq_key=UNIQ_KEY FROM INVENTOR WHERE rtrim(ltrim(PART_NO))=rtrim(ltrim(@assyNo))AND rtrim(ltrim(REVISION))=rtrim(ltrim(@assyRev)) AND CUSTNO=''    
  
IF @eUniq_key<>''   
BEGIN  
 SELECT   
    @partSource=PART_SOURC,  
    @assyDesc=DESCRIPT,  
    @partClass=PART_CLASS,  
    @partType=PART_TYPE,  
    @uniq_key=@eUniq_key,  
    @eCustno=BOMCUSTNO   
 FROM INVENTOR   
 WHERE UNIQ_KEY=@eUniq_key    
END  
  
 -- 01/21/2019 Sachin B Update the Customer if the BOM_Det Table Don't have component  
 DECLARE @count INT = (SELECT COUNT(*) FROM BOM_DET WHERE BOMPARENT =@eUniq_key)  
  
SELECT   
   @eUniq_key=INT_UNIQ   
   FROM INVENTOR   
   WHERE rtrim(ltrim(CUSTPARTNO))=rtrim(ltrim(@assyNo))AND rtrim(ltrim(CUSTREV))=rtrim(ltrim(@assyRev))    
  
IF @eUniq_key<>''   
BEGIN  
   SELECT   
    @partSource=PART_SOURC,  
    @assyDesc=DESCRIPT,  
    @partClass=PART_CLASS,  
    @partType=PART_TYPE,  
    @uniq_key=@eUniq_key,  
    @eCustno=BOMCUSTNO   
   FROM INVENTOR   
   WHERE UNIQ_KEY=@eUniq_key    
END  
   
 IF @eCustno<>'' AND @custNo<>@eCustno AND @eCustno<>'000000000~' AND @count > 0   
 BEGIN    
  SET @custNo=@eCustno     
  SET @msg='Assembly and Rev exist under another customer.  Assigned customer was adjusted.'    
 END   
   
    
 IF @eUniq_key='' OR @eUniq_key is null SET @uniq_key=''    
 SELECT @eUniq_key    
 --select *  from INVENTOR where PART_SOURC='make'     
      
    -- 7/31/15 Raviraj Added useSetUp and StdBldQty in importBomheader table for Assembly    
 UPDATE [dbo].[importBOMHeader]    
    SET [source] = @partSource    
    ,[status] = @status    
    ,[completeDate] = @completeDate    
    ,[completedBy] = @completedBy    
    ,[custNo] = @custNo    
    ,[assyNum] = @assyNo    
    ,[assyRev] = @assyRev    
    ,[assyDesc] = @assyDesc    
    ,[partClass] = @partClass    
    ,[partType] = @partType    
    ,[uniq_key] = @uniq_key    
    ,[message] = @msg    
    ,[useSetUp] = @useSetUp    
    ,[stdBldQty] = @stdBldQty    
  WHERE importId = @importId    
      
 EXEC importBOMHeaderGet @importId, @userId    
END