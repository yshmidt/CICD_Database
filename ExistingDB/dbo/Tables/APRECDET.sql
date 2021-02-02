﻿CREATE TABLE [dbo].[APRECDET] (
    [UNIQRECUR]    CHAR (10)       CONSTRAINT [DF__APRECDET__UNIQRE__4E1E9780] DEFAULT ('') NOT NULL,
    [UNIQDETREC]   CHAR (10)       CONSTRAINT [DF__APRECDET__UNIQDE__4F12BBB9] DEFAULT ('') NOT NULL,
    [ITEM_NO]      NUMERIC (10)    CONSTRAINT [DF__APRECDET__ITEM_N__51EF2864] DEFAULT ((0)) NOT NULL,
    [ITEM_DESC]    CHAR (25)       CONSTRAINT [DF__APRECDET__ITEM_D__52E34C9D] DEFAULT ('') NOT NULL,
    [QTY_EACH]     NUMERIC (8, 2)  CONSTRAINT [DF__APRECDET__QTY_EA__53D770D6] DEFAULT ((0)) NOT NULL,
    [PRICE_EACH]   NUMERIC (13, 5) CONSTRAINT [DF__APRECDET__PRICE___54CB950F] DEFAULT ((0)) NOT NULL,
    [IS_TAX]       BIT             CONSTRAINT [DF__APRECDET__IS_TAX__55BFB948] DEFAULT ((0)) NOT NULL,
    [TAX_PCT]      NUMERIC (8, 4)  CONSTRAINT [DF__APRECDET__TAX_PC__56B3DD81] DEFAULT ((0)) NOT NULL,
    [ITEM_TOTAL]   NUMERIC (10, 2) CONSTRAINT [DF__APRECDET__ITEM_T__57A801BA] DEFAULT ((0)) NOT NULL,
    [GL_NBR]       CHAR (13)       CONSTRAINT [DF__APRECDET__GL_NBR__589C25F3] DEFAULT ('') NOT NULL,
    [ITEM_NOTE]    TEXT            CONSTRAINT [DF__APRECDET__ITEM_N__59904A2C] DEFAULT ('') NOT NULL,
    [PRICE_EACHFC] NUMERIC (13, 5) CONSTRAINT [DF__APRECDET__PRICE___05B12591] DEFAULT ((0)) NOT NULL,
    [ITEM_TOTALFC] NUMERIC (10, 2) CONSTRAINT [DF__APRECDET__ITEM_T__06A549CA] DEFAULT ((0)) NOT NULL,
    [PRICE_EACHPR] NUMERIC (13, 5) CONSTRAINT [DF__APRECDET__PRICE___4E428BC4] DEFAULT ((0)) NOT NULL,
    [ITEM_TOTALPR] NUMERIC (10, 2) CONSTRAINT [DF__APRECDET__ITEM_T__4F36AFFD] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [APRECDET_PK] PRIMARY KEY CLUSTERED ([UNIQDETREC] ASC)
);


GO
-- =============================================
-- Author:		Vicky Lu	
-- Create date: 12/07/16
-- Description:	After Delete trigger for the Apdetail table
-- =============================================
CREATE TRIGGER  [dbo].[Aprecdet_Delete]
   ON  [dbo].[Aprecdet] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION 
	DELETE FROM AprecdetTax WHERE UNIQDETREC IN (SELECT UNIQDETREC FROM DELETED)
	COMMIT

END