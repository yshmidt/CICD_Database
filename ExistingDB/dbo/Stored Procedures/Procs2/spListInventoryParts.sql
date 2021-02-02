-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/19/13
-- Description:	Universal list of parts, designed to use in the pick list .net
-- Modified: 11/27/13 YS added new parameter @ShowRevision . Ignore revision for part ranges 
---						change default '' to be 'All' for All, empty means no selection
--						change to search for @filter if provided anywhere in the part_no, not just in the beginning.
--						changed to use custpartno if consign part
--						check column that are returned
--			 01/28/15 DS changed filter from @filter to @paramFilter
--			 02/11/2015 DRP:  02/17/2015 changed it back again. . . the changes above made by David "changed filter from @filter to @paramFilter" did not work with the Cloud version.  Changed it back to @filter
-- =============================================
CREATE PROCEDURE [dbo].[spListInventoryParts]
	-- Add the parameters for the stored procedure here
	@PartSource varchar(100)='BUY',				--- could be 'BUY' or 'MAKE' or 'CONSG' or 'PHANTOM' or 'ALL' or any combinations , e.g. 'BUY,CONSG'
	@custno varchar(max)='',					--- if @PartSource CONSG have to enter Custno
	@MakeBuy bit = NULL,						--  NULL - no filter for the Make_buy, 1 - only make buy when @partSource='MAKE', 0 - only not make_buy when @partsource='MAKE'
	@PartClass varchar(max)='All',					-- if empty no restictions for part class
	@PartType varchar(max)='All',					-- if empty no restictions for part type
	@Status varchar(50)='Active',				-- could be 'Active' or 'Inactive' or 'Active,Inactive' or 'All'
	@paramFilter varchar(max)='',                    -- if filter is empty - return all records 
	@showRevision bit = 1,						-- if 1 show revision as part of the value, 0 - do not.
	@userid uniqueidentifier = null				
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- 11/27/13 YS trim the filter
	SET @paramFilter=RTRIM(@paramFilter);
    -- Insert statements for procedure here
	
	DECLARE @tCustomers tCustomer ;
	DECLARE @tCustno tCustno ;
	DECLARE @Class TABLE (part_class char(8));
	DECLARE @Type TABLE (part_type char(8));
	-- get list of customers for @userid with access
	-- even if @lcCustomer is not empty we cannot assume that the user has rights to those customers. They might just know the codes of the customers that they have no rights to
	INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid ;
	
	IF @custno is not null and @custno <>'' and @custno<>'All'
		-- from the given list select only those that @userid has an access
		INSERT INTO @tCustno SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@custno,',')
			WHERE cast(ID as char(10)) IN (SELECT Custno from @tCustomers)
	ELSE
	BEGIN
	IF @custno='All'
		-- get all the customers to which @userid has accees
		-- selct from the list of all customers for which @userid has acceess
		INSERT INTO @tCustno SELECT Custno FROM @tCustomers
	END	
	
	
	IF @PartClass is not null and @partclass <>'' and  @partclass <>'All'
		INSERT INTO @Class SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@PartClass ,',')
	IF @PartType is not null and @PartType <>'' and @PartType <>'All'
		INSERT INTO @Type  SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@PartType  ,',')
		
	IF CHARINDEX('CONSG',@PartSource )<>0 and (@custno is null or @custno ='')
	BEGIN
		-- return an empty set
		---!!! too much information?
		--select part_no,Revision,Part_class,Part_type,Part_sourc,[Status],Make_buy,Descript,Uniq_key from INVENTOR where 1=0
		--11/27/13 ys return different result. if no revision first field will be part_no and no uniq_key will be returned.
		if @showRevision =1
			select Uniq_key,cast('' as varchar(50)) as part from INVENTOR where 1=0
		else
			select part_no  from INVENTOR where 1=0
	END	-- CHARINDEX('CONSG',@PartSource )<>0 and @custno is null or @custno =''
	else --- IF CHARINDEX('CONSG',@PartSource )<>0 and @custno is null or @custno =''
	BEGIN
		--11/27/13 ys return different result. if no revision first field will be part_no and no uniq_key will be returned. Also will have to select distinct to avoid duplicate parts on the list
		if  @showRevision =1
		BEGIN
			select uniq_key,
				convert(varchar(50),
				CASE WHEN Part_sourc='CONSG' THEN rtrim(CustPartno)  +
					CASE WHEN CustRev='' then '' else ' | '+Custrev END 
				ELSE rtrim(part_no)+
					CASE WHEN Revision='' then '' else ' | '+REVISION END 
				END) as part
			from INVENTOR I  left outer join @tCustno  C on i.CUSTNO =c.custno
			left outer join @tCustno  M on i.BOMCUSTNO =M.custno and i.PART_SOURC ='MAKE' and i.CUSTNO =' '
			left outer join @Class PC on i.PART_CLASS =pc.part_class
			left outer join @Type PT on i.PART_TYPE = pt.part_type
			--where charindex(rtrim(part_sourc),@PartSource )<>0
			WHERE 1=CASE WHEN @paramFilter='' then 1 
					--11/27/13 YS change search to search anywhere in the part number instead of just a beginning of the part number
					--when LEFT(part_no,len(rtrim(@filter)))=@filter then 1 else 0 end
					when PATINDEX('%'+@paramFilter+'%',PART_NO)<>0 THEN 1 ELSE 0 END
			and	1= CASE WHEN @PartSource ='All' THEN 1 when charindex(rtrim(part_sourc),@PartSource )<>0 then 1 else 0 end  
			and 1=case WHEN (CHARINDEX('CONSG',@PartSource )<>0 
					or (@PartSource ='All' and Part_sourc='CONSG')  
					OR (charindex(rtrim(part_sourc),'CONSG')>0 and Part_sourc='CONSG')
					) and c.custno is not null then 1 
					WHEN CHARINDEX('CONSG',@PartSource )=0 then 1 else 0 end
			and 1= case when @MakeBuy IS null or part_sourc<>'MAKE' then 1 
					 WHEN i.PART_SOURC='MAKE' and @MakeBuy =1 AND i.make_Buy=1 THEN 1
					 WHEN i.PART_SOURC='MAKE' and @MakeBuy=0 and I.MAKE_BUY =0 THEN 1 else 0 end
			and 1 = case when @PartClass ='All' then 1
					when @PartClass <>'All' ANd pc.part_class IS NOT null	THEN 1
					when @PartClass <>'All' ANd pc.part_class IS null	THEN 0 end
			and 1 = case when @PartType ='All' then 1
					when @PartType  <>'All' ANd pt.part_type IS NOT null	THEN 1
					when @PartType <>'All' ANd pt.part_type IS null	THEN 0 end	
			and 1= case when @Status ='All' then 1
					when charindex(RTRIM(I.[STATUS]),@Status )<>0 THEN 1
					ELSE 0 END	
		END -- if  @showRevision =1			
	
	else  --- if @showRevision=1
	begin  --- else if @showRevision=1
	-- do not show revision
		select DISTINCT 
		CASE WHEN Part_sourc='CONSG' THEN CustPartno ELSE Part_no END as Part_no
		from INVENTOR I  left outer join @tCustno  C on i.CUSTNO =c.custno
		left outer join @tCustno  M on i.BOMCUSTNO =M.custno and i.PART_SOURC ='MAKE' and i.CUSTNO =' '
		left outer join @Class PC on i.PART_CLASS =pc.part_class
		left outer join @Type PT on i.PART_TYPE = pt.part_type
		--where charindex(rtrim(part_sourc),@PartSource )<>0
		WHERE 1=CASE WHEN @paramFilter='' then 1 
				--11/27/13 YS change search to search anywhere in the part number instead of just a beginning of the part number
				--when LEFT(part_no,len(rtrim(@filter)))=@filter then 1 else 0 end
				when PATINDEX('%'+@paramFilter+'%',PART_NO)<>0 THEN 1 ELSE 0 END
		and	1= CASE WHEN @PartSource ='All' THEN 1 when charindex(rtrim(part_sourc),@PartSource )<>0 then 1 else 0 end  
			and 1=case WHEN (CHARINDEX('CONSG',@PartSource )<>0 
					or (@PartSource ='All' and Part_sourc='CONSG')  
					OR (charindex(rtrim(part_sourc),'CONSG')>0 and Part_sourc='CONSG')
					) and c.custno is not null then 1 
					WHEN CHARINDEX('CONSG',@PartSource )=0 then 1 else 0 end
		and 1= case when @MakeBuy IS null or part_sourc<>'MAKE' then 1 
				 WHEN i.PART_SOURC='MAKE' and @MakeBuy =1 AND i.make_Buy=1 THEN 1
				 WHEN i.PART_SOURC='MAKE' and @MakeBuy=0 and I.MAKE_BUY =0 THEN 1 else 0 end
		and 1 = case when @PartClass ='All' then 1
				when @PartClass <>'All' ANd pc.part_class IS NOT null	THEN 1
				when @PartClass <>'All' ANd pc.part_class IS null	THEN 0 end
		and 1 = case when @PartType ='All' then 1
				when @PartType  <>'All' ANd pt.part_type IS NOT null	THEN 1
				when @PartType <>'All' ANd pt.part_type IS null	THEN 0 end	
		and 1= case when @Status ='All' then 1
				when charindex(RTRIM(I.[STATUS]),@Status )<>0 THEN 1
				ELSE 0 END	
	end -- else if @showrevision
	
	END   --- CHARINDEX('CONSG',@PartSource )<>0 and @custno is null or @custno =''
		
	
		
END