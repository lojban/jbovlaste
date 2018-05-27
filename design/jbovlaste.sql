BEGIN;

DROP TABLE comments, definitions, definitionvotes, etymology, example,
keywordmapping, languages, natlangwords, pages,
threads, users, valsi, valsitypes, natlangwordvotes, xrefs
CASCADE;

-- DROP VIEW convenientcomments, convenientdefinitions, convenientetymology,
-- convenientexamples, convenientthreads, convenientvalsi;

-- DROP SEQUENCE comments_commentid_seq,  definitions_definitionid_seq,
-- etymology_etymologyid_seq,  example_exampleid_seq,  languages_langid_seq,
-- natlangwords_wordid_seq,  threads_threadid_seq,  users_userid_seq,
-- valsi_valsiid_seq;

DROP FUNCTION pages_sanity_check();

COMMIT;

BEGIN;

-- people authorized to insert data into the database
CREATE TABLE users (
  userId serial primary key, -- unique user id
  username varchar(64) not null unique, -- unique username
  password char(32) not null, -- password! they're all md5sum'd
  email text not null, -- email address
  realname text,       -- "real name"
  url text,            -- some url
  personal text,       -- some wiki-marked text about them

  votesize real default 0.0 -- the secret size of their vote
);

-- null user
INSERT INTO users (userId, username, password, email, realname, url,
 personal, votesize) VALUES (0, 'nobody', '***', 'nobody@localhost',
 'nobody', 'http://nowhere/', 'nothing', 0.0);

-- table describing the languages for which data is present
CREATE TABLE languages (
  langId serial primary key, -- unique language id
  tag varchar(128) not null, -- ISO/IANA language tag for the language
  englishname text not null, -- english name of the language
  lojbanname text not null,  -- lojban name of the language
  realname text not null,    -- full in-language name of the language, unicode
  forlojban text,   	     -- The word for Lojban in the language
  url text                   -- url for info about the language
);

-- null language
INSERT INTO languages (langId, tag, englishname, lojbanname, realname, forlojban, url)
 VALUES	(0, 'xx', 'nolanguage', 'nolanguage', 'nolanguage', 'noforlojban', 'http://nowhere/');

-- wiki pages
CREATE TABLE pages (
 pagename text not null,     -- name of the page, utf8
 version int4 not null,      -- version of the page
 time int4 not null,         -- time created
 userId int4 not null,       -- user id of the submitter
 langId int4 not null,       -- language of the page (should be invariant)
 content text,               -- wiki marked content of the page
 compressed boolean          -- indicates whether or not the content
    default 'false',         -- field is gzip compressed data.
                             -- to be used for old versions of a page
 latest boolean              -- for each set of pages with (pagename,langId) 
    default 'true',          -- only the one with the highest version should
                             -- have this set to true
 PRIMARY KEY ( pagename, version, langId )
);

ALTER TABLE pages ADD CONSTRAINT pages_userId
 FOREIGN KEY (userId) REFERENCES users MATCH FULL;
ALTER TABLE pages ADD CONSTRAINT pages_langId
 FOREIGN KEY (langId) REFERENCES languages MATCH FULL;

CREATE FUNCTION pages_sanity_check () RETURNS OPAQUE AS '
 DECLARE
   expectedVersion int4;
 BEGIN
   UPDATE pages SET latest = \'false\' WHERE pagename = NEW.pagename
       AND langId = NEW.langId;
   expectedVersion := (SELECT max(version)+1 FROM pages WHERE
       pagename = NEW.pagename AND langId = NEW.langId);
   IF (NEW.version != expectedVersion) THEN
     RAISE EXCEPTION ''page was not inserted with the expected version %'', expectedVersion;
   END IF;
   RETURN NEW;
 END;
' LANGUAGE 'plpgsql';

CREATE TRIGGER pages_sanity_check BEFORE INSERT ON pages
  FOR EACH ROW EXECUTE PROCEDURE pages_sanity_check();

-- allowable wordtypes
CREATE TABLE valsitypes (
  typeId int2 primary key,        -- arbitrary ID
  descriptor varchar(128) unique  -- "gismu", "lujvo", "cmavo-compound", etc
);

