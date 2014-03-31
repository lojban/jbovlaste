
-- This migration is part of the fix for issue #21
-- https://github.com/lojban/jbovlaste/issues/21

BEGIN;

-- disallow duplicate natural words with null meaning

CREATE UNIQUE INDEX natlangwords_unique_langid_word_null
  ON natlangwords(langid, word)
  WHERE meaning IS NULL;

-- disallow non-null but blank meaning

UPDATE natlangwords
  SET meaning = NULL
  WHERE meaning = '';

ALTER TABLE natlangwords
  ADD CONSTRAINT natlangwords_meaning_nonempty
  CHECK( length(meaning) > 0 );

ALTER TABLE natlangwordvotes
  ALTER value TYPE integer;
-- one single non-integer value is rounded to 1

UPDATE natlangwordvotes v
SET natlangwordid = ww.wordid
  FROM natlangwords w, definitions d, natlangwords ww
  WHERE w.wordid = v.natlangwordid AND w.meaning IS NULL
    AND d.definitionid = v.definitionid
    AND ww.langid = d.langid
    AND ww.word = w.word AND ww.meaning IS NULL
    AND NOT EXISTS
      (SELECT 1 FROM natlangwordvotes
       WHERE userid = v.userid
         AND natlangwordid = ww.wordid);

UPDATE natlangwordvotes v
SET natlangwordid = ww.wordid
  FROM natlangwords w, definitions d, natlangwords ww
  WHERE w.wordid = v.natlangwordid
    AND d.definitionid = v.definitionid
    AND ww.langid = d.langid
    AND ww.word = w.word AND ww.meaning = w.word
    AND NOT EXISTS
      (SELECT 1 FROM natlangwordvotes
       WHERE userid = v.userid
         AND natlangwordid = ww.wordid);
-- this didn't update any rows (relevant words already have votes for users)
-- but is included for completeness

DELETE
FROM natlangwordvotes v
USING natlangwords w, definitions d
WHERE w.wordid = v.natlangwordid
  AND d.definitionid = v.definitionid
  AND w.langid <> d.langid;

-- this deletes ~20 votes that couldn't be cleaned up above, either because
-- the user has already voted for the natlangword or because no natlangword
-- could be found in the language of the definition which matches the word
-- and meaning

COMMIT;

