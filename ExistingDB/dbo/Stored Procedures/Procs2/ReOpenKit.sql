 -- ============================================================================================================  
-- Date   : 01/03/2020  
-- Author  : Rajendra K 
-- Description : Used in Kitting Module to Re-Open Kit 
-- ReOpenKit '0000001236,0000001236,0000001236,0000001236,0000001236','49F80792-E15E-4B62-B720-21B360E3108A'
-- ============================================================================================================    
CREATE PROC ReOpenKit
 @Wono VARCHAR(MAX),
 @userId UNIQUEIDENTIFIER = null
 AS  
BEGIN 
 SET NOCOUNT ON; 
  DECLARE @initials VARCHAR(10);
  DECLARE @woNoList AS Table (woNo CHAR(10))    
  INSERT INTO @woNoList SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@Wono,',')
  SET @initials = (SELECT Initials FROM aspnet_Profile WHERE UserId = @userId)

  BEGIN TRY    
  BEGIN TRANSACTION  	
	    UPDATE Wo
		 SET KitStatus = CASE WHEN Wo.LIS_RWK = 1 THEN 'REWORK' ELSE 'KIT PROCSS' END
			,KitCloseDt = NULL
			,KitCloseUserID = NULL
			,KitReOpenUserId = @userId
		FROM WOENTRY Wo 
		INNER JOIN @woNoList W ON W.woNo = Wo.WONO

		-- Get Both type records
		SELECT dbo.fn_GenerateUniqueNumber() AS UniqMfgVar, mf.Wono AS Wono,Uniq_key,IssueCost,BomCost,-TotalVar AS Totalvar,@userId AS UserId,Man_gl_nbr, Wip_gl_nbr, 
		GETDATE() AS Date,Vartype, IssuecostPR, BomcostPR,-TotalvarPR AS TotalVarpp,PRFcused_uniq, FuncFcused_uniq,0 AS isKitClosed,UniqMfgVar AS refUniqMfgVar,@initials AS initials 
		INTO #MfgrvData
		FROM MFGRVAR mf 
		INNER JOIN @woNoList w ON w.wono = mf.wono
		WHERE isKitClosed=1 AND (vartype='RVAR' OR vartype='MFGRV')
		AND NOT EXISTS (SELECT 1 FROM MFGRVAR O WHERE o.refUniqMfgVar=mf.UNIQMFGVAR) ORDER BY DATETIME DESC

		--Insert data into MFGRVAR
		IF EXISTS(SELECT TOP 1 * FROM #MfgrvData)
		BEGIN
			INSERT INTO MFGRVAR (UniqMfgVar, Wono, Uniq_key, Issuecost, Bomcost, Totalvar, UserId, Man_gl_nbr, Wip_gl_nbr, 
								 Datetime, VarType, IssuecostPR, BomcostPR, TotalvarPR, PRFcused_uniq, FuncFcused_uniq,isKitClosed,refUniqMfgVar,INITIALS) 
			SELECT * FROM #MfgrvData
		END
  COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
  	ROLLBACK TRANSACTION;
   SELECT      
  	  ERROR_NUMBER() AS ErrorNumber      
  	 ,ERROR_SEVERITY() AS ErrorSeverity      
  	 ,ERROR_PROCEDURE() AS ErrorProcedure      
  	 ,ERROR_LINE() AS ErrorLine      
  	 ,ERROR_MESSAGE() AS ErrorMessage;  
  END CATCH		
END
