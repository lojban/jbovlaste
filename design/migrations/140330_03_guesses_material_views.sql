
BEGIN;

CREATE TEMPORARY VIEW definitionscores AS
  SELECT valsiid, langid, definitionid, min(time) AS time, sum(value) AS score
  FROM definitionvotes
  GROUP BY valsiid, langid, definitionid;

CREATE TEMPORARY VIEW definitionranks AS
  SELECT valsiid, langid, definitionid, score, row_number() OVER scores
  FROM definitionscores
  WINDOW scores AS (PARTITION BY valsiid, langid ORDER BY score DESC, time);
-- favoring older definitions with tie scores over newer ones

DROP VIEW IF EXISTS valsibestguesses;

DROP TABLE IF EXISTS valsibestdefinitions;

CREATE TABLE valsibestdefinitions(

  valsiid      integer NOT NULL,
  langid       integer NOT NULL,
  definitionid integer NOT NULL,
  score        integer NOT NULL,

  CONSTRAINT valsibestdefinitions_pkey
    PRIMARY KEY (valsiid, langid),

  CONSTRAINT valsibestdefinitions_valsiid
    FOREIGN KEY (valsiid) REFERENCES valsi(valsiid),
  CONSTRAINT valsibestdefinitions_langid
    FOREIGN KEY (langid) REFERENCES languages(langid),
  CONSTRAINT valsibestdefinitions_definitionid
    FOREIGN KEY (definitionid) REFERENCES definitions(definitionid)

);

CREATE INDEX valsibestdefinitions_definitionid_key
  ON valsibestdefinitions (definitionid);

INSERT INTO valsibestdefinitions
  SELECT valsiid, langid, definitionid, score
  FROM definitionranks
  WHERE row_number = 1;

CREATE OR REPLACE FUNCTION reset_valsibestdefinition(_valsiid integer, _langid integer)
RETURNS VOID
LANGUAGE plpgsql
AS $$
  DECLARE
    _new RECORD;
  BEGIN

    SELECT valsiid, langid, definitionid, min(time) as time, sum(value) AS score
      INTO _new
      FROM definitionvotes
      WHERE valsiid = _valsiid AND langid = _langid
      GROUP BY valsiid, langid, definitionid
      ORDER BY score DESC, time
      LIMIT 1;

    DELETE
      FROM valsibestdefinitions
      WHERE valsiid = _valsiid AND langid = _langid;

    IF _new IS NOT NULL THEN
      INSERT
        INTO valsibestdefinitions (valsiid, langid, definitionid, score)
        VALUES (_new.valsiid, _new.langid, _new.definitionid, _new.score);
    END IF;

  END;
$$;

CREATE OR REPLACE FUNCTION reload_valsibestdefinitions()
RETURNS VOID
LANGUAGE plpgsql
AS $$
  DECLARE
    _row RECORD;
  BEGIN

    TRUNCATE valsibestdefinitions;

    FOR _row IN
      SELECT DISTINCT valsiid, langid
        FROM definitionvotes
    LOOP
      PERFORM reset_valsibestdefinition(_row.valsiid, _row.langid);
    END LOOP;

  END;
$$;

CREATE OR REPLACE FUNCTION refresh_valsibestdefinitions_for_upsert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM reset_valsibestdefinition(NEW.valsiid, NEW.langid);
    RETURN NULL;
  END;
$$;

CREATE OR REPLACE FUNCTION refresh_valsibestdefinitions_for_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM reset_valsibestdefinition(OLD.valsiid, OLD.langid);
    RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS on_definitionvotes_insert ON definitionvotes;

CREATE TRIGGER on_definitionvotes_insert
  AFTER INSERT
    ON definitionvotes
  FOR EACH ROW
    EXECUTE PROCEDURE refresh_valsibestdefinitions_for_upsert();

DROP TRIGGER IF EXISTS on_definitionvotes_update ON definitionvotes;

CREATE TRIGGER on_definitionvotes_update
  AFTER UPDATE
    ON definitionvotes
  FOR EACH ROW
    EXECUTE PROCEDURE refresh_valsibestdefinitions_for_upsert();

DROP TRIGGER IF EXISTS on_definitionvotes_delete ON definitionvotes;

CREATE TRIGGER on_definitionvotes_delete
  AFTER DELETE
    ON definitionvotes
  FOR EACH ROW
    EXECUTE PROCEDURE refresh_valsibestdefinitions_for_delete();

CREATE VIEW valsibestguesses AS
  SELECT valsiid, langid, definitionid
  FROM valsibestdefinitions;

--

