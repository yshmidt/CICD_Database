-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/12/2016
-- Description:	Transfer Prospect to Customer (order configuration), @ProspectCustno is Prospect.Custno and @NewCustno is the new custno will be used in Customer table
-- Modification:
-- 06/20/17 VL changed fn_GetHomeCurrency to use fn_GetFunctionalCurrency
-- =============================================
CREATE PROCEDURE [dbo].[sp_ProspectXfertoCustomer]
	@ProspectCustno char(10) = ' ', @NewCustno char(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
BEGIN TRY
	BEGIN TRANSACTION
	DECLARE @Blinkadd char(10), @Slinkadd char(10), @lFCInstalled bit, @Fcused_Uniq char(10), @lnTableVarCnt int, @lnTotalNo int, @lnCount int,
			@Cid char(10), @Lastname char(15), @Firstname char(15), @Custno char(10), @Title char(20), @Workphone char(19), @Email char(50), @Contactfax char(19), @NewCid char(10)
	DECLARE @PContact TABLE (Cid char(10), Lastname char(15), Firstname char(15), Custno char(10), Title char(20), Workphone char(19), Email char(50), Contactfax char(19), nRecno int)

	-- 04/08/16 VL changed to get FC installed from function
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
	IF @lFCInstalled = 1
		-- 06/20/17 VL changed fn_GetHomeCurrency to use fn_GetFunctionalCurrency
		SELECT @Fcused_Uniq = dbo.fn_GetFunctionalCurrency()
	ELSE
		SELECT @Fcused_uniq = SPACE(10)

	-- Insert Customer
	SELECT @Blinkadd = dbo.fn_GenerateUniqueNumber(), @Slinkadd = dbo.fn_GenerateUniqueNumber()

	INSERT INTO Customer (Custno, Custname, Phone, Fax, Blinkadd, Slinkadd, Acct_date, Status, ModifiedDate, Fcused_uniq)
		SELECT @NewCustno AS Custno, Custname, Phone, Fax, @Blinkadd AS Blinkadd, @Slinkadd AS Slinkadd, GETDATE(), 'Active', GETDATE(), @Fcused_Uniq
			FROM Prospect 
			WHERE Custno = @ProspectCustno

	-- Billing Address
	INSERT INTO Shipbill (Linkadd, Custno, Shipto, Address1, Address2, Address3, Address4, City, State, Zip, Country, RecordType, ModifiedDate, Fcused_uniq) 
		SELECT @Blinkadd AS Linkadd, @NewCustno AS Custno, Custname, BAddress1 AS Address1, BAddress2 AS Address2, BAddress3 AS Address3, BAddress4 AS Address4, BCity AS City, 
			BState AS State, BZip AS Zip, BCountry AS Country, 'B', GETDATE(), @Fcused_Uniq AS Fcused_uniq
			FROM Prospect
			WHERE Custno = @ProspectCustno
	
	-- Shipping Address
	INSERT INTO Shipbill (Linkadd, Custno, Shipto, Address1, Address2, Address3, Address4, City, State, Zip, Country, RecordType, ModifiedDate, Fcused_uniq) 
		SELECT @Slinkadd AS Linkadd, @NewCustno AS Custno, Custname, SAddress1 AS Address1, SAddress2 AS Address2, SAddress3 AS Address3, SAddress4 AS Address4, SCity AS City, 
			SState AS State, SZip AS Zip, SCountry AS Country, 'S', GETDATE(), @Fcused_Uniq AS Fcused_uniq
			FROM Prospect
			WHERE Custno = @ProspectCustno

	-- Contact
	SET @lnTableVarCnt = 0
	INSERT INTO @PContact (Cid, Lastname, Firstname, Custno, Title, Workphone, Email, Contactfax)
		SELECT Cid, Lastname, Firstname, @NewCustno AS Custno, Title, Workphone, Email, Contactfax
			FROM PContact
			WHERE Custno = @ProspectCustno

	UPDATE @PContact SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1

	SET @lnTotalNo = @@ROWCOUNT;	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN
		SET @lnCount=@lnCount+1;
		SELECT @Cid = Cid, @Lastname = Lastname, @Firstname = Firstname, @Custno = Custno, @Title = Title, @WorkPhone = Workphone, @Email = Email, @ContactFax = ContactFax
			FROM @PContact
			WHERE nRecno = @lnCount
		EXEC GetNextCcontactNumber @NewCid OUTPUT

		INSERT INTO Ccontact (Cid, Type, Lastname, Firstname, Custno, Title, Workphone, Email, Contactfax, Status, ModifiedDate ) 
			VALUES (@NewCid, 'C', @LastName, @Firstname, @Custno, @Title, @Workphone, @Email, @Contactfax, 'Active', GETDATE())
	END

	DELETE FROM Prospect WHERE Custno = @ProspectCustno
	DELETE FROM PContact WHERE Custno = @ProspectCustno

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH	

END