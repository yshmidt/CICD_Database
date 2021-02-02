CREATE TABLE [dbo].[aspmnx_ActiveUsers] (
    [sessionId]        VARCHAR (50)     NOT NULL,
    [fkuserId]         UNIQUEIDENTIFIER NOT NULL,
    [lastActivityDate] DATETIME         NOT NULL,
    [workstationId]    VARCHAR (MAX)    NULL,
    [lastModule]       VARCHAR (50)     NULL,
    [ipaddress]        VARCHAR (50)     NULL,
    [oldsessionId]     VARCHAR (50)     CONSTRAINT [DF_aspmnx_ActiveUsers_oldsessionId] DEFAULT ('') NOT NULL,
    [pkActiveUsers]    UNIQUEIDENTIFIER CONSTRAINT [DF_aspmnx_ActiveUsers_pkActiveUsers] DEFAULT (newid()) NOT NULL,
    CONSTRAINT [PK_aspmnx_activeUsers] PRIMARY KEY NONCLUSTERED ([pkActiveUsers] ASC)
);


GO
CREATE NONCLUSTERED INDEX [activeuserupdate]
    ON [dbo].[aspmnx_ActiveUsers]([sessionId] ASC, [fkuserId] ASC)
    INCLUDE([oldsessionId], [lastActivityDate]);


GO
CREATE NONCLUSTERED INDEX [fkuserId]
    ON [dbo].[aspmnx_ActiveUsers]([fkuserId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aspmnx_ActiveUsers]
    ON [dbo].[aspmnx_ActiveUsers]([sessionId] ASC, [oldsessionId] ASC, [fkuserId] ASC);


GO
CREATE NONCLUSTERED INDEX [lastActivityDate]
    ON [dbo].[aspmnx_ActiveUsers]([lastActivityDate] ASC);


GO
CREATE NONCLUSTERED INDEX [oldsessionID]
    ON [dbo].[aspmnx_ActiveUsers]([oldsessionId] ASC);


GO
CREATE NONCLUSTERED INDEX [SessionID]
    ON [dbo].[aspmnx_ActiveUsers]([sessionId] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [SessionUserUnique]
    ON [dbo].[aspmnx_ActiveUsers]([sessionId] ASC, [fkuserId] ASC);


GO
-- =============================================
-- Author:		David Sharp
-- Create date: 11/15/2012
-- Description:	check for insert records and update subscribed users
-- 07/10/13 DS Add handing for bogus ID for desktop users
-- 01/15/14 YS added new column notificationType varchar(20)
--- coud have 'N' - for notification
---			  'E' - for email
---			  'N,E' - for both
--- open for future methods of notification
-- =============================================
CREATE TRIGGER [dbo].[NOTICE_ActiveUserCount] 
   ON  [dbo].[aspmnx_ActiveUsers] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    DECLARE @valueString varchar(MAX), @userCount int
    SELECT @userCount=COUNT(*)FROM dbo.aspmnx_ActiveUsers
    -- 12/17/2012 David Modified to use notificationValues
    --SELECT @userName=u.UserName FROM inserted i INNER JOIN aspnet_Users u ON i.fkuserId=u.UserId
    SELECT @valueString='{''userName'':'''+ COALESCE(u.UserName,'Desktop only user')+''',''userCount'':'+CAST(@userCount AS varchar(100))+'}' 
		FROM inserted i LEFT OUTER JOIN aspnet_Users u ON i.fkuserId=u.UserId
    
    
    INSERT INTO dbo.wmTriggerNotification(noticeType,recipientId,triggerId,dateAdded,notificationValues)
    SELECT 'Subscribe',fkUserId,'643c335a-87db-44ea-aa1d-a4aa5fddd41b',GETDATE(),@valueString
		FROM wmTriggersActionSubsc 
		WHERE fkActTriggerId='643c335a-87db-44ea-aa1d-a4aa5fddd41b' AND @userCount>=CAST(recordLink as INT)
		-- 01/15/14 YS added new column notificationType varchar(20)
			and charindex('N',notificationType)<>0
    
    --SELECT * FROM aspnet_Users

END
