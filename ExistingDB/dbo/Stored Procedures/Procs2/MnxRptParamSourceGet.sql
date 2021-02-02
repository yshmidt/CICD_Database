		   
		-- =============================================    
		-- Author:  Aloha    
		-- Create date: 04/17/2013     
		-- Description: Selects the Sourcesql by its source name it will need in serial list   
		-- 08/08/14 YS added bigData column to mnxParamSources table 
		-- =============================================    
		CREATE PROCEDURE [dbo].[MnxRptParamSourceGet]--'openPoSelect' ,'lcPoNum'   
		 @sourceName char(50)   
		AS    
		BEGIN    
		  
		-- Selects the Source Sql
		--05/09/13 YS change to use dataSource in place of source
		 -- 08/08/14 YS added bigData column to mnxParamSources table 
		 SELECT  DataSource, sourceType,bigData    
		 FROM 
			MnxParamSources  WHERE sourceName=@sourceName    
		      
		END  