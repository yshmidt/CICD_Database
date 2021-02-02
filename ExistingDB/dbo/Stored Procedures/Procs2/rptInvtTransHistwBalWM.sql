-- =============================================
	-- Author:		Yelena
	-- Create date: 01/12/2015
	-- Description:	This Stored Procedure was created for the Inventory Transaction History with Balance and will replace rptInvtTransHistwBal
	-- original Report:  icrpt4.rpt
	-- =============================================
	CREATE PROCEDURE [dbo].[rptInvtTransHistwBalWM]
	-- changing parameters to work on the  web
			@lcUniq_key char(10),
			@lcType as char (20) = 'Internal',  --where the user would specify Internal, Internal & In Store, In Store, Consigned
			@lcCustNo as varchar(max) = 'All',
			@lcDateStart as smalldatetime= null,
			@userId uniqueidentifier = null
	
	AS
	BEGIN		
		-- check sql version  and run a different code for the sql server 2012 and up.
		-- wndowing functions 
		IF @@Version like'%2008%'
			--- use CTE to claculate running total (much slower than what sql 2012 and up can do with new  ROWS UNBOUNDED PRECEDING function
			exec [rptInvtTransHistwBal2008WM] @lcUniq_key ,
							@lcType ,
							@lcCustNo ,
							@lcDateStart,
							@userId 
		else --  @@Version like'%2008%'
			exec [rptInvtTransHistwBal2012WM] @lcUniq_key ,
							@lcType ,
							@lcCustNo ,
							@lcDateStart,
							@userId 



	END