INSERT INTO valsitypes (typeId, descriptor) VALUES (0, 'nalvla');
INSERT INTO valsitypes (typeId, descriptor) VALUES (1, 'gismu');
INSERT INTO valsitypes (typeId, descriptor) VALUES (2, 'cmavo');
INSERT INTO valsitypes (typeId, descriptor) VALUES (3, 'cmevla');
INSERT INTO valsitypes (typeId, descriptor) VALUES (4, 'lujvo');
INSERT INTO valsitypes (typeId, descriptor) VALUES (5, 'fu\'ivla');
INSERT INTO valsitypes (typeId, descriptor) VALUES (6, 'cmavo-compound');
INSERT INTO valsitypes (typeId, descriptor) VALUES (7, 'experimental gismu');
INSERT INTO valsitypes (typeId, descriptor) VALUES (8, 'experimental cmavo');
INSERT INTO valsitypes (typeId, descriptor) VALUES (9, 'bu-letteral');
INSERT INTO valsitypes (typeId, descriptor) VALUES (10, 'zei-lujvo');
INSERT INTO valsitypes (typeId, descriptor) VALUES (11, 'obsolete cmevla');
INSERT INTO valsitypes (typeId, descriptor) VALUES (12, 'obsolete fu\'ivla');
INSERT INTO valsitypes (typeId, descriptor) VALUES (13, 'obsolete zei-lujvo');
INSERT INTO valsitypes (typeId, descriptor) VALUES (14, 'obsolete cmavo');
INSERT INTO valsitypes (typeId, descriptor) VALUES (15, 'phrase');

-- table of lojban words
CREATE TABLE valsi (
  valsiId serial primary key, -- the unique id
  word text not null unique,  -- the word itself
  typeId int2 not null references valsitypes, -- gismu, cmavo, lujvo, etc etc
  userId int4 not null,       -- user id of the submitter
  rafsi text,		      -- space-seperated list of rafsi this word has, if any
  time int4 not null          -- time of submission
);

-- null valsi
INSERT INTO valsi (valsiId, word, typeId, userId, time)
 VALUES (0, '', 0, 0, 0);

ALTER TABLE valsi ADD CONSTRAINT valsi_userId
 FOREIGN KEY (userId) REFERENCES users MATCH FULL;

CREATE INDEX valsi_lower_word ON valsi(lower(word));

CREATE UNIQUE INDEX valsi_unique_word_nospaces ON valsi (replace(word, ' ', ''));

-- words, things, etc in natural languages, probably be a big big table
CREATE TABLE natlangwords (
  wordId serial primary key,        -- unique word id
  langId int4 not null,             -- the language the word belongs to
  word text not null,               -- the word itself
  meaning text,                     -- a constraint on the meanining
                                    -- of the word
  meaningNum int4 not null,         -- the number of this meaning, as
				    -- opposed to other identical words
				    -- with different meanings
  userId int4 not null,       -- user id of the submitter
  time int4 not null,          -- time of submission
  notes text,
  UNIQUE(langId, word, meaning)
);

-- the null natural language word
INSERT INTO natlangwords (wordId, langId, word, meaningNum, userId, time)
 VALUES (0, 0, ' ', 0, 0, 0);

ALTER TABLE natlangwords ADD CONSTRAINT natlangwords_langId
 FOREIGN KEY (langId) REFERENCES languages MATCH FULL;

CREATE INDEX natlangwords_lower_word ON natlangwords(lower(word));

-- Definitions of lojban valsi in other languages
--
-- Definitions need to be numbered on a per-lang-per-word basis, so that
-- we can present that number to the user in the interface so that users
-- can talk about "definition number 5", or whatever.
CREATE TABLE definitions (
  langId int4 not null,              -- the language that the definition is in
  valsiId int4 not null,             -- corresponding valsi
  definitionNum int4 not null,       -- The number of this definion, on
				     -- a per-lang, per-word basis.
  definitionId serial primary key,	     -- unique definition id, for convenience
  definition text not null,          -- text of the definition.
                                     -- place structure for all selbri
  notes text,                        -- little bits of additional, non-def
                                     -- info

  jargon text,			     -- not null if this is
				     -- domain-specific jargon;
				     -- value is the type of jargon
				     -- it is

  userId int4 not null,              -- contributing user
  time int4 not null,                -- time of contribution
  selmaho text,		      	     -- What selma'o this word belongs to, if any 
  UNIQUE ( langId, valsiId, definitionNum )
);

-- null definition
INSERT INTO definitions (definitionId, langId, valsiId, definitionNum,
                         definition, userId, time)
 VALUES (0, 0, 0, 0, '', 0, 0);

ALTER TABLE definitions ADD CONSTRAINT definitions_langId
 FOREIGN KEY (langId) REFERENCES languages MATCH FULL;
ALTER TABLE definitions ADD CONSTRAINT definitions_valsiId
 FOREIGN KEY (valsiId) REFERENCES valsi MATCH FULL;
ALTER TABLE definitions ADD CONSTRAINT definitions_userId
 FOREIGN KEY (userId) REFERENCES users MATCH FULL;

-- provides the keywords for each defined place of a given definition,
-- including the gloss word (which is place 0)
CREATE TABLE keywordmapping (
  natlangwordId int4 references natlangwords, 	    -- ID of the natlang word
  definitionId int4 references definitions, -- ID of the definition
  place int2 not null, 			    -- zero for the gloss word
  PRIMARY KEY (natlangwordId, definitionId, place)
);

