CREATE TABLE [dbo].[wmSystemErrors] (
    [errorId]        BIGINT           IDENTITY (1, 1) NOT NULL,
    [userId]         UNIQUEIDENTIFIER NOT NULL,
    [eventDate]      SMALLDATETIME    NOT NULL,
    [url]            VARCHAR (500)    NOT NULL,
    [controllerName] VARCHAR (50)     NOT NULL,
    [actionName]     VARCHAR (50)     NOT NULL,
    [errorMessage]   VARCHAR (MAX)    NOT NULL
);