CREATE TEMPORARY VIEW natlangdefinitionscores AS
  SELECT natlangwordid AS wordid, definitionid, place, min(time) AS time, sum(value) AS score
  FROM natlangwordvotes
  GROUP BY wordid, definitionid, place;

CREATE TEMPORARY VIEW natlangdefinitionranks AS
  SELECT wordid, definitionid, place, score, row_number() OVER scores
  FROM natlangdefinitionscores
  WINDOW scores AS (PARTITION BY wordid ORDER BY score DESC, time);

DROP VIEW IF EXISTS natlangwordbestguesses;

DROP TABLE IF EXISTS natlangwordbestplaces;

CREATE TABLE natlangwordbestplaces(

  wordid       integer NOT NULL,
  definitionid integer NOT NULL,
  place        integer NOT NULL,
  score        integer NOT NULL,

  CONSTRAINT natlangwordbestplaces_pkey
    PRIMARY KEY (wordid),

  CONSTRAINT natlangwordbestplaces_wordid
    FOREIGN KEY (wordid) REFERENCES natlangwords(wordid),
  CONSTRAINT natlangwordbestplaces_definitionid
    FOREIGN KEY (definitionid) REFERENCES definitions(definitionid)

);

CREATE INDEX natlangwordbestplaces_definitionid_key
  ON natlangwordbestplaces (definitionid);

INSERT INTO natlangwordbestplaces
  SELECT wordid, definitionid, place, score
  FROM natlangdefinitionranks
  WHERE definitionid IS NOT NULL AND row_number = 1;

CREATE OR REPLACE FUNCTION reset_natlangwordbestplace(_wordid integer)
RETURNS VOID
LANGUAGE plpgsql
AS $$
  DECLARE
    _new RECORD;
  BEGIN

    SELECT natlangwordid AS wordid, definitionid, place, min(time) AS time, sum(value) AS score
      INTO _new
      FROM natlangwordvotes
      WHERE natlangwordid = _wordid
      GROUP BY wordid, definitionid, place
      ORDER BY score DESC, time
      LIMIT 1;

    DELETE
      FROM natlangwordbestplaces
      WHERE wordid = _wordid;

    IF _new IS NOT NULL THEN
      INSERT
        INTO natlangwordbestplaces (wordid, definitionid, place, score)
        VALUES (_new.wordid, _new.definitionid, _new.place, _new.score);
    END IF;

  END;
$$;

CREATE OR REPLACE FUNCTION reload_natlangwordbestplaces()
RETURNS VOID
LANGUAGE plpgsql
AS $$
  DECLARE
    _wordid integer;
  BEGIN

    TRUNCATE natlangwordbestplaces;

    FOR _wordid IN
      SELECT DISTINCT natlangwordid AS wordid
        FROM natlangwordvotes
    LOOP
      PERFORM reset_natlangwordbestplace(_wordid);
    END LOOP;

  END;
$$;

CREATE OR REPLACE FUNCTION refresh_natlangwordbestplaces_for_upsert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM reset_natlangwordbestplace(NEW.natlangwordid);
    RETURN NULL;
  END;
$$;

CREATE OR REPLACE FUNCTION refresh_natlangwordbestplaces_for_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    PERFORM reset_natlangwordbestplace(OLD.natlangwordid);
    RETURN NULL;
  END;
$$;

DROP TRIGGER IF EXISTS on_natlangwordvotes_insert ON natlangwordvotes;

CREATE TRIGGER on_natlangwordvotes_insert
  AFTER INSERT
    ON natlangwordvotes
  FOR EACH ROW
    EXECUTE PROCEDURE refresh_natlangwordbestplaces_for_upsert();

DROP TRIGGER IF EXISTS on_natlangwordvotes_update ON natlangwordvotes;

CREATE TRIGGER on_natlangwordvotes_update
  AFTER UPDATE
    ON natlangwordvotes
  FOR EACH ROW
    EXECUTE PROCEDURE refresh_natlangwordbestplaces_for_upsert();

DROP TRIGGER IF EXISTS on_natlangwordvotes_delete ON natlangwordvotes;

CREATE TRIGGER on_natlangwordvotes_delete
  AFTER DELETE
    ON natlangwordvotes
  FOR EACH ROW
    EXECUTE PROCEDURE refresh_natlangwordbestplaces_for_delete();

DROP TABLE IF EXISTS natlangwordbestguesses;

CREATE VIEW natlangwordbestguesses AS
  SELECT wordid AS natlangwordid, definitionid, place
  FROM natlangwordbestplaces;

COMMIT;

