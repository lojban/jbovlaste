BEGIN;

-- TO ADD NEW LANGUAGES:
-- Add the language in the right place here, then *make a copy of
-- the file* with just that entry in it, and load that into the
-- database using:
--
-- psql -U jbovlaste jbovlaste < /tmp/language.sql
--
-- Make sure to leave the COMMIT; in at the bottom.

-- Lojban!
INSERT INTO languages (tag, englishname, lojbanname, realname, url)
 VALUES ('jbo', 'Lojban', 'jbobau', 'lojban', 'http://www.lojban.org/');

-- The six base languages
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('en', 'English', 'bangenugu', 'English', 'Lojban');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('hi', 'Hindi', 'benxe\'inu', 'हिन्दी');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('es', 'Spanish', 'bansupu\'a', 'Español');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('ru', 'Russian', 'banru\'usu', 'Русский','Ложбан');

INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('zh', 'Chinese', 'banzuxe\'o', '中文');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ar', 'Arabic', 'bangaru\'a', '‮العربية‬');

-- Others
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('fr', 'French', 'banfuru\'a', 'français');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('de', 'German', 'bandu\'e\'u', 'Deutsch', 'Lojban');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('ja', 'Japanese', 'banjupunu', '日本語', 'ロジバン' );
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('pl', 'Polish', '', 'banpu\'olu');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('da', 'Danish', 'bandu\'anu', 'Dansk');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('it', 'Italian', 'bangitu\'a', 'Italiano');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ko', 'Korean', 'banku\'oru', '한국어');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ro', 'Romanian', 'banru\'onu', 'RomÃ¢nÄ');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('el', 'Greek', 'bangelulu', 'Ελληνικά', 'Λόζμπαν');
INSERT INTO languages (tag, englishname, lojbanname, realname)
VALUES ('he', 'Hebrew', 'banxe'\ebu', 'עברית');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('cs', 'Czech','bancu\'esu','Česká');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('no', 'Norwegian', 'baurnu\'oru', 'Norsk', 'Lojban');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('fi', 'Finnish', 'banfu\'inu', 'Suomi');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('pt', 'Portuguese', 'banpu\'oru', 'Português');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('sv', 'Swedish', 'bansuve\'e', 'Svenska');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('sr', 'Serbian', 'bansurupu', 'Srpski');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('tr', 'Turkish', 'bantu\'uru', 'Türkçe');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('fa', 'Farsi', 'banfu\'asu', '‮فرسى‬');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ka', 'Georgian', 'banku\'atu', 'ქართველი'); 
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('gu', 'Gujarati', 'baurgu\'uju', 'ગુજરાતી');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('sq', 'Albanian', 'bansuke\'i', 'shqiptare');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('eu', 'Basque', 'bange\'usu', 'Euskara');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('be', 'Belarusian', 'banbu\'elu', 'Беларуская', 'Ложбан');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('id', 'Indonesian', 'banginudu', 'Bahasa Indonesia');
--INSERT INTO languages (tag, englishname, lojbanname, realname)
-- VALUES ('ms', 'Malay', 'mejbau', 'Bahasa Melayu');
--I think the 'e' is actually 0115 (ĕ), but I'm not sure.
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('mg', 'Malagasy', 'banmulugu', 'Malagasy');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ne', 'Nepali', 'baurnu\'epu', 'नेपाली');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('sa', 'Sanskrit', 'bansu\'anu', 'संस्कृत');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('so', 'Somali', 'bansu\'omu', 'Soomaali');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('br', 'Breton', 'banburu\'e', 'brezhoneg');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ch', 'Chamorro', 'bancuxe\'a', 'Chamoru');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('kw', 'Cornish', 'bancu\'oru', 'Kernewek');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ca', 'Catalan', 'bancu\'atu', 'català');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('la', 'Latin', 'banlu\'atu', 'Latina');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('hr', 'Croatian', 'banxeruvu', 'hrvatski');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('nl', 'Dutch', 'baurnuludu', 'Nederlands');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('hu', 'Hungarian', 'banxe\'unu', 'Magyarul');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('lt', 'Lithuanian', 'banlu\'itu', 'Lietuvių');

-- Not totally sure about the lojbanizations here.
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('bg', 'Bulgarian', 'banbu\'ulu', 'Български', 'Ложбан');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('sk', 'Slovak', 'bansuluku', 'Slovenský');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('sl', 'Slovenian', 'bansuluvu', 'Slovenski');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('vi', 'Vietnamese', 'banvu\'i\'e', 'Tiếng Việt');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('et', 'Estonian', 'bangesutu', 'Eesti');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('gl', 'Galician', 'baurgulugu', 'Galego');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('uk', 'Ukrainian', 'bangukuru', 'Українська');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('am', 'Amharic', 'bangamuxe', 'አማርኛ');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('cy', 'Welsh', 'bancujemu', 'Cymraeg');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ga', 'Irish', 'baurgulu\'e', 'Gaeilge');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ia', 'Interlingua', 'banginu\'a', 'Interlingua');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('wa', 'Walloon', 'banvelunu', 'Walon');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('hy', 'Armenian', 'banxeje\'e', 'հայերեն');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban )
 VALUES ('tpi', 'Tok Pisin', 'bantupu\'i', 'tok Pisin', 'tok Losban' );
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban )
 VALUES ( 'ta', 'Tamil', 'bantu\'amu', 'தமிழ்', 'யாழ்வாண்' );

-- "Exotic"
INSERT INTO languages (tag, englishname, lojbanname, realname, url)
 VALUES ('tlh', 'Klingon', 'bantuluxe', ' ', 'http://www.kli.org/');
INSERT INTO languages (tag, englishname, lojbanname, realname, url)
 VALUES ('art-loglan', 'Loglan', 'loglybau', 'loglan', 'http://www.loglan.net/');
INSERT INTO languages (tag, englishname, lojbanname, realname, url, forlojban)
 VALUES ('eo', 'Esperanto', 'bangepu\'o', 'Esperanto', 'http://www.esperanto.net/', 'Loĵbano');
INSERT INTO languages (tag, englishname, lojbanname, realname, url)
 VALUES ('art-guaspi', 'Gua\spi', 'gaspo', 'gua\spi', 'http://www.loglan.net/');

-- Simple
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('en-simple', 'Simple English', 'sampu glibau', 'Simple English');

-- ROLLBACK; if there are errors

INSERT INTO languages (tag, englishname, lojbanname, realname, url, forlojban)
 VALUES ('test', 'Test Language', 'cipybau', 'Test Language', '', 'Lojban');

-- if it worked
COMMIT;
