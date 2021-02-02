CREATE TABLE [dbo].[WFRequest] (
    [WFRequestId] CHAR (10)        NOT NULL,
    [ModuleId]    INT              NOT NULL,
    [RequestDate] SMALLDATETIME    NOT NULL,
    [RequestorId] UNIQUEIDENTIFIER NOT NULL,
    [WFComplete]  BIT              NOT NULL,
    [RecordId]    VARCHAR (MAX)    NOT NULL,
    [IsDeleted]   BIT              NULL,
    [IsCancel]    BIT              CONSTRAINT [DF__WFRequest__IsCan__6116FFC4] DEFAULT ('0') NULL,
    CONSTRAINT [PK_WFRequest] PRIMARY KEY CLUSTERED ([WFRequestId] ASC)
);


GO

-------------------------------------------------------------------------
-- Author	   : Satish B 
-- Create date : 12/10/2018
-- Description : Create trigger to update the tables by query
-------------------------------------------------------------------------
CREATE TRIGGER [dbo].[WFRequest_Update]
	ON [dbo].[WFRequest]
    AFTER UPDATE
AS
BEGIN

  SET NOCOUNT ON
	DECLARE @poNum VARCHAR(20), @wfReqId VARCHAR(20),  @wfComplete BIT, @query NVARCHAR(MAX)

	SELECT @wfReqId = WFRequestId ,@wfComplete =WFComplete ,@poNum =RecordId FROM inserted

	IF(@wfComplete =1)
	   BEGIN
			SELECT @query = source FROM MnxWFMetaData join WFRequest 
						    on MnxWFMetaData.ModuleId=  WFRequest.ModuleId 
							WHERE  WFRequest.WFRequestId =  @wfReqId
			SET @query = @query +''''+@wfReqId +''''
			EXECUTE sp_executesql @query
	   END
END




--When PO is approved then updated the table WFrequest and add new column into MnxWFMetaData
-- ALTER TABLE MnxWFMetaData ADD [Source] VARCHAR(500); 
--(Added)
--update MnxWFMetaData  set Source = N'UPDATE POMAIN SET POSTATUS = ''OPEN'', PONUM=  REPLACE(LEFT(wt.RECORDID,1),''T'',''0'')+RIGHT(wt.RECORDID,Len(wt.RECORDID)-1) FROM POMAIN JOIN WFREQUEST wt ON POMAIN.PONUM = wt.RECORDID WHERE wt.WFREQUESTID ='
--update MnxWFMetaData set Source='UPDATE ECMAIN SET ECStatus= ''Approved Internally'' FROM ECMAIN JOIN WFREQUEST wt ON ECMAIN.ECONO = wt.RECORDID WHERE wt.WFREQUESTID =' where MetaDataName='ECO'
GO
-------------------------------------------------------------------------
-- Author:		Satish B 
--Create date: 12/10/2018
--Description:	Create trigger to update the tables by query
-------------------------------------------------------------------------
CREATE TRIGGER [dbo.[WFRequest_Update]
	ON [dbo].[WFRequest]
    AFTER UPDATE
AS
BEGIN

  SET NOCOUNT ON
	DECLARE @poNum VARCHAR(20), @wfReqId VARCHAR(20),  @wfComplete BIT, @query NVARCHAR(MAX)

	SELECT @wfReqId = WFRequestId ,@wfComplete =WFComplete ,@poNum =RecordId FROM inserted

	IF(@wfComplete =1)
	   BEGIN
			SELECT @query =source FROM MnxWFMetaData   join WFRequest on  MnxWFMetaData.ModuleId=  WFRequest.ModuleId WHERE  WFRequest.WFRequestId =  @wfReqId
			SET @query = @query +''''+@wfReqId +''''
			EXECUTE sp_executesql @query
	   END
END



