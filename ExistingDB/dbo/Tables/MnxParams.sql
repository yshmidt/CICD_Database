CREATE TABLE [dbo].[MnxParams] (
    [rptParamId]      UNIQUEIDENTIFIER CONSTRAINT [DF_mnxParams_paramId] DEFAULT (newid()) NOT NULL,
    [localizationKey] VARCHAR (50)     CONSTRAINT [DF_mnxParams_displayName] DEFAULT ('') NOT NULL,
    [paramName]       VARCHAR (50)     NOT NULL,
    [paramType]       VARCHAR (50)     CONSTRAINT [DF_mnxParams_paramType] DEFAULT ('Text') NOT NULL,
    [sourceLink]      VARCHAR (100)    CONSTRAINT [DF_mnxParams_sourceLink] DEFAULT ('') NOT NULL,
    [fieldWidth]      VARCHAR (50)     CONSTRAINT [DF_MnxParams_fieldWidth] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_mnxParams] PRIMARY KEY CLUSTERED ([rptParamId] ASC)
);


GO
-- =============================================
-- Author:		David Sharp
-- Create date: 8/14/2013
-- Description:	Delete the target trigger link (parent or target) if the parameter is deleted
-- 10/07/2013 YS changed name of the table from rptGroupParams to mnxGroupParams and others
-- 03/03/14 DS moved the delete from GroupParams to Params
-- =============================================
CREATE TRIGGER [dbo].[MnxParams_Delete] 
   ON  [dbo].[MnxParams] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DELETE FROM MnxGroupParams
		WHERE fkParamId IN (SELECT rptParamId FROM deleted)
			OR fkParamId IN (SELECT rptParamId FROM deleted)
	DELETE FROM MnxReportParamTargets
		WHERE rptParamId IN (SELECT rptParamId FROM deleted)
			OR parentParamId IN (SELECT rptParamId FROM deleted)
    -- Insert statements for trigger here

END
