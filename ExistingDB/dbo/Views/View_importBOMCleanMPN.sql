CREATE VIEW dbo.View_importBOMCleanMPN
AS
SELECT DISTINCT L.uniq_key, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(UPPER(m.mfgr_pt_no), '_', ''), '-', ''), ' ', ''), '.', ''), '&', ''), '%', ''), '$', '') AS MFGR_PT_NO
FROM            dbo.InvtMPNLink AS L INNER JOIN
                         dbo.MfgrMaster AS m ON L.MfgrMasterId = m.MfgrMasterId
WHERE        (m.mfgr_pt_no <> '')