
BEGIN;

UPDATE valsitypes set descriptor = 'cmevla' WHERE typeId = 3;
UPDATE valsitypes set descriptor = 'obsolete cmevla' WHERE typeId = 11;

COMMIT;

