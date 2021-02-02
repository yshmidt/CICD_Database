-- =============================================
-- Modified:	08/04/2014 DRP:  needed to add the Supplier Selection list to the procedure so we are sure that we are only displaying results for the suppliers the user is approved to view.
--							added the pjctmain table to the statement.  then changed the @lcPrjNumber to be the prjunique instead of the Prjnumber.  This is so we could be consistant with the value we pass from the parameters. 
--				12/12/14 DS Added supplier status filter
-- =============================================
CREATE PROCEDURE [dbo].[QkViewOpenPObyPJView] 

	@lcPrjNumber char(10) = ''
	, @userId uniqueidentifier=null
	,@supplierStatus varchar(20) = 'All'

AS
BEGIN


--08/04/2014 ADDED THE SUPPLIER LIST BELOW

/*GATHERS THE LIST OF SUPPLIERS THE USER IS APPROVED TO SEE*/
	DECLARE  @tSupplier tSupplier
	 --get list of Suppliers for @userid with access
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, @supplierStatus ;
	 
	 
/*RECORD SELECTION*/
	SET NOCOUNT ON;

	SELECT	ISNULL(Inventor.PART_NO, Poitems.PART_NO) AS Part_no, ISNULL(Inventor.Revision, Poitems.Revision) AS Revision,
			ISNULL(Inventor.Part_class, SPACE(8)) AS Part_Class, ISNULL(Inventor.Part_type, SPACE(8)) AS Part_type,
			ISNULL(Inventor.Descript, SPACE(45)) AS Descript, Poitems.Ponum, SUM(Schd_qty) AS Schd_qty, SUM(Balance) AS Balance, Poitems.Uniqlnno,PRJNUMBER
	FROM	Pomain,PJCTMAIN, Poitschd, Poitems LEFT OUTER JOIN Inventor 
			ON Inventor.Uniq_key = Poitems.Uniq_key 			
	WHERE	Poitschd.Uniqlnno = Poitems.Uniqlnno 
			AND Pomain.Ponum = Poitems.Ponum 
			--AND Poitschd.woprjnumber = @lcPrjNumber	--08/04/2014 DRP:  replaced with the below.
			AND PJCTMAIN.PRJUNIQUE = @lcPrjNumber
			AND Poitschd.RequestTp='Prj Alloc'
			AND Poitems.lCancel = 0
			and pomain.UNIQSUPNO in (select UNIQSUPNO from @tSupplier) --08/04/2014 DRP:  added to make sure only po's that the user is approved to see those suppliers
			and rtrim(POITSCHD.WOPRJNUMBER) = PJCTMAIN.PRJNUMBER	--08/04/2014 DRP: added the pjctmain table so the parameter could be off of the prjunique  
	GROUP BY Poitems.Uniqlnno,ISNULL(Inventor.PART_NO, Poitems.PART_NO),ISNULL(Inventor.Revision, Poitems.Revision),
			ISNULL(Inventor.Part_class, SPACE(8)),ISNULL(Inventor.Part_type, SPACE(8)), ISNULL(Inventor.Descript, SPACE(45)), Poitems.Ponum,PRJNUMBER
	ORDER BY 1 

END

