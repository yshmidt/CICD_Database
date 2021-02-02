
		-- =============================================
		-- Author:			Debbie 
		-- Create date:		04/26/2013
		-- Description:		Created for the ECO Status Report
		-- Reports:			ecstatus.rpt 
		-- Modifications:	09/13/2013 DRP:  per conversation with David/Yelena I went through and remove the '*' from the parameters   then added code how to handle null or '*'  should now work for both the CR and Stimulsoft reports
		--					04/18/2014 DRP:  needed to change the customer parameter to custno from custname
		--					01/06/2015 DRP:  Added @customerStatus Filter 
		--					06/22/2015 DRP:  changed part range paramaters from lcpart to lcuniq_key  Also removed the Micssys.LicName
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		-- =============================================
		CREATE PROCEDURE  [dbo].[rptEcoStatus]

--declare	  
				@lcEcStatus as char(10) = 'All'				--This is the ECO Status selection, will be populated with one of the following : (Edit,Pending,Approved,Completed,Cancelled or All)
				,@lcEcType	as char(9) = 'ECO'					--This is the ECO Type, will be populated by either (ECO,BCN or Deviation)
				,@lcDateStart as smalldatetime= null		--This is based on the ECO Open Date
				,@lcDateEnd as smalldatetime = null
				--,@lcPartStart as varchar(25)= null        				--06/22/2015 DRP:  Removed
				--,@lcPartEnd as varchar(25)= null							--06/22/2015 DRP:  Removed
				,@lcUniq_keyStart as char(10) = null				--This is based on the Part_no (not the NewProdNo)
				,@lcUniq_keyEnd as char(10) = null
				,@lcCustNo as varchar(max) = 'All'
				--,@lcCust as varchar (35) = ''				--Customer Select
				,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
				, @userId uniqueidentifier= null
as
		begin

-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--06/22/2015 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	declare @lcPartStart char(35)='',@lcRevisionStart char(8)='',
		@lcPartEnd char(35)='',@lcRevisionEnd char(8)=''

	--06/22/2015 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
	-- find starting part number
	IF  @lcUniq_keyStart IS NULL or  @lcUniq_keyStart ='' 
		SELECT	@lcPartStart=' ', @lcRevisionStart=' '
	ELSE
		SELECT	@lcPartStart = iSNULL(I.Part_no,' ') ,	
				@lcRevisionStart = ISNULL(I.Revision,' ') 
		FROM	Inventor I where Uniq_key=@lcUniq_keyStart
		
	-- find ending part number
	IF  @lcUniq_keyEnd IS NULL or  @lcUniq_keyEnd ='' 
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
		SELECT	@lcPartEnd = REPLICATE('Z',35), @lcRevisionEnd=REPLICATE('Z',8)
	ELSE
		SELECT	@lcPartEnd = ISNULL(I.Part_no,' '),
				@lcRevisionEnd = ISNULL(I.Revision,' ') 
		FROM	Inventor I where Uniq_key=@lcUniq_keyEnd
	--select @lcPartStart, @lcRevisionStart	,@lcPartEnd,@lcRevisionEnd
	SELECT @lcDateStart=CASE WHEN @lcDateStart is null then @lcDateStart else cast(@lcDateStart as smalldatetime)  END,
			@lcDateEnd=CASE WHEN @lcDateEnd is null then @lcDateEnd else DATEADD(day,1,cast(@lcDateEnd as smalldatetime))  END

		----09/13/2013 DRP: If null or '*' then pass '' for Part No
		--	IF @lcPartStart is null OR @lcPartStart = '*'
		--		select @lcPartStart=''
		--	IF @lcPartEnd is null OR @lcPartEnd = '*'
		--		select @lcPartEnd=''
		----09/13/2013 DRP:  IF NULL OR '*' THEN PASS '' FOR ECTYPE
		--	if @lcEcType is null or @lcEcType='*' 
		--		select @lcEcType=''


/*04/18/2014 DRP:  REMOVED THE BELOW AND REPLACED WITH THE CUSTNO SELECTION BELOW
		09/13/2013 DRP:  added code to handle Wo List
			declare @Cust table(Cust char(35))
			if @lcCust is not null and @lcCust <> ''
				insert into @Cust select * from dbo.[fn_simpleVarcharlistToTable](@lcCust,',')	
*/

		DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of Customers for @userid with access
		INSERT INTO @tCustomer EXEC aspmnxSP_Getcustomers4user @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
		IF @lcCustno is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select Custno from @tCustomer)
		ELSE

		IF  @lccustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT Custno FROM @tCustomer
		END	

	
	
	
		--09/13/2013 DRP:  added code to handle EC Status List
			declare @status table (EcStatus char(10))
				if @lcEcStatus is not null or @lcEcStatus<> 'ALL' and @lcEcStatus <> '' 
					insert into @status select * from dbo.[fn_simpleVarcharlistToTable](@lcEcStatus,',')
				
						
					; with zECO as(
					SELECT	Custname,EcoNo,OpenDate,Engineer,ChangeType,EcStatus,Part_no,Revision,Part_Class,Part_Type,Descript,NewProdNo,NewRev,NewDescr,UniqEcNo,customer.custno
					FROM	EcMain
							left outer join inventor on ecmain.UNIQ_KEY = inventor.UNIQ_KEY
							left outer join CUSTOMER on inventor.bomCUSTNO = customer.CUSTNO
		--09/13/2013 DRP:	--where	ECSTATUS like case when @lcEcStatus = '*' then '%' else @lcEcStatus end
					--		and ISNULL(Customer.Custname,' ') like case when @lcCust ='*' then '%' else @lcCust+'%' end
					--		and OPENDATE>=@lcDateStart AND opendate<@lcDateEnd+1
					--		and Part_no>= case when @lcPartStart='*' then PART_NO else @lcPartStart END
					--		and PART_NO<= CASE WHEN @lcPartEnd='*' THEN PART_NO ELSE @lcPartEnd END
					--		and ChangeType like case when @lcEcType = '*' then '%' else @lcEcType end
					where	ECSTATUS = case when @lcEcStatus = 'All' then ECSTATUS else @lcEcStatus end 
							--and 1 = case when isnull(Customer.CUSTNAME,'') like case when @lcCust ='' then '%' else @lcCust+'%' end then 1 else 0 end 
							and 1= case WHEN customer.custNO IN (SELECT custno FROM @custOMER) THEN 1 ELSE 0  END
							--and Part_no>= case when @lcPartStart='' then Part_no else @lcPartStart END		--06/22/2015 DRP:  Replaced with the below to work with the Uniq_key that is now passed
							--and PART_NO<= CASE WHEN @lcPartEnd=''  THEN PART_NO ELSE @lcPartEnd END			--06/22/2015 DRP:  Replaced with the below to work with the Uniq_key that is now passed
							and (part_no+REVISION between @lcPartStart+@lcRevisionStart and @lcPartEnd+@lcRevisionEnd)
							and OPENDATE>=@lcDateStart AND opendate<@lcDateEnd+1
							and changeType = case when @lcEcType='' THEN  changeType else @lcEcType end 
								
						
					)	
					--select * from zECO

					,
					Zaprov as (
					SELECT	EcApprov.UniqEcNo, COUNT(UniqAppno) AS NoAprov 
					FROM	EcApprov, zECO 
					WHERE	EcApprov.Init <> '' 
							AND EcApprov.UniqEcNo = zECO.UniqEcNo 
					GROUP BY EcApprov.UniqEcNo
					)  
					--select * from zaprov

					select	e1.*,isnull(a1.NoAprov,0) as NoAprov 
							--,micssys.LIC_NAME	--06/22/2015 DRP:  Removed
					from	zECO E1 
							left outer join  zaprov A1 on e1.UNIQECNO = A1.UNIQECNO
							--cross join micssys	--06/22/2015 DRP:  Removed
					GROUP BY Custname,EcoNo,OpenDate,Engineer,ChangeType,EcStatus,Part_no,Revision,Part_Class,Part_Type,Descript,NewProdNo,NewRev,NewDescr,e1.UNIQECNO,a1.NoAprov,custno
							--,LIC_NAME		--06/22/2015 DRP: Removed
					order by UNIQECNO
				
		end
		
		