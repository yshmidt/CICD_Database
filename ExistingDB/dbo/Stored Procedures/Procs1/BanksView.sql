CREATE PROCEDURE [dbo].[BanksView] 
--10/16/13 YS added parameters and more columns
-- 10/18/13 YS allow csv for bk_uniq to gather all banks for a specific supplier different remit to
@bk_uniq varchar(max) = ' ' ,@internalUse bit=1
AS
--10/15/13 YS added e-bank information and filter for internal bank setup
-- use different view to get supplier and customer's e-bank information
-- 09/25/14	VL added Bank_balFC, Open_balFC, FCUsed_uniq, lIs_vitual, lis_Preferred, Currency fields for FC module
-- 07/22/15 VL changed to use PreferredWithdrawal not PreferredWithdrowal
-- 01/13/17 VL added functional currency fields
     BEGIN
     DECLARE  @Banks table (bk_uniq char(10))
     INSERT INTO @Banks SELECT * from dbo.fn_simpleVarcharlistToTable(@bk_uniq,',') 
     
      SELECT [BK_UNIQ]
      ,[BK_ACCT_NO]
      ,[ACCTTITLE]
      ,[BANK]
      ,[ACCT_TYPE]
      ,Banks.[GL_NBR]
      ,[BC_GL_NBR]
      ,[INT_GL_NBR]
      ,[BANK_BAL]
      ,[OPEN_BAL]
      ,[LAST_STMT]
      ,[XXCKNOSYS]
      ,[LastCkNo]
      ,[BKLASTSAVE]
      ,[FK_UNIQLAYOUT]
      ,[LINACTIVE]
      ,[AccountName]
      ,[RoutingNumber]
      ,[SWIFT]
      ,[BranchNumber]
      ,[CountryCode]
      ,[Address1]
      ,[Address2]
      ,[Address3]
      ,[Address4]
      ,[City]
      ,[StateCode]
      ,[ZipCode]
      ,[Country]
      ,[attention]
      ,[phone]
      ,[fax]
      ,[email]
      ,[internalUse]
      ,[PreferredDeposit]
      ,[PreferredWithdrawal]
      ,[PaymentType]
      ,[eReferenceNumber]
      ,[AutoReferenceNumber]
      ,[Bank_BalFC]
      ,[Open_BalFC]
      ,[FCUsed_Uniq]
      ,[lIs_Virtual]
      ,[lIs_Preferred]
      ,[Currency]
	  -- 01/13/17 VL added functional currency fields
      ,[Bank_BalPR]
      ,[Open_BalPR]
      ,isnull(Gl_nbrs.gl_descr,space(30)) AS ba_descr, isnull(Gl_nbrs_a.gl_descr,SPACE(30)) AS bc_descr,
		isnull(Gl_nbrs_b.gl_descr,SPACE(30)) AS ie_descr
	FROM
    banks LEFT OUTER JOIN gl_nbrs ON  Banks.gl_nbr = Gl_nbrs.gl_nbr
                 LEFT OUTER JOIN gl_nbrs Gl_nbrs_b ON Banks.int_gl_nbr =
	Gl_nbrs_b.gl_nbr
                 LEFT OUTER JOIN gl_nbrs Gl_nbrs_a  ON  Banks.bc_gl_nbr =
	Gl_nbrs_a.gl_nbr where banks.internalUse=@internalUse 
	and 1 = case when @internalUse =1 then 1 
	when BK_UNIQ IN (SELECT bk_uniq from @Banks) then 1 else 0 end 
END