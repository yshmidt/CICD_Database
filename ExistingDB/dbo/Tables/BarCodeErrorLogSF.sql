CREATE TABLE [dbo].[BarCodeErrorLogSF] (
    [ErrorId]      INT              IDENTITY (1, 1) NOT NULL,
    [Wono]         CHAR (10)        NOT NULL,
    [UserId]       UNIQUEIDENTIFIER NOT NULL,
    [Dept_Id]      CHAR (10)        NULL,
    [SerialNo]     VARCHAR (30)     NOT NULL,
    [InsertDate]   DATETIME         CONSTRAINT [DF__BarCodeEr__Inser__1E9C0395] DEFAULT (getdate()) NOT NULL,
    [ErrorDetails] VARCHAR (500)    NOT NULL,
    CONSTRAINT [PK__BarCodeE__35856A2A1CB3BB23] PRIMARY KEY CLUSTERED ([ErrorId] ASC)
);

