BEGIN;

-- Lojban!
INSERT INTO languages (tag, englishname, lojbanname, realname, url)
 VALUES ('jbo', 'Lojban', 'lobybau', 'lojban', 'http://www.lojban.org/');

-- The six base languages
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('en', 'English', 'gli\'icybau', 'English', 'Lojban');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('hi', 'Hindi', 'xinbau', 'हिन्दी');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('es', 'Spanish', 'spa\'anybau', 'Español');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('ru', 'Russian', 'rukybau', 'Русский','Ложбан');

INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('zh', 'Chinese', 'jugbau', '中文');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ar', 'Arabic', 'rabybau', '‮العربية‬');

-- Others
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('fr', 'French', 'fasybau', 'français');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('de', 'German', 'dotybau', 'Deutsch', 'Lojban');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('ja', 'Japanese', 'ponbau', '日本語', 'ロジバン' );
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('pl', 'Polish', '', 'Polski');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('da', 'Danish', '', 'Dansk');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('it', 'Italian', '', 'Italiano');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ko', 'Korean', '', '한국어');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ro', 'Romanian', '', 'RomÃ¢nÄ');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('el', 'Greek', 'xesybau', 'Ελληνικά', 'Λόζμπαν');
INSERT INTO languages (tag, englishname, lojbanname, realname)
VALUES ('he', 'Hebrew', 'xebybau', 'עברית');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('cs', 'Czech','','Česká');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban)
 VALUES ('no', 'Norwegian', '', 'Norsk', 'Lojban');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('fi', 'Finnish', '', 'Suomi');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('pt', 'Portuguese', 'potybau', 'Português');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('sv', 'Swedish', '', 'Svenska');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('sr', 'Serbian', '', 'Srpski');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('tr', 'Turkish', 'bangrtirki', 'Türkçe');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('fa', 'Farsi', '', '‮فرسى‬');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ka', 'Georgian', 'kartuli', 'ქართველი'); 
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('gu', 'Gujarati', 'gudjrati', 'ગુજરાતી');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('sq', 'Albanian', 'ckiptare', 'shqiptare');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('eu', 'Basque', 'skalduna', 'Euskara');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('be', 'Belarusian', 'labru''obau', 'Беларуски');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('id', 'Indonesian', 'bidbau', 'Bahasa Indonesia');
--INSERT INTO languages (tag, englishname, lojbanname, realname)
-- VALUES ('ms', 'Malay', 'mejbau', 'Bahasa Melayu');
--I think the 'e' is actually 0115 (ĕ), but I'm not sure.
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('mg', 'Malagasy', 'malgaci', 'Malagasy');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ne', 'Nepali', 'bangrnepali', 'नेपाली');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('sa', 'Sanskrit', 'srito', 'संस्कृत');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('so', 'Somali', 'bangrsomali', 'Soomaali');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('br', 'Breton', 'bre\'one', 'brezhoneg');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ch', 'Chamorro', 'tcamoru', 'Chamoru');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('kw', 'Cornish', 'kernauke', 'Kernewek');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ca', 'Catalan', 'katlana', 'català');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('la', 'Latin', 'latmo', 'Latina');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('hr', 'Croatian', 'bangrxrvatski', 'hrvatski');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('nl', 'Dutch', 'bangrnedrlanda', 'Nederlands');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('hu', 'Hungarian', 'banrmadiaru', 'Magyarul');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('lt', 'Lithuanian', 'bangrlietuva', 'Lietuvių');

-- Not totally sure about the lojbanizations here.
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('bg', 'Bulgarian', 'bolgaro', 'Български');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('sk', 'Slovak', 'slovako', 'Slovenský');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('sl', 'Slovenian', 'slovino', 'Slovenski');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('vi', 'Vietnamese', 'vietnama', 'Tiếng Việt');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('et', 'Estonian', 'bangrxesti', 'Eesti');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('gl', 'Galician', 'bangrgalego', 'Galego');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('uk', 'Ukrainian', 'vukro', 'Українська');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('am', 'Amharic', 'amxari', 'አማርኛ');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('cy', 'Welsh', 'kamro', 'Cymraeg');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ga', 'Irish', 'gailge', 'Gaeilge');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('ia', 'Interlingua', 'binbau', 'Interlingua');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('wa', 'Walloon', 'frasrvalona', 'Walon');
INSERT INTO languages (tag, englishname, lojbanname, realname)
 VALUES ('hy', 'Armenian', 'bangrxaiastana', 'հայերեն');
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban )
 VALUES ('tpi', 'Tok Pisin', 'bangrtokpisina', 'tok Pisin', 'tok Losban' );
INSERT INTO languages (tag, englishname, lojbanname, realname, forlojban )
 VALUES ( 'th', 'Thai', 'bangrtai', 'ภาษา��ย', 'ภาษาลอ����า�' );



-- "Exotic"
INSERT INTO languages (tag, englishname, lojbanname, realname, url)
 VALUES ('tlh', 'Klingon', 'bangrtlingana', ' ', 'http://www.kli.org/');
INSERT INTO languages (tag, englishname, lojbanname, realname, url)
 VALUES ('art-loglan', 'Loglan', 'loglan', 'loglan', 'http://www.loglan.net/');
INSERT INTO languages (tag, englishname, lojbanname, realname, url, forlojban)
 VALUES ('eo', 'Esperanto', 'spe\'atybau', 'Esperanto', 'http://www.esperanto.net/', 'Loĵbano');
-- ROLLBACK; if there are errors

-- if it worked
COMMIT;
