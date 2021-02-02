-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/23/14
-- Description:	using in the desktop INVT fomr. Maybe absoleete but need to have to for now
--- 09/28/17 YS convert mfgrmasterid to in from bigint untill desktop is gone. bigInt in vfp becomes char(20)
-- =============================================
CREATE PROCEDURE [dbo].[MfgrMasterView]
	-- Add the parameters for the stored procedure here
	@Uniq_key char(10)='' --- uniq_key to find all MPNs assigned to a uniq_key
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT convert(int,[MfgrMasterId]) as [MfgrMasterId]
      ,[PartMfgr]
      ,[mfgr_pt_no]
      ,[mfgrDescript]
      ,[Root]
      ,[marking]
      ,[body]
      ,[pitch]
      ,[part_spec]
      ,[part_pkg]
      ,[uniqpkg]
      ,[is_deleted]
      ,[MatlType]
      ,[autolocation]
      ,[MATLTYPEVALUE]
      ,[LDISALLOWBUY]
      ,[LDISALLOWKIT]
      ,[SFTYSTK]
      ,[MOISTURE]
      ,[EICCSTATUS]
      ,[LifeCycle]
      ,[PTLENGTH]
      ,[PTWIDTH]
      ,[PTDEPTH]
      ,[ptwt]
      ,[qtyPerPkg]
      ,[shelfLife]
      ,[IsSynchronizedFlag]
      ,[countryofOrigin]
		from MfgrMaster where exists (select 1 from Invtmpnlink where uniq_key=@Uniq_key and invtmpnlink.mfgrmasterid=mfgrMaster.mfgrmasterid)
END