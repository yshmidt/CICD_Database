-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/08/2020
-- Description:	Use in the SFBL Invoice module
-- =============================================
CREATE PROCEDURE [dbo].[GetShipFirstBillLater4Customer] 
	-- Add the parameters for the stored procedure here
	@Custno char(10) = NULL, 
	@userid uniqueidentifier = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 /* error handling */  
  
	DECLARE @ErrorMessage NVARCHAR(4000);  
    DECLARE @ErrorSeverity INT;  
    DECLARE @ErrorState INT;  
    -- Insert statements for procedure here
	/*--- get customer list specific to the user in case of any restrictions */
	Declare @customerStatus varchar (20) = 'All'
	DECLARE  @tCustomer as tCustomer

	BEGIN TRY
	-- get list of customers for @userid with access
	INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
	IF (@custno IS NOT NULL) AND  EXISTS(select 1 from @tCustomer where custno=@Custno)
	BEGIN
		select i.PART_NO,i.revision,
		RTRIM(i.part_no)+CASE WHEN i.REVISION<>'' then '/'+i.revision else '' end as PartNoWithRev,
		ISNULL(c.CUSTPARTNO,space(35)) as CustPartno,Isnull(c.custrev,space(8)) as CustRev,
		CASE WHEN c.CUSTPARTNO IS NOT NULL THEN RTRIM(c.CustPartNo)+
			CASE WHEN c.custrev<>'' then  '/'+c.custrev else '' END
		ELSE --- no customer part number for selected customer
			SPACE(44) END AS CustPartNoWithRev,
		sum(qty_oh) as Balance,CAST(0.00 as numeric(12,2)) as QtyUsed,  pri.price ,
		 i.UNIQ_KEY
			from invtmfgr m inner join inventor i 
			on i.uniq_key=m.UNIQ_KEY
			/* find customer part number if exists and display in the end result*/
			LEFT OUTER JOIN Inventor c on i.UNIQ_KEY=c.INT_UNIQ and c.CUSTNO=@Custno
		cross apply 
		(select  distinct FIRST_VALUE(sp.PRICE) OVER (order by pm.shipdate) as Price 
		from invtmfgr mf
		inner  join pldetail pd on mf.LOCATION=pd.UNIQUELN
		inner join plmain pm on pd.PACKLISTNO=pm.PACKLISTNO
		inner join SOPRICES sp on pd.UNIQUELN=sp.UNIQUELN
		where SFBL=1 and pm.CUSTNO=@custno
		and m.UNIQ_KEY=mf.UNIQ_KEY
		) Pri
		where m.SFBL=1 and exists
		(select 1 from sodetail d inner join somain s on s.sono=d.sono
			where d.uniqueln=m.[location]
		and s.custno=@custno)
		group by i.UNIQ_KEY,i.PART_NO,i.revision,i.DESCRIPT,pri.price,c.CUSTPARTNO,c.custrev	
	END
	ELSE
	BEGIN
		--- Validations  
		declare @message nvarchar(max)
		set @message = CASE WHEN @Custno IS NULL THEN 'Customer is not provided ' 
				ELSE ' This user has restricted access to the customer '+@custno +'. Please check Security module for the user' END
		RAISERROR(@message,
		16,
		1);
	END
	END TRY
	BEGIN CATCH
		SELECT @ErrorMessage = ERROR_MESSAGE(),  
        @ErrorSeverity = ERROR_SEVERITY(),  
        @ErrorState = ERROR_STATE();  
		RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
               );  

	END CATCH
END