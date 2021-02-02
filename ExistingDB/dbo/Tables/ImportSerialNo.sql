CREATE TABLE [dbo].[ImportSerialNo] (
    [Wono]     CHAR (10)   CONSTRAINT [DF__ImportSeri__Wono__72C939A6] DEFAULT ('') NOT NULL,
    [Serialno] CHAR (30)   CONSTRAINT [DF__ImportSer__Seria__73BD5DDF] DEFAULT ('') NOT NULL,
    [Part_no]  CHAR (25)   CONSTRAINT [DF__ImportSer__Part___74B18218] DEFAULT ('') NOT NULL,
    [Revision] CHAR (8)    CONSTRAINT [DF__ImportSer__Revis__75A5A651] DEFAULT ('') NOT NULL,
    [Uniq_key] CHAR (10)   CONSTRAINT [DF__ImportSer__Uniq___7699CA8A] DEFAULT ('') NOT NULL,
    [Balance]  NUMERIC (7) CONSTRAINT [DF__ImportSer__Balan__778DEEC3] DEFAULT ((0)) NOT NULL,
    [Deptkey]  CHAR (10)   CONSTRAINT [DF__ImportSer__Deptk__788212FC] DEFAULT ('') NOT NULL,
    [importId] INT         IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_ImportSerialNo] PRIMARY KEY CLUSTERED ([importId] ASC)
);

