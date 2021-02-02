-- =============================================
-- Author:		Anuj Kumar
-- Create date: <11/30/2015>
-- Description:	GetItemByCreditMemo
-- =============================================
Create PROCEDURE GetItemByCreditMemo
 @creditMemoNum char(10)

AS
BEGIN

	-- If the credit memo is rma then get the accounts from sales price and cmalloc table
	--YS This is to complicate for me :) I like to keep it simple
	---If (Select 1 from CMMAIN where IS_RMA = 1 and CMEMONO = @creditMemoNum) = 1
	if EXISTS (select 1 from CMMAIN where IS_RMA = 1 and CMEMONO = @creditMemoNum)
	BEGIN
		select distinct cl.WH_GL_NBR , sp.COG_GL_NBR, cp.PL_GL_NBR as 'GL_NBR',
		--YS here is my changes . I added cast because if you have first line return short description and the second will be long the length will be cought to the length of the first line.
		--CASE
		--when sd.UNIQ_KEY<>''
		--THEN
		--('Part No: ' + inv.PART_NO + 'Revision: ' + inv.REVISION + 'Class: ' + inv.PART_CLASS + 'Type: ' + inv.PART_TYPE + 'DESCRIPTION: ' + inv.DESCRIPT)
		--ELSE sd.Sodet_Desc 
		--END as DESCRIPT
		cast( CASE WHEN cp.RECORDTYPE='P' THEN ('Part No: ' + inv.PART_NO + 'Revision: ' + inv.REVISION + 'Class: ' + inv.PART_CLASS + 'Type: ' + inv.PART_TYPE + 'DESCRIPTION: ' + inv.DESCRIPT)
		else cp.Descript end as varchar(200)) as desctipt
		,cp.CMPRICE as Price , cp.CMQUANTITY as Quantity, sd.UNIQ_KEY as UniqKey
		from 
		CMPRICES cp left outer join SOPRICES sp on cp.PLPRICELNK = sp.PLPRICELNK
		left outer join CMALLOC cl on cl.UNIQUELN = cp.UNIQUELN
		left outer join SODETAIL sd on sd.UNIQUELN = cp.UNIQUELN
		left outer join INVENTOR inv on sd.UNIQ_KEY = inv.UNIQ_KEY
		where cp.CMEMONO = @creditMemoNum
	END
	ELSE
	BEGIN
		declare @stockWarehouse char(13)
		Select top 1 @stockWarehouse = SHRI_GL_NO from INVSETUP
		select distinct @stockWarehouse as 'WH_GL_NBR' , sp.COG_GL_NBR, cp.PL_GL_NBR as 'Gl_NBR',
		CASE
		WHEN sd.UNIQ_KEY<>''
		THEN
		('Part No: ' + inv.PART_NO + 'Revision: ' + inv.REVISION + 'Class: ' + inv.PART_CLASS + 'Type: ' + inv.PART_TYPE + 'DESCRIPTION: ' + inv.DESCRIPT)
		ELSE sd.Sodet_Desc 
		END as DESCRIPT,
		cp.CMPRICE as Price , cp.CMQUANTITY as Quantity, sd.UNIQ_KEY as UniqKey
		from 
		CMPRICES cp left join SOPRICES sp on cp.PLPRICELNK = sp.PLPRICELNK
		left join SODETAIL sd on sd.UNIQUELN = cp.UNIQUELN
		left join INVENTOR inv on sd.UNIQ_KEY = inv.UNIQ_KEY
		where cp.CMEMONO = @creditMemoNum
	END

END