CREATE VIEW dbo.View_GlNbrsPosting
AS
SELECT     GL_NBR, GL_DESCR, GLTYPE, STATUS
FROM         dbo.GL_NBRS
WHERE     (GL_CLASS = 'Posting') AND (STATUS = 'Active')