ALTER TABLE keywordmapping ADD CONSTRAINT keywordmapping_natlangwordId
 FOREIGN KEY (natlangwordId) REFERENCES natlangwords MATCH FULL;
ALTER TABLE keywordmapping ADD CONSTRAINT keywordmapping_defbestguessId
  FOREIGN KEY (definitionId) REFERENCES definitions MATCH FULL;

-- DEPRECATED 
-- -- maps glosswords for a definition to natlang words
-- CREATE TABLE glosswordmapping (
--   definitionId int4 references definitions, -- ID of the definition
--   wordId int4 references natlangwords       -- ID of the natlang word
-- );

-- votes for which definition in a given language best matches a given
-- valsi
CREATE TABLE definitionvotes (
  valsiId int4 not null,      -- the valsi the definition corresponds to
  langId int4 not null,       -- the language id of the definition
  definitionId int4 not null, -- the definition receiving the vote
  value real not null,        -- value of the vote
  userId int4 not null,       -- user id of the vote
  time int4 not null,         -- the time of the voting
  PRIMARY KEY (valsiId, langId, userId)
);

ALTER TABLE definitionvotes ADD CONSTRAINT definitionvotes_valsiId
 FOREIGN KEY (valsiId) REFERENCES valsi MATCH FULL;
ALTER TABLE definitionvotes ADD CONSTRAINT definitionvotes_langId
 FOREIGN KEY (langId) REFERENCES languages MATCH FULL;
ALTER TABLE definitionvotes ADD CONSTRAINT definitionvotes_definitionId
 FOREIGN KEY (definitionId) REFERENCES definitions MATCH FULL;
ALTER TABLE definitionvotes ADD CONSTRAINT definitionvotes_userId
 FOREIGN KEY (userId) REFERENCES users MATCH FULL;

-- votes for which valsi best corresponds to a given natlang word
CREATE TABLE natlangwordvotes (
  natlangwordId int4 references natlangwords,-- the natlang word we're picking a valsi for
  definitionid int4 references definitions,	-- definition receiving the vote
  place int4 not null,      			-- the exact place receiving the vote, within the definition
  userId int4 references users,       -- the person who voted
  value real not null,        -- the value of the vote
  time int4 not null,         -- the time at which they voted
  PRIMARY KEY (natlangwordId, userId)
);

-- ALTER TABLE natlangwordvotes ADD CONSTRAINT natlangwordvotes_valsiId
--  FOREIGN KEY (valsiId) REFERENCES valsi MATCH FULL;
-- ALTER TABLE natlangwordvotes ADD CONSTRAINT natlangwordvotes_langId
--  FOREIGN KEY (langId) REFERENCES languages MATCH FULL;
ALTER TABLE natlangwordvotes ADD CONSTRAINT natlangwordvotes_natlangwordId
 FOREIGN KEY (natlangwordId) REFERENCES natlangwords MATCH FULL;
ALTER TABLE natlangwordvotes ADD CONSTRAINT natlangwordvotes_voter
 FOREIGN KEY (userId) REFERENCES users MATCH FULL;

-- threads
CREATE TABLE threads (
  threadId serial primary key, -- unique id for each thread
  valsiId int4 not null,       -- id of the valsi it is about (0 if about
                               -- a natlang word)
  natlangwordId int4 not null, -- id of the natlang word it is about (0 if
	                       -- about a valsi)
  definitionId int4 not null	-- Comments should be per-definition
				-- A 0 definitionId means the comment
				-- refers to the word as a whole.
);

INSERT INTO threads (threadId, valsiId, natlangwordId, definitionId)
 VALUES (0, 0, 0, 0);

ALTER TABLE threads ADD CONSTRAINT threads_valsiId
 FOREIGN KEY (valsiId) REFERENCES valsi MATCH FULL;
ALTER TABLE threads ADD CONSTRAINT natlangwordId_natlangwordId
 FOREIGN KEY (natlangwordId) REFERENCES natlangwords MATCH FULL;

-- threaded comments
CREATE TABLE comments (
  commentId serial primary key, -- unique id for each comment
  threadId int4 not null,       -- to which thread does the comment belong
  parentId int4 not null,       -- what is it in response to? (toplevel = 0)
  userId int4 not null,         -- poster
  commentNum int4 not null,	-- Comments should be uniquely numbered
  time int4 not null,           -- time of post

  subject text,                 -- the subject line for the comment
  content text                  -- the body of the comment wiki-marked
);

-- the null comment
INSERT INTO comments (commentId, threadId, parentId, userId,
time, commentNum)
 VALUES (0, 0, 0, 0, 0, 0);

ALTER TABLE comments ADD CONSTRAINT comments_threadId
 FOREIGN KEY (threadId) REFERENCES threads MATCH FULL;
ALTER TABLE comments ADD CONSTRAINT comments_parentId
 FOREIGN KEY (parentId) REFERENCES comments MATCH FULL;
ALTER TABLE comments ADD CONSTRAINT comments_userId
 FOREIGN KEY (userId) REFERENCES users MATCH FULL;

-- a cross referencing table, between anything
-- for instance:
-- * to link together two natlang words in different languages
CREATE TABLE xrefs (
  srctype int2 not null,   -- there will be some as yet undecided set of
                           -- values for this, which will be of the same
                           -- types as desttype
  srcId int4 not null,     -- the unique id. wiki pages will use hash codes
                           -- of the pagename. maybe. or something. same
                           -- for destid
  desttype int2 not null,
  destId int4 not null
);

-- stores origin information for a word
-- * particularly useful for fu'ivla and cmevla
-- * could also be used to store the whatnot that went into the gismu
-- * creation algorithm, in the case of gismu.

CREATE TABLE etymology (
  etymologyId serial unique,    -- needed to be able to go back and edit a specific
                         -- bit of etymological data.
  valsiId int4 not null, -- etymology is only given for valsi
  langId int4 not null,  -- allows etymologic info in any language
  content text,          -- the wiki-marked text

  time int4 not null,    -- time of this bits contribution
  userId int4 not null   -- the user who contributed it
);

ALTER TABLE etymology ADD CONSTRAINT etymology_valsiId
 FOREIGN KEY (valsiId) REFERENCES valsi MATCH FULL;
ALTER TABLE etymology ADD CONSTRAINT etymology_langId
 FOREIGN KEY (langId) REFERENCES languages MATCH FULL;
ALTER TABLE etymology ADD CONSTRAINT etymology_userId
 FOREIGN KEY (userId) REFERENCES users MATCH FULL;

-- stores an example usage of a valsi
CREATE TABLE example (
  exampleId serial unique,      -- needed to be able to go back and edit a specific
                         -- bit of etymological data.
  valsiId int4 not null, -- examples provided only for valsi
  definitionId int4 not null,	-- Examples should be per-definition
				-- A 0 definitionId means the example
				-- refers to the word as a whole.
  exampleNum int4 not null,	-- They should also be numbered
  content text,          -- the wiki-marked text

  time int4 not null,    -- time of the bits contribution
  userId int4 not null   -- user who contributed it
);

ALTER TABLE example ADD CONSTRAINT example_valsiId
 FOREIGN KEY (valsiId) REFERENCES valsi MATCH FULL;
ALTER TABLE example ADD CONSTRAINT example_userId
 FOREIGN KEY (userId) REFERENCES users MATCH FULL;

CREATE VIEW convenientcomments AS
    SELECT c.commentid, c.threadid, c.parentid, c.userid, u.username,
    u.realname, c."time", c.subject, c.content, c.commentNum
    FROM comments c, users u
    WHERE (u.userid = c.userid);

CREATE VIEW convenientetymology AS
    SELECT e.etymologyId, v.word, e.valsiid, l.tag, l.realname,
    l.langid, e.content, e."time", u.username, u.userid
    FROM etymology e, valsi v, languages l, users u
    WHERE (((e.userid = u.userid)
	AND (e.langid = l.langid))
	AND (e.valsiid = v.valsiid));

CREATE VIEW convenientexamples AS
    SELECT e.exampleId, v.word, e.valsiid, e.content,
    e."time", u.username, u.userid, e.examplenum, e.definitionid
    FROM valsi v, example e, users u
    WHERE ((v.valsiid = e.valsiid) AND (u.userid = e.userid));

CREATE VIEW convenientdefinitions AS
    SELECT nd.definitionid, l.realname as langrealname, l.tag,
    l.langid, v.valsiid, v.word, nd.definition, nd.notes,
    u.username, u.userid, nd."time", nd.definitionNum, v.rafsi,
    nd.selmaho, nd.jargon
    FROM definitions nd, languages l, valsi v, users u
    WHERE nd.langid = l.langid AND nd.valsiid = v.valsiid
	AND nd.userid = u.userid;

CREATE VIEW convenientthreads AS
    SELECT t.threadid, t.valsiid, v.word AS valsi,
    t.natlangwordid, nlw.word AS natlangword, l.tag, t.definitionId
    FROM threads t, valsi v, natlangwords nlw, languages l
    WHERE t.valsiid = v.valsiid
	AND t.natlangwordid = nlw.wordid
	AND nlw.langid=l.langid;

CREATE VIEW convenientvalsi AS
    SELECT v.valsiId, v.word, t.descriptor as type, v.typeId,
    u.username, v.userId, v.time, v.rafsi
    FROM valsi v, valsitypes t, users u
    WHERE v.typeId=t.typeId AND v.userId=u.userId;

-- ROLLBACK; if there are errors

-- if it worked
COMMIT;
