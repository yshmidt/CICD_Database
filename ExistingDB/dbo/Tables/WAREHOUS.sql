CREATE TABLE [dbo].[WAREHOUS] (
    [UNIQWH]                    CHAR (10) CONSTRAINT [DF__WAREHOUS__UNIQWH__27BA8E24] DEFAULT ('') NOT NULL,
    [WHNO]                      CHAR (3)  CONSTRAINT [DEFAULTWHNO] DEFAULT ([dbo].[NewWhNo]()) NOT NULL,
    [WAREHOUSE]                 CHAR (6)  CONSTRAINT [DF__WAREHOUS__WAREHO__29A2D696] DEFAULT ('') NOT NULL,
    [WH_DESCR]                  CHAR (25) CONSTRAINT [DF__WAREHOUS__WH_DES__2A96FACF] DEFAULT ('') NOT NULL,
    [WH_GL_NBR]                 CHAR (13) CONSTRAINT [DF__WAREHOUS__WH_GL___2B8B1F08] DEFAULT ('') NOT NULL,
    [WH_NOTE]                   TEXT      CONSTRAINT [DF__WAREHOUS__WH_NOT__2D73677A] DEFAULT ('') NOT NULL,
    [DEFAULT]                   BIT       CONSTRAINT [DF__WAREHOUS__DEFAUL__2E678BB3] DEFAULT ((0)) NOT NULL,
    [GLDIVNO]                   CHAR (2)  CONSTRAINT [DF__WAREHOUS__GLDIVN__2F5BAFEC] DEFAULT ('') NOT NULL,
    [WHSTATUS]                  CHAR (10) CONSTRAINT [DF__WAREHOUS__WHSTAT__34206509] DEFAULT ('Active') NOT NULL,
    [LNOTAUTOKIT]               BIT       CONSTRAINT [DF__WAREHOUS__LNOTAU__35148942] DEFAULT ((0)) NOT NULL,
    [IS_DELETED]                BIT       CONSTRAINT [DF__WAREHOUS__IS_DEL__3608AD7B] DEFAULT ((0)) NOT NULL,
    [AUTOLOCATION]              BIT       CONSTRAINT [DF__WAREHOUS__AUTOLO__36FCD1B4] DEFAULT ((0)) NOT NULL,
    [LREMOVEWHENZERO]           BIT       CONSTRAINT [DF__WAREHOUS__LREMOV__37F0F5ED] DEFAULT ((0)) NOT NULL,
    [LADD2NEWAVL]               BIT       CONSTRAINT [DF__WAREHOUS__LADD2N__38E51A26] DEFAULT ((0)) NOT NULL,
    [WH_MAP]                    BIT       CONSTRAINT [DF__WAREHOUS__WH_MAP__41929C1C] DEFAULT ((0)) NOT NULL,
    [ALLOW_MX_FIND_LOC_ATRECEV] BIT       CONSTRAINT [DF__WAREHOUS__ALLOW___4286C055] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [WAREHOUS_PK] PRIMARY KEY CLUSTERED ([UNIQWH] ASC)
);


GO
CREATE NONCLUSTERED INDEX [DIVWHNAME]
    ON [dbo].[WAREHOUS]([GLDIVNO] ASC, [WAREHOUSE] ASC);


GO
CREATE NONCLUSTERED INDEX [DIVWHNO]
    ON [dbo].[WAREHOUS]([GLDIVNO] ASC, [WHNO] ASC);


GO
CREATE NONCLUSTERED INDEX [WAREHOUSE]
    ON [dbo].[WAREHOUS]([WAREHOUSE] ASC);


GO
CREATE NONCLUSTERED INDEX [WHNO]
    ON [dbo].[WAREHOUS]([WHNO] ASC);


GO
-- =============================================
-- Author:		Yelena
-- Create date: 07/15/2015
-- Description:	Update Trigger
--08/04/15 YS fixed update, added where importBOMFieldDefinitions.fieldname='warehouse'
-- =============================================
CREATE TRIGGER [dbo].[warehous_Update] 
   ON  [dbo].[WAREHOUS] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	-- update importBOMFieldDefinitions.default for warehouse if default warehous is changed in the warehous table
	--08/04/15 YS fixed update, added where importBOMFieldDefinitions.fieldname='warehouse'
	Update importBOMFieldDefinitions set [default]=Inserted.warehouse from Inserted 
		where importBOMFieldDefinitions.fieldname='warehouse' and  Inserted.[DEFAULT]=1 and Inserted.warehouse<>importBOMFieldDefinitions.[default]

END