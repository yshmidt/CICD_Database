CREATE TABLE [dbo].[Forecast] (
    [forecastno] NUMERIC (6)   CONSTRAINT [DF_Forecast_forecastno] DEFAULT ((0)) NOT NULL,
    [uniq_key]   CHAR (10)     CONSTRAINT [DF_Forecast_uniq_key] DEFAULT ('') NOT NULL,
    [totalqty]   NUMERIC (8)   CONSTRAINT [DF_Forecast_totalqty] DEFAULT ((0)) NOT NULL,
    [startdt]    SMALLDATETIME NULL,
    [qtyper]     NUMERIC (8)   CONSTRAINT [DF_Forecast_qtyper] DEFAULT ((0)) NOT NULL,
    [unitper]    CHAR (2)      CONSTRAINT [DF_Forecast_unitper] DEFAULT ('') NOT NULL,
    [forcstnote] TEXT          CONSTRAINT [DF_Forecast_forcstnote] DEFAULT ('') NOT NULL,
    [consumed]   NUMERIC (10)  CONSTRAINT [DF_Forecast_consumed] DEFAULT ((0)) NOT NULL,
    [edit_date]  SMALLDATETIME NULL,
    [SAVEINIT]   CHAR (8)      CONSTRAINT [DF_Forecast_SAVEINIT] DEFAULT ('') NULL,
    [custno]     NCHAR (10)    CONSTRAINT [DF_Forecast_custno] DEFAULT ('') NOT NULL,
    [SIMULATION] BIT           CONSTRAINT [DF_Forecast_SIMULATION] DEFAULT ((0)) NOT NULL,
    [CONSUME]    BIT           CONSTRAINT [DF_Forecast_CONSUME] DEFAULT ((0)) NOT NULL,
    [w_key]      CHAR (10)     CONSTRAINT [DF_Forecast_w_key] DEFAULT ('') NOT NULL,
    [uniqmfgrhd] CHAR (10)     CONSTRAINT [DF_Forecast_uniqmfgrhd] DEFAULT ('') NOT NULL,
    [forecastuk] CHAR (10)     CONSTRAINT [DF_Forecast_forecastuk] DEFAULT ('') NOT NULL
);

