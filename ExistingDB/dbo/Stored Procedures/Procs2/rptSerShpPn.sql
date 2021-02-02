-- =============================================
-- Author:		Debbie
-- Create date:	02/09/2012
-- Description:	This Stored Procedure was created for the Serial Number Ship History by Part Number
-- Reports:		sershppt.rpt
-- Modified:		11/04/15 DRP:  added @userId, /*CUSTOMER LIST*/ and changed other parameters to work with the WebReports
-- =============================================
CREATE PROCEDURE [dbo].[rptSerShpPn]

--declare
		@lcUniq_key varchar(max) = 'aLL'
		--@lcPart char(25) = '*'			--11/04/15 DRP:  REMOVED
		--,@lcRev Char(8) = '*'				--11/04/15 DRP:  REMOVED
		,@lcDateStart as smalldatetime= NULL
		,@lcDateEnd as smalldatetime = NULL
		,@userId uniqueidentifier= NULL
		
AS 
BEGIN

/*PART LIST*/
DECLARE @tUniq_Key TABLE (Uniq_key char(10))

IF @lcUniq_key is not null and @lcUniq_key <>'' and @lcUniq_key<>'All'
			insert into @tUniq_key select * from dbo.[fn_simpleVarcharlistToTable](@lcUniq_key,',')
							
ELSE
		IF  @lcUniq_key='All'	
		BEGIN
			INSERT INTO @tUniq_key 
						SELECT	distinct inventor.uniq_key 
						FROM	packlser 
								inner join sodetail on PACKLSER.UNIQUELN = sodetail.UNIQUELN
								inner join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
		END


/*RECORD SELECTION*/
SELECT	SODETAIL.uniq_key,Part_no, Revision, Part_class, Part_type, Descript, Sodetail.Sono, Packlser.Packlistno,LINE_NO, ShipDate
		,cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) as SerialNo 
FROM	Packlser
		inner join sodetail on PACKLSER.UNIQUELN = sodetail.UNIQUELN
		inner join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
		inner join PLMAIN  on packlser.PACKLISTNO = plmain.PACKLISTNO
where	
		--Part_no = case when @lcPart='*' then PART_NO else @lcPart END			--11/04/15 DRP: REMOVED
		--and REVISION = case when @lcRev = '*' then REVISION else @lcRev end	--11/04/15 DRP: REMOVED
		plmain.SHIPDATE>=@lcDateStart AND plmain.SHIPDATE<@lcDateEnd+1
		and (@lcUniq_key='All' OR exists (select 1 from @tUniq_Key t inner join INVENTOR I on t.Uniq_key=I.UNIQ_KEY where I.UNIQ_KEY = SODETAIL.UNIQ_KEY))	--11/04/15 DRP:  ADDED
end
			