
-- added 2nd parameter that is @lAss = .T., only bring Depts = "ACTG" for accounting supervisor to edit, otherwise
-- the user is a supervisor, the supervisor will be able to edit all <> "ACTG" records

-- 07/24/12 VL changed Users.Supervisor = 0 in @cWhereFrom = 'ACT' part to 'Users.lAss = CASE WHEN @lAddSuperUse =0 THEN 0 ELSE USERS.lAss END'

CREATE PROC [dbo].[Rights_v] @pUniqUser AS CHAR(10) = '',@cWhereFrom CHAR(3) = 'MNX' ,@lAddSuperUse as bit=0
 AS

IF @cWhereFrom = 'MNX'
	WITH ZRights as
	(
	SELECT Users.Userid, Items.Screenname, Rights.Sview, Rights.Sedit, Rights.Scopy, Rights.Sdelete, Rights.Sadd, Rights.Rview,Rights.Rprint, Rights.Rfax, Rights.Rcreate, 
		Financdata, Sall, Rall, Rights.Depts, Remail, Rfile, Items.Number, Items.Screendesc, Rights.Uniq_right,RIGHTS.FK_uniqUser,RIGHTS.Fk_Uniquenum,
		CAST(CASE WHEN x.Options IS NULL THEN 0 ELSE 1 END as bit) as Options 
		 FROM Items INNER JOIN Rights ON Items.UNIQUENUM  = Rights.Fk_Uniquenum
		 INNER JOIN Users ON Users.UNIQ_USER =RIGHTS.FK_uniqUser
		OUTER APPLY  (select MAX(SecOptionUk) as Options from SecOption Where  SecOption.ScreenName =Items.Screenname) as X 
	 WHERE  Items.Depts <> 'ACTG'
	 AND (Items.App<>' ' OR (Items.App=' ' AND ScreenName = 'SREPCOMM'))
	   AND  Rights.FK_uniqUser  =  @pUniqUser
	)
	SELECT ZRights.* FROM ZRights 
	UNION	   
	SELECT  Users.Userid, Items.Screenname, CAST(0 as bit) as Sview, CAST(0 as bit) as Sedit, CAST(0 as bit) as Scopy, 
		CAST(0 as bit) as Sdelete, CAST(0 as bit) as Sadd, CAST(0 as bit) as Rview,CAST(0 as bit) as Rprint, 
		CAST(0 as bit) as Rfax, CAST(0 as bit) as Rcreate, 
		CAST(0 as bit) as Financdata, CAST(0 as bit) as Sall, CAST(0 as bit) as Rall, 
		Items.Depts, CAST(0 as bit) as Remail, CAST(0 as bit) as Rfile, 
		Items.Number, Items.Screendesc, CAST('' as CHAR(10)) as Uniq_right,
		Users.UNIQ_USER as FK_uniqUser,ITEMS.UNIQUENUM as Fk_Uniquenum,
		CAST(CASE WHEN x.Options IS NULL THEN 0 ELSE 1 END as bit) as Options 
		FROM ITEMS CROSS JOIN Users
		OUTER APPLY  (select MAX(SecOptionUk) as Options from SecOption Where  SecOption.ScreenName =Items.Screenname) as X 
		WHERE Users.UNIQ_USER = @pUniqUser
		AND Users.SUPERVISOR = CASE WHEN @lAddSuperUse =0 THEN 0 ELSE USERS.SUPERVISOR END
		AND Items.Depts <> 'ACTG'
		AND ITEMS.Installed =1
		AND (Items.App<>' ' OR (Items.App=' ' AND ScreenName = 'SREPCOMM'))
		AND NOT EXISTS (SELECT FK_uniqUser From zRights where zRIGHTS.FK_uniqUser =@pUniqUser and zRights.Fk_Uniquenum =ITEMS.UNIQUENUM )
		
	 
ELSE
	WITH ZRights as
	(
	SELECT Users.Userid, Items.Screenname, Rights.Sview, Rights.Sedit, Rights.Scopy, Rights.Sdelete, Rights.Sadd, Rights.Rview,Rights.Rprint, Rights.Rfax, Rights.Rcreate, 
		Financdata, Sall, Rall, Rights.Depts, Remail, Rfile, Items.Number, Items.Screendesc, Rights.Uniq_right,RIGHTS.FK_uniqUser,RIGHTS.Fk_Uniquenum,
		CAST(CASE WHEN x.Options IS NULL THEN 0 ELSE 1 END as bit) as Options 
		 FROM Items INNER JOIN Rights ON Items.UNIQUENUM  = Rights.Fk_Uniquenum
		 INNER JOIN Users ON Users.UNIQ_USER =RIGHTS.FK_uniqUser
		OUTER APPLY  (select MAX(SecOptionUk) as Options from SecOption Where  SecOption.ScreenName =Items.Screenname) as X 
	 WHERE  Items.Depts = 'ACTG'
	   AND  Rights.FK_uniqUser  =  @pUniqUser
	)
	SELECT ZRights.* FROM ZRights 
	UNION	   	   
	SELECT  Users.Userid, Items.Screenname, CAST(0 as bit) as Sview, CAST(0 as bit) as Sedit, CAST(0 as bit) as Scopy, 
		CAST(0 as bit) as Sdelete, CAST(0 as bit) as Sadd, CAST(0 as bit) as Rview,CAST(0 as bit) as Rprint, 
		CAST(0 as bit) as Rfax, CAST(0 as bit) as Rcreate, 
		CAST(0 as bit) as Financdata, CAST(0 as bit) as Sall, CAST(0 as bit) as Rall, 
		Items.Depts, CAST(0 as bit) as Remail, CAST(0 as bit) as Rfile, 
		Items.Number, Items.Screendesc, CAST('' as CHAR(10)) as Uniq_right,
		Users.UNIQ_USER as FK_uniqUser,ITEMS.UNIQUENUM as Fk_Uniquenum,
		CAST(0 as bit) as Options   
		FROM ITEMS CROSS JOIN Users
		WHERE Users.UNIQ_USER = @pUniqUser
		AND ITEMS.Installed =1
		AND Items.Depts = 'ACTG'
		AND Users.lAss = CASE WHEN @lAddSuperUse =0 THEN 0 ELSE USERS.lAss END
		AND NOT EXISTS (SELECT FK_uniqUser From zRights where zRIGHTS.FK_uniqUser =@pUniqUser and zRights.Fk_Uniquenum =ITEMS.UNIQUENUM )
		