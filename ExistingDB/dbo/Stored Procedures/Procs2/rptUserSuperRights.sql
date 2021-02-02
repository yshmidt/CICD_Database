
-- =============================================
-- Author:			Debbie
-- Create date:		11/20/15
-- Description:		Created for the Supervisor Rights Report
-- Reports:			supervsr
-- Modified:	  
-- =============================================
create PROCEDURE [dbo].[rptUserSuperRights]


@userId uniqueidentifier=null	


as
begin

/*USER LIST*/		
	DECLARE  @tUser as table(UserId char(8),name char(15),firstname char(15))
		DECLARE @User as table(UserId char(10))

	insert into @tUser select UserId,name,firstname from Users where	(SUPERVISOR =1 ) or (LASS = 1)

		--select * from @user


/*RECORD SELECTION SECTION*/


select	userid,name as lastname,FIRSTNAME,workcenter,department
from	users
where	exists (select 1 from @tuser t inner join users c on t.userid=c.userid where c.userid=users.userid)


end