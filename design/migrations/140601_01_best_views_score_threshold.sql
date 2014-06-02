
BEGIN;

CREATE OR REPLACE VIEW valsibestguesses AS
  SELECT valsiid, langid, definitionid
  FROM valsibestdefinitions
  WHERE score > 0;

CREATE OR REPLACE VIEW natlangwordbestguesses AS
  SELECT wordid AS natlangwordid, definitionid, place
  FROM natlangwordbestplaces
  WHERE score > 0;

COMMIT;

