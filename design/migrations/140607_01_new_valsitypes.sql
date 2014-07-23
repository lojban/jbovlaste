
BEGIN;

UPDATE valsitypes set descriptor = 'cmavo-compound' WHERE typeId = 6;

INSERT INTO valsitypes (typeId, descriptor) VALUES ( 9, 'bu-letteral');
INSERT INTO valsitypes (typeId, descriptor) VALUES (10, 'zei-lujvo');
INSERT INTO valsitypes (typeId, descriptor) VALUES (11, 'obsolete cmene');
INSERT INTO valsitypes (typeId, descriptor) VALUES (12, 'obsolete fu\'ivla');
INSERT INTO valsitypes (typeId, descriptor) VALUES (13, 'obsolete zei-lujvo');

COMMIT;

