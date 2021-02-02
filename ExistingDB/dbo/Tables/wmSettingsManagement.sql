CREATE TABLE [dbo].[wmSettingsManagement] (
    [settingId]    UNIQUEIDENTIFIER NOT NULL,
    [settingValue] NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK_wmSettingsManagement] PRIMARY KEY NONCLUSTERED ([settingId] ASC),
    CONSTRAINT [FK_wmSettingsManagement_mnxSettingsManagement] FOREIGN KEY ([settingId]) REFERENCES [dbo].[MnxSettingsManagement] ([settingId]) ON DELETE CASCADE
);


GO
CREATE CLUSTERED INDEX [IX_moduleid]
    ON [dbo].[wmSettingsManagement]([settingId] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UK_wmSettingsManagement]
    ON [dbo].[wmSettingsManagement]([settingId] ASC);


GO
-- =============================================
-- Author:		Satish B
-- Create date: 11/16/2016
-- Description:	<Update trigger for MnxGroupParams to update default values in packing list reports from packing list setting.>
-- Modified : 03/02/2017 Raviraj P Added a commit statement to complete the transaction
--          : 09/14/2017 Satish B : Check setting value with '1' instade of check with 'True'
--			: 02/28/2018 Satish B : Change checked setting name from PKPRINTBC to IncludeBarCode
--			: 02/28/2018 Satish B : Check setting names in IncludeBarCode and PrintCustPartNo instade of PKPRINTBC and PK_CUSTPN 
--			: 05/10/2018 Satish B : Added code for error handling and rearrange the existing code
--			: 05/24/2018 Satish B : Change where condition from m.settingModule='Packing List' to m.settingModule='PackingList'
-- =============================================
CREATE TRIGGER [dbo].[wmSettingsManagement_Update]
   ON  [dbo].[wmSettingsManagement]
   AFTER UPDATE
AS 
BEGIN
   SET NOCOUNT ON;
   -- Update statements for trigger here
   BEGIN TRANSACTION
		IF (SELECT m.settingModule FROM INSERTED I INNER JOIN mnxSettingsManagement m ON m.settingId=I.settingId ) NOT LIKE 'Packing%'
		  BEGIN
			  COMMIT-- 03/02/2017 Raviraj P Added a commit statement to complete the transaction
			  RETURN
		  END
		ELSE
		 --05/10/2018 Satish B : Added code for error handling and rearrange the existing code : START
		  BEGIN TRY
				 BEGIN
					DECLARE @temp table (settingName varchar(50),settingValue varchar(50))
					INSERT INTO @temp
						--02/28/2018 Satish B : Change checked setting name from PKPRINTBC to IncludeBarCode
						SELECT  CASE WHEN m.settingName ='IncludeBarCode' THEN 'lcBarCodeAddndm' ELSE 'lcCustPn'END as settingName,
						--09/14/2017 Satish B : Check setting value with '1' instade of check with 'True'
						--CASE WHEN  w.settingValue ='True' THEN 'Yes' ELSE 'No' END as settingValue 
						CASE WHEN  w.settingValue ='1' THEN 'Yes' ELSE 'No' END as settingValue 
					FROM mnxSettingsManagement m 
						INNER JOIN wmSettingsManagement w ON m.settingId=w.settingId 
					--05/24/2018 Satish B : Change where condition from m.settingModule='Packing List' to m.settingModule='PackingList'
					WHERE m.settingModule='PackingList'
						--02/28/2018 Satish B : Check setting names in IncludeBarCode and PrintCustPartNo instade of PKPRINTBC and PK_CUSTPN 
						AND settingName in ('IncludeBarCode' ,'PrintCustPartNo')

					UPDATE MnxGroupParams SET defaultValue= t.settingValue  
						   FROM MnxParams m 
						   INNER JOIN MnxGroupParams p ON p.fkParamId =m.rptParamId 
						   INNER JOIN @temp t ON t.settingName = m.paramname
					WHERE m.sourceLink='yesNo' 
						  AND p.paramgroup='PackList'
				END
				COMMIT
			END TRY
			BEGIN CATCH
				IF @@TRANCOUNT>0
				ROLLBACK
				RAISERROR('Error occurred while updating MnxGroupParams table',11,1)
			END CATCH
			--05/10/2018 Satish B : Added code for error handling and rearrange the code : END
		 
END
