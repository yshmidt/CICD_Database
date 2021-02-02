CREATE TABLE [dbo].[CCONTACT] (
    [CID]                CHAR (10)        CONSTRAINT [DF__CCONTACT__CID__2942188C] DEFAULT ('') NOT NULL,
    [TYPE]               CHAR (1)         CONSTRAINT [DF__CCONTACT__TYPE__2A363CC5] DEFAULT ('') NOT NULL,
    [LASTNAME]           VARCHAR (50)     CONSTRAINT [DF__CCONTACT__LASTNA__2B2A60FE] DEFAULT ('') NOT NULL,
    [FIRSTNAME]          VARCHAR (50)     CONSTRAINT [DF__CCONTACT__FIRSTN__2C1E8537] DEFAULT ('') NOT NULL,
    [MIDNAME]            VARCHAR (50)     CONSTRAINT [DF__CCONTACT__MIDNAM__2D12A970] DEFAULT ('') NOT NULL,
    [NICKNAME]           VARCHAR (50)     CONSTRAINT [DF__CCONTACT__NICKNA__2E06CDA9] DEFAULT ('') NOT NULL,
    [IS_EDITED]          CHAR (3)         CONSTRAINT [DF__CCONTACT__IS_EDI__2EFAF1E2] DEFAULT ('') NOT NULL,
    [CUSTNO]             CHAR (10)        CONSTRAINT [DF__CCONTACT__CUSTNO__2FEF161B] DEFAULT ('') NOT NULL,
    [DEPARTMENT]         CHAR (35)        CONSTRAINT [DF__CCONTACT__DEPART__30E33A54] DEFAULT ('') NULL,
    [TITLE]              VARCHAR (50)     CONSTRAINT [DF__CCONTACT__TITLE__31D75E8D] DEFAULT ('') NOT NULL,
    [WORKPHONE]          VARCHAR (25)     CONSTRAINT [DF__CCONTACT__WORKPH__32CB82C6] DEFAULT ('') NOT NULL,
    [EMAIL]              VARCHAR (100)    CONSTRAINT [DF__CCONTACT__EMAIL__33BFA6FF] DEFAULT ('') NOT NULL,
    [CONTACTFAX]         VARCHAR (25)     CONSTRAINT [DF__CCONTACT__CONTAC__34B3CB38] DEFAULT ('') NOT NULL,
    [MOBILE]             VARCHAR (25)     CONSTRAINT [DF__CCONTACT__MOBILE__35A7EF71] DEFAULT ('') NOT NULL,
    [PAGER]              VARCHAR (25)     CONSTRAINT [DF__CCONTACT__PAGER__369C13AA] DEFAULT ('') NOT NULL,
    [HOMEPHONE]          VARCHAR (25)     CONSTRAINT [DF__CCONTACT__HOMEPH__379037E3] DEFAULT ('') NOT NULL,
    [STREET1]            VARCHAR (50)     CONSTRAINT [DF__CCONTACT__STREET__38845C1C] DEFAULT ('') NOT NULL,
    [STREET2]            VARCHAR (50)     CONSTRAINT [DF__CCONTACT__STREET__39788055] DEFAULT ('') NOT NULL,
    [CITY]               VARCHAR (25)     CONSTRAINT [DF__CCONTACT__CITY__3A6CA48E] DEFAULT ('') NOT NULL,
    [STATE]              CHAR (20)        CONSTRAINT [DF__CCONTACT__STATE__3B60C8C7] DEFAULT ('') NOT NULL,
    [ZIP]                CHAR (10)        CONSTRAINT [DF__CCONTACT__ZIP__3C54ED00] DEFAULT ('') NOT NULL,
    [COUNTRY]            CHAR (20)        CONSTRAINT [DF__CCONTACT__COUNTR__3D491139] DEFAULT ('') NOT NULL,
    [CONTACTDOB]         CHAR (5)         CONSTRAINT [DF__CCONTACT__CONTAC__3E3D3572] DEFAULT ('') NOT NULL,
    [SPOUSENAME]         CHAR (15)        CONSTRAINT [DF__CCONTACT__SPOUSE__3F3159AB] DEFAULT ('') NOT NULL,
    [ANIVERSARY]         CHAR (5)         CONSTRAINT [DF__CCONTACT__ANIVER__4119A21D] DEFAULT ('') NOT NULL,
    [AFFILIATN]          TEXT             CONSTRAINT [DF__CCONTACT__AFFILI__420DC656] DEFAULT ('') NOT NULL,
    [FOOD]               TEXT             CONSTRAINT [DF__CCONTACT__FOOD__4301EA8F] DEFAULT ('') NOT NULL,
    [SPORTS]             TEXT             CONSTRAINT [DF__CCONTACT__SPORTS__43F60EC8] DEFAULT ('') NOT NULL,
    [HOBBY]              TEXT             CONSTRAINT [DF__CCONTACT__HOBBY__44EA3301] DEFAULT ('') NOT NULL,
    [CONTNOTE]           TEXT             CONSTRAINT [DF__CCONTACT__CONTNO__45DE573A] DEFAULT ('') NOT NULL,
    [DIVISION]           CHAR (12)        CONSTRAINT [DF__CCONTACT__DIVISI__46D27B73] DEFAULT ('') NOT NULL,
    [PHOTO_PATH]         CHAR (50)        CONSTRAINT [DF__CCONTACT__PHOTO___47C69FAC] DEFAULT ('') NOT NULL,
    [REPTYPE]            CHAR (15)        CONSTRAINT [DF__CCONTACT__REPTYP__48BAC3E5] DEFAULT ('') NOT NULL,
    [STATUS]             CHAR (10)        CONSTRAINT [DF__CCONTACT__STATUS__49AEE81E] DEFAULT ('') NOT NULL,
    [modifiedDate]       DATETIME         NULL,
    [IsSynchronizedFlag] BIT              CONSTRAINT [DF__CCONTACT__IsSync__4C246DD1] DEFAULT ((0)) NULL,
    [FkUserId]           UNIQUEIDENTIFIER CONSTRAINT [DF__CCONTACT__FkUser__69409AC3] DEFAULT (NULL) NULL,
    [STREET3]            VARCHAR (50)     NULL,
    [STREET4]            VARCHAR (50)     NULL,
    [WRKEMAIL]           VARCHAR (100)    NULL,
    [EMRCONTACTNO]       VARCHAR (100)    NULL,
    [EMRCONTACT]         VARCHAR (25)     NULL,
    [EMPDOB]             SMALLDATETIME    NULL,
    [SPOUSEPHONE]        VARCHAR (25)     NULL,
    [URL]                VARCHAR (MAX)    CONSTRAINT [DF__CCONTACT__URL__1460CE49] DEFAULT ('') NOT NULL,
    [PEERNAME]           VARCHAR (50)     CONSTRAINT [DF__CCONTACT__PEERNA__1554F282] DEFAULT ('') NOT NULL,
    [PEERTITLE]          VARCHAR (50)     CONSTRAINT [DF__CCONTACT__PEERTI__164916BB] DEFAULT ('') NOT NULL,
    [PEERPHONE]          VARCHAR (25)     CONSTRAINT [DF__CCONTACT__PEERPH__173D3AF4] DEFAULT ('') NOT NULL,
    [PEEREMAIL]          VARCHAR (100)    CONSTRAINT [DF__CCONTACT__PEEREM__18315F2D] DEFAULT ('') NOT NULL,
    [IsFavourite]        BIT              CONSTRAINT [DF__CCONTACT__IsFavo__19258366] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [CCONTACT_PK] PRIMARY KEY CLUSTERED ([CID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CUSTNO]
    ON [dbo].[CCONTACT]([CUSTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [FCID]
    ON [dbo].[CCONTACT]([FIRSTNAME] ASC, [CID] ASC);


GO
CREATE NONCLUSTERED INDEX [LASTNAME]
    ON [dbo].[CCONTACT]([LASTNAME] ASC, [FIRSTNAME] ASC);


GO
CREATE NONCLUSTERED INDEX [LCID]
    ON [dbo].[CCONTACT]([LASTNAME] ASC, [CID] ASC);


GO
-- =============================================  
-- Author:  Shripati U  
-- Create date: 08/27/2017  
-- Description: insert trigger for insert data into aspnet_user, aspnet_profile and aspnet_membership table when data is inserted into ccontact  
-- 09/15/2017 Shripati change where condition for filter user  
-- 10/5/2017 Ravi : Removed Hrtype columns and set default and HRtype to full time  
-- 11/15/2017 Shripati : Removed the default HRtype as 'full time' and set 'customer' and 'supplier' with respective Type. To handle exception added try catch block.  
-- 06/14/2018 Shripati U: To save the password in encrypted format     
-- 07/12/2018 Shripati U: While creating new contact created new @UserId insted of used FkUserId to handle null values   
-- 09/04/2019 Sachin B : Sachin Added veriable @isUserIdInserted to check null userid entered in ccontact table or not       
-- 09/04/2019 Sachin B : Sachin use @UserId veriable conditionaly, if user entered in ccontact table use same value here if it is null then use newid() assigned  
-- 12/19/2019 Sachin B : Sachin B Add Cursur for the Inserting Multiple contact at a time
-- 01/09/2020 Sachin B : Sachin B Change the position of FETCH NEXT FROM CContact_cursor from inside IF @Type ='C' OR @Type ='S' condition to outside the if.Due to @Type ='E' doesn't matched and loop will exexute within if 
-- 04/10/2020 Sachin B : Add convert function to save encrypted value as it is
-- =============================================  
CREATE TRIGGER [dbo].[CCONTACT_Insert] ON [dbo].[CCONTACT]  
FOR INSERT  
AS  

DECLARE @ApplicationId UNIQUEIDENTIFIER, @Type CHAR, @UserId UNIQUEIDENTIFIER=null,@cid CHAR(10),
	    @ErrorMsg VARCHAR(MAX), @ErrorNumber INT, @ErrorProc sysname, @ErrorLine INT     

BEGIN TRY -- Shripati U :To handle exception added try catch block.     
BEGIN TRANSACTION  

-- 12/19/2019 Sachin B : Sachin B Add Cursur for the Inserting Multiple contact at a time
DECLARE CContact_cursor CURSOR FAST_FORWARD 
FOR SELECT TYPE, FkUserId, CID
FROM INSERTED

OPEN CContact_cursor  
FETCH NEXT FROM CContact_cursor    
INTO @Type,@UserId,@cid

--SELECT @Type=TYPE,@UserId=FkUserId,@cid=CID FROM inserted  
WHILE @@FETCH_STATUS = 0    
BEGIN  	
	-- 09/04/2019 Sachin B : Sachin Added veriable @isUserIdInserted to check null userid entered in ccontact table or not           
	DECLARE  @isUserIdInserted UNIQUEIDENTIFIER = @UserId   
  
	IF @Type ='C' OR @Type ='S' -- 09/15/2017 Shripati U: Change where condition for filter user  
	BEGIN 	 
		SET XACT_ABORT ON 		 			
		SELECT @ApplicationId = ApplicationId  from aspnet_Applications where ApplicationName='Manex'  

		IF @UserId IS NULL     
		BEGIN   
			-- 07/12/2018 Shripati U: While creating new contact created new @UserId insted of used FkUserId to handle null values      
			SET @UserId =NEWID()  
			UPDATE CCONTACT SET FkUserId=@UserId WHERE CID=@cid  
		END  
		-- 07/12/2018 Shripati U: While creating new contact created new @UserId insted of used FkUserId to handle null values      
		INSERT INTO aspnet_users (ApplicationId,UserId,UserName,LoweredUserName,IsAnonymous,LastActivityDate)  
		SELECT @ApplicationId ,  
			--@UserId  
		-- 09/04/2019 Sachin B : Sachin use @UserId veriable conditionaly, if user entered in ccontact table use same value here if it is null then use newid() assigned  
		CASE WHEN (@isUserIdInserted IS NULL ) THEN @UserId ELSE Contact.FkUserId END,  
		dbo.fn_GetValidUserName(Contact.CID) ,LOWER(dbo.fn_GetValidUserName(Contact.CID)),0,   
		ISNULL(Contact.modifiedDate,GETDATE())   
		FROM inserted Contact  WHERE CID = @cid  
  
		-- insert CCONTACT data into the aspnet_Profile  
		INSERT INTO [dbo].[aspnet_Profile]([UserId],[LastUpdatedDate]  
				,[FirstName],[LastName],[Midname],[Department],  
			[AcctAdmin],[CompanyAdmin],[externalEmp],[ProdAdmin],[minuteLimit],[LicenseType],title,photoPath, nickname,[isbuyer]  
				,[frstAmtInvtApproved],[finalAmtInvtApproved],[frstAmtNonInvtApproved],[finalAmtNonInvtApproved],[LanguageId],[ITARrestricted]  
				,[STATUS],[HRType],[ScmAdmin],[CrmAdmin]  
			)  
  
		SELECT    
		--@UserId  
		-- 09/04/2019 Sachin B : Sachin use @UserId veriable conditionaly, if user entered in ccontact table use same value here if it is null then use newid() assigned  
		CASE WHEN (@isUserIdInserted IS NULL ) THEN @UserId ELSE Contact.FkUserId END   
		,modifiedDate,FIRSTNAME,LASTNAME,MIDNAME,DEPARTMENT,0,0,1,0,30  
		,CASE WHEN TYPE='C' THEN 'customer' WHEN TYPE='S' THEN 'supplier' END,TITLE,PHOTO_PATH,NICKNAME,0,  
		0,0,0,0,1,0,STATUS,CASE WHEN TYPE='C' THEN 'customer' WHEN TYPE='S' THEN 'supplier' END,0,0  -- 10/5/2017 Ravi : Removed Hrtype columns and set default HRtype to full time   
		from inserted Contact WHERE CID = @cid  -- 09/15/2017 Shripati: change where condition for filter user   
		 
		-- 11/15/2017 Shripati : Removed the default HRtype as 'full time' and set 'customer' and 'supplier' with respective Type   
		DECLARE @salt UNIQUEIDENTIFIER=NEWID()  

		-- insert CCONTACT data into the aspnet_Membership  
		INSERT INTO aspnet_Membership (ApplicationId,UserId,Email,LoweredEmail,Password,PasswordFormat,PasswordSalt,IsApproved,IsLockedOut  
		,CreateDate,LastLoginDate,LastPasswordChangedDate,LastLockoutDate,FailedPasswordAttemptCount,FailedPasswordAttemptWindowStart  
		,FailedPasswordAnswerAttemptCount,FailedPasswordAnswerAttemptWindowStart)  
		SELECT @ApplicationId,  
		--@UserId,  
		-- 09/04/2019 Sachin B : Sachin use @UserId veriable conditionaly, if user entered in ccontact table use same value here if it is null then use newid() assigned  
		CASE WHEN (@isUserIdInserted IS NULL ) THEN @UserId ELSE Contact.FkUserId END,   
		Contact.Email,  
		LOWER(Contact.Email),  
		-- 06/14/2018 Shripati U: To save the password in encrypted format  
		--HASHBYTES('SHA1', 'default'+CAST(N'' as xml).value('xs:base64Binary(sql:variable("@salt"))', 'varchar(max)')),  
		-- 04/10/2020 Sachin B : Add convert function to save encrypted value as it is
		CONVERT(nvarchar(128),HASHBYTES('SHA1', 'default'+CAST(@salt as nvarchar(128))),2),  
		2,  
		-- 06/14/2018 Shripati U: To save the passwordSalt in encrypted format  
		--CAST(N'' as xml).value('xs:base64Binary(sql:variable("@salt"))', 'varchar(max)')  
		-- 04/10/2020 Sachin B : Add convert function to save encrypted value as it is
		CONVERT(nvarchar(128),HASHBYTES('SHA1',CAST(@salt as nvarchar(128))),2) 
		,1,0,  
		ISNULL(Contact.modifiedDate,GETDATE()),ISNULL(Contact.modifiedDate,GETDATE()),ISNULL(Contact.modifiedDate,GETDATE()),  
		ISNULL(Contact.modifiedDate,GETDATE()),0,ISNULL(Contact.modifiedDate,GETDATE()),0,ISNULL(Contact.modifiedDate,GETDATE())  
		FROM inserted Contact WHERE CID = @cid  
			
 END 
 -- 01/09/2020 Sachin B : Sachin B Change the position of FETCH NEXT FROM CContact_cursor from inside IF @Type ='C' OR @Type ='S' condition to outside the if.Due to @Type ='E' doesn't matched and loop will exexute within if 
		FETCH NEXT FROM CContact_cursor    
		INTO @Type,@UserId,@cid   
	END  	

CLOSE CContact_cursor;    
DEALLOCATE CContact_cursor; 
 
COMMIT TRANSACTION  
END TRY   
BEGIN CATCH  
	IF @@TRANCOUNT > 0  
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorProc = ERROR_PROCEDURE(), @ErrorLine = ERROR_LINE();  
		RAISERROR (@ErrorMsg,16,1);  
	ROLLBACK TRANSACTION ;  
	RETURN  
END CATCH  
GO
-- =============================================
-- Author:		Sachin shevale
-- Create date: <09/01/2010>
-- Description:	<Delete trigger to make sure CCONTACT deleted as well>
CREATE TRIGGER [dbo].[CCONTACT_Delete] 
   ON  [dbo].[CCONTACT]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	BEGIN TRANSACTION		
	 DELETE FROM CCONTACT WHERE CID in (SELECT CID FROM Deleted)
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'CCONTACT'
           ,'CID'
           ,Deleted.CID from Deleted
		   WHERE custno<>' '			  
		 
	COMMIT
END
GO
-- =============================================
-- Author:		Yelena SHmidt
-- Create date: 04/24/2014
-- Description:	Update trigger for CContact table. Save date/time when modified
--09/24/15-Sachin s- The above code return error if multiple records are updated and Inserted return more than one result 
--09-24-2015 update IsSynchronizedFlag set 0 other service not pick the reocrds
-- =============================================
CREATE TRIGGER [dbo].[CCONTACT_UPDATE]
   ON  [dbo].[CCONTACT]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	UPDATE CCONTACT SET modifiedDate = GETDATE(),
    -- Insert statements for trigger here
	 IsSynchronizedFlag= 
						CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
					    WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1
						--09-24-2015 update IsSynchronizedFlag set 0 other service not pick the reocrds
						ELSE 0 END					
					FROM inserted I inner join deleted D on i.CID=d.CID
					where I.CID =CCONTACT.CID  
		----08/28/15 - delete records from SynchronizationMultiLocationLog table if uniquenum exists while update the record
		--  --Check IsSynchronizedFlag is zero 
		--  IF((SELECT IsSynchronizedFlag FROM inserted) = 0)
		--    BEGIN
		--	--Delete the Unique num from SynchronizationMultiLocationLog table if exists  with same UNIQ_KEY so all location pick again
		--	 DELETE sml FROM SynchronizationMultiLocationLog sml 
		--	  INNER JOIN CCONTACT ctc on sml.UniqueNum=ctc.CID
		--		where ctc.CID =sml.UniqueNum 					
		--	END
		--09/24/15-Sachin s- The above code return error if multiple records are updated and Inserted return more than one result 
			IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.CID=SynchronizationMultiLocationLog.Uniquenum);
			END					
END