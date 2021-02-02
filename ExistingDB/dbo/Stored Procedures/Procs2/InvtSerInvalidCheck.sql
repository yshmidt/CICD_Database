-- =============================================
-- Author:		??
-- Create date: ??
-- Description:	??
-- Modified: 04/08/15 YS user's setting saved in wmsettings.. table 
-- =============================================
CREATE PROCEDURE [dbo].[InvtSerInvalidCheck]
(
 @SerialNo   VARCHAR(30),
 @wono       VARCHAR(10),
 @UserId	UNIQUEIDENTIFIER
)
AS
BEGIN

DECLARE @ErrorMessage AS VARCHAR(50) = 'Invalid Serial Number'
--04/08/15 YS user's setting saved in wmsettings.. table 
--DECLARE @ErrorLogging AS VARCHAR(50) = (SELECT [settingValue] FROM [MnxSettingsManagement]  WHERE ModuleId = 41 AND [settingName]='ErrorLogging')
DECLARE @ErrorLogging AS VARCHAR(50) = (SELECT COALESCE(s.[settingValue],w.[settingValue]) FROM [MnxSettingsManagement] S LEFT OUTER JOIN 
											WmSettingsManagement W on s.settingid=w.settingid  WHERE s.ModuleId = 41 AND s.[settingName]='ErrorLogging')
DECLARE @Dept_Id AS CHAR(10) = null

 DECLARE @tSNDetails TABLE
        (
		   [SERIALUNIQ] [CHAR](10) NOT NULL,
           [SERIALNO]   [CHAR](30) NOT NULL,          
           [ID_KEY]     [CHAR](10) NOT NULL,
           [ID_VALUE]   [CHAR](10) NOT NULL,
           [WONO]       [CHAR](10) NOT NULL,
           [DEPT_ID]    [CHAR](4) NOT NULL,
           [DEPTKEY]    [CHAR](10) NOT NULL           
        )

INSERT INTO @tSNDetails     
select invtser.SerialUniq,invtser.SerialNo,invtser.id_key,invtser.id_value,invtser.wono,D.dept_id,d.deptkey from invtser
, dept_qty d
where SerialNo=@SerialNo and invtser.wono = @wono
AND d.wono = invtser.wono
AND d.deptkey = CASE
							WHEN invtser.id_key = 'DEPTKEY'
							THEN
								invtser.id_value
							ELSE 
								D.deptkey
							END
AND D.dept_id = CASE
					WHEN invtser.id_key = 'W_KEY'
					THEN
						'FGI'
					ELSE 
						D.dept_id
					END

	IF ISNULL(@ErrorLogging,0) = 1
	BEGIN
		IF (SELECT COUNT(*) from @tSNDetails) > 0  
		BEGIN
			SET @Dept_Id = (SELECT dept_id FROM @tSNDetails)
			SET @ErrorMessage = 'Return to ' + @Dept_Id
		END

		EXEC BarCodeErrorLogSFAdd @wono ,@UserId ,@Dept_Id ,@SerialNo,@ErrorMessage
	END

	SELECT SerialUniq,SerialNo,id_key,id_value,wono,dept_id,deptkey 
	from @tSNDetails
END