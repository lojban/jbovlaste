

BEGIN;

CREATE UNIQUE INDEX valsi_unique_word_nospaces
ON valsi (replace(word, ' ', ''));

COMMIT;
