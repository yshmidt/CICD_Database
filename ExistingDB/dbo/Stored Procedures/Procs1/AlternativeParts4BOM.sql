
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/09/2014
-- Description:	return alternative parts assigned to components on the BOM, called from BOM API
-- Modified:	01/06/2015 DRP:  Added @customerStatus Filter  
-- =============================================
CREATE PROCEDURE [dbo].[AlternativeParts4BOM] 
	-- Add the parameters for the stored procedure here
	@BomParent char(10)=' ', @showSubAssembly bit=0, @IncludeMakeBuy bit=0,@customerStatus varchar (20) = 'All',  @UserId uniqueidentifier=NULL 

	-- list of parameters:
	-- 1. @BomParent - top level BOM uniq_key 
	-- 2. @showSubAssembly - explode 'MAKE' parts
	-- 2. @IncludeMakeBuy - if showSubAssembly = 1 this parameter indicates if make/buy parts will be exploded as well; if 0 - will not (default 1)
	-- 3. @UserId - check if user allowed to view a bom based on the customer list assigned to a user
	
	--- this sp will 
	----- 1. find BOM information and explode PHANTOM. It will also explode Make parts if @showSubAssembly=1. If the make part has make/buy flag and @IncludeMakeBuy=0, then Make/Buy will not be indented to the next level
	----- 2. Figure out AVL (if internal part, but BOM assigned to a customer, an appropriate consign part AVL will be found
	----- 3. Remove AVL if any AntiAvl are assigned
	AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	declare @tBom table (bomParent char(10),uniqbomno char(10),bomcustno char(10),UNIQ_KEY char(10),Part_sourc char(10) ,
		Make_buy bit,Status char(10),[Level] integer ,
		[path] varchar(max),[sort] varchar(max), CustUniqKey char(10)) ;

	DECLARE @tCustomers tCustomer ;
	INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid,null,@customerStatus ;
	
	INSERT INTO @tBom exec miniBomIndented @BomParent, @showSubAssembly, @IncludeMakeBuy 

	
	Select t.*,
		BA.Alt_for, BA.Uniq_key as AltUniqueKey, BA.BOMALTUNIQ, I.part_class, I.part_type,I.custno, I.part_no, 
		I.revision,I.custpartno, I.custrev, I.descript, I.part_sourc, I.matltype
	FROM Bom_alt BA INNER JOIN @tBom t on t.Bomparent = Ba.Bomparent 
	INNER JOIN Inventor I ON I.Uniq_key = Ba.Uniq_key
	INNER JOIN @tCustomers C on t.bomcustno=c.custno
 	

END  