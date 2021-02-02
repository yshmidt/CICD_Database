CREATE TABLE [dbo].[WCChkList] (
    [WCChkID]       INT           IDENTITY (1, 1) NOT NULL,
    [Dept_ID]       CHAR (4)      NOT NULL,
    [WCChkName]     VARCHAR (100) NOT NULL,
    [WCChkPriority] INT           NOT NULL,
    CONSTRAINT [PK_WCChkList] PRIMARY KEY CLUSTERED ([WCChkID] ASC)
);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/28/2021
-- Description:	Modify check list name on all routings that are assigned to assemblies
-- =============================================
CREATE TRIGGER [dbo].[WCChkList_UPDATE] 
   ON  [dbo].[WCChkList] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	/* find all the routings that have the old check list name and replace. Only if the name is changed */
	;with updateAssyCheckList
	as
	(
	select i.WCChkName,d.WCChkName as oldCheckName, pc.WRKCKUNIQ 
	from  INSERTED I 
	INNER JOIN DELETED D on I.WCChkID=D.WCChkID and i.WCChkName<>D.WCChkName  
	INNER JOIN WRKCKLST PC
	on pc.DEPT_ACTIV=i.Dept_ID and pc.CHKLST_TIT=D.WCChkName
	where not EXISTS (select 1 from WRKCKLST where WRKCKLST.UNIQ_KEY=pc.uniq_key and WRKCKLST.TemplateId=pc.TemplateId
	and WRKCKLST.DEPT_ACTIV=pc.DEPT_ACTIV  and WRKCKLST.CHKLST_TIT=i.WCChkName)
                                                                                        
	)
	update WRKCKLST set CHKLST_TIT=u.WCChkName
	from updateAssyCheckList u where u.WRKCKUNIQ=WRKCKLST.WRKCKUNIQ
END
GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/28/2021
-- Description:	Add new check list to all routings that are assigned to assemblies
-- =============================================
CREATE TRIGGER dbo.WCChkList_INSERT 
   ON  dbo.WCChkList 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	/* find all the routings that do not have the check list already. Even though the check list is new to the setting table, 
	the user could have manually added the same check list in the routing for the assembly. To avoid duplicating we will have to check for existance */
	;with updateAssyCheckList
	as
	(
	select rps.Uniquerout,rps.uniq_key,rps.TemplateID,
	q.dept_id,q.number,q.UNIQNUMBER,wc.WCChkName,wc.WCChkPriority
	from routingProductSetup rps
	inner join inventor i on rps.Uniq_key=i.UNIQ_KEY
	inner join quotdept q on rps.uniquerout=q.uniqueRout and rps.Uniq_key=q.UNIQ_KEY
	inner join INSERTED WC on q.DEPT_ID=wc.dept_id
	where i.STATUS='Active'
	and  not exists
	(select * from WRKCKLST PC where pc.UNIQNUMBER=q.UNIQNUMBER and dept_activ=wc.DEPT_ID and pc.chklst_TIT=wc.WCChkName)
	)
	insert into WRKCKLST (UNIQ_KEY,dept_activ,UNIQNUMBER,number,CHKLST_TIT, WRKCKUNIQ,TemplateId,wccheckpriority)
	select u.Uniq_key,u.DEPT_ID,u.UNIQNUMBER,u.NUMBER,u.WCChkName, dbo.fn_GenerateUniqueNumber(),u.TemplateID,u.WCChkPriority 
	from updateAssyCheckList U

END