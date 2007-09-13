(require-extension mysql)
(require 'regex)
(require 'lolevel)
(require 'srfi-4)
(require 'extras)
(require 'fmt)
(require 'posix)

; We've imported the jbovlaste wiki pages into the table "pages" in
; the Tiki database.  Real Tiki pages live in tiki_pages.  The goal
; is to convert the one to the other.
;
;  mysql> describe pages;
;  +------------+------------+------+-----+---------+-------+
;  | Field      | Type       | Null | Key | Default | Extra |
;  +------------+------------+------+-----+---------+-------+
;  | pagename   | text       | NO   |     |         |       |
;  | version    | int(11)    | NO   |     |         |       |
;  | time       | int(11)    | NO   |     |         |       |
;  | userid     | int(11)    | NO   |     |         |       |
;  | langid     | int(11)    | NO   |     |         |       |
;  | content    | text       | YES  |     | NULL    |       |
;  | compressed | tinyint(1) | YES  |     | 0       |       |
;  | latest     | tinyint(1) | YES  |     | 1       |       |
;  +------------+------------+------+-----+---------+-------+
;  8 rows in set (0.23 sec)
;  
;  mysql> describe tiki_pages;
;  +-----------------+------------------+------+-----+---------+----------------+
;  | Field           | Type             | Null | Key | Default | Extra          |
;  +-----------------+------------------+------+-----+---------+----------------+
;  | page_id         | int(14)          | NO   | PRI | NULL    | auto_increment |
;  | pageName        | varchar(160)     | NO   | UNI |         |                |
;  | hits            | int(8)           | YES  |     | NULL    |                |
;  | data            | mediumtext       | YES  | MUL | NULL    |                |
;  | description     | varchar(200)     | YES  |     | NULL    |                |
;  | lastModif       | int(14)          | YES  | MUL | NULL    |                |
;  | comment         | varchar(200)     | YES  |     | NULL    |                |
;  | version         | int(8)           | NO   |     | 0       |                |
;  | user            | varchar(200)     | YES  |     |         |                |
;  | ip              | varchar(15)      | YES  |     | NULL    |                |
;  | flag            | char(1)          | YES  |     | NULL    |                |
;  | points          | int(8)           | YES  |     | NULL    |                |
;  | votes           | int(8)           | YES  |     | NULL    |                |
;  | cache           | mediumtext       | YES  |     | NULL    |                |
;  | wiki_cache      | int(10)          | YES  |     | NULL    |                |
;  | cache_timestamp | int(14)          | YES  |     | NULL    |                |
;  | pageRank        | decimal(4,3)     | YES  | MUL | NULL    |                |
;  | creator         | varchar(200)     | YES  |     | NULL    |                |
;  | page_size       | int(10) unsigned | YES  |     | 0       |                |
;  | lang            | varchar(16)      | YES  |     | NULL    |                |
;  | lockedby        | varchar(200)     | YES  |     | NULL    |                |
;  | is_html         | tinyint(1)       | YES  |     | 0       |                |
;  | created         | int(14)          | YES  |     | NULL    |                |
;  +-----------------+------------------+------+-----+---------+----------------+
;  23 rows in set (0.01 sec)


(define db (mysql-connect
	     user: "tiki"
	     passwd: "Nsp4sswd"
	     db: "tiki"))

; Can only have one query against a DB handle at a time, apparently
(define db2 (mysql-connect
	     user: "tiki"
	     passwd: "Nsp4sswd"
	     db: "tiki"))

;(write (mysql-escape-string db "foo\0"))

;(exit)

(mysql-query db "select count(*) from pages;")

(fmt #t "count: " (conc
		    ((mysql-fetch-row db) "count(*)")
		    "\n"))

; Languages table; imported by hand.  Yay ghetto.
(define languages (list
		    "xx"
		    "jbo"
		    "en"
		    "hi"
		    "es"
		    "ru"
		    "zh"
		    "ar"
		    "fr"
		    "de"
		    "ja"
		    "pl"
		    "da"
		    "it"
		    "ko"
		    "ro"
		    "el"
		    "he"
		    "cs"
		    "no"
		    "fi"
		    "pt"
		    "sv"
		    "sr"
		    "tr"
		    "fa"
		    "ka"
		    "gu"
		    "sq"
		    "eu"
		    "be"
		    "id"
		    "mg"
		    "ne"
		    "sa"
		    "so"
		    "br"
		    "ch"
		    "kw"
		    "ca"
		    "la"
		    "hr"
		    "nl"
		    "hu"
		    "lt"
		    "bg"
		    "sk"
		    "sl"
		    "vi"
		    "et"
		    "gl"
		    "uk"
		    "am"
		    "cy"
		    "ga"
		    "ia"
		    "wa"
		    "tlh"
		    "art-loglan"
		    "eo"
		    "tpi"
		    "ta"
		    "test"))

(define session #f)

(let*-values
  ([(input-port output-port pid) (process "curl -s -o /dev/null -c - 'http://lojban.org/tiki/tiki-index.php'")])
  (process-wait)
  (set! session
    (conc "PHPSESSID=" (last (string-tokenize (last (read-lines input-port)))))))

(fmt #t "session: " session nl)

(process-run "curl" (list "-o" "/dev/null" "-s" "-b" session "-i"
			  "-e" "http://www.lojban.org/tiki/tiki-login_scr.php" "-L" "-d"
			  "user=rlpowell&pass=Nsp4sswd&login=login&rme=on"
			  "http://www.lojban.org/tiki/tiki-login.php"))
(process-wait)

;(mysql-query db "select * from pages where pages.time=1082087860 and pages.langid=14;")
;(mysql-query db "select * from pages where pages.pagename='samru\\'e demonstration';")
(mysql-query-foreach
  db2
  "select * from pages;"
  (lambda (row row-index)
    (let*
      ([mysql-convert
	 (lambda (content)
	   (string-substitute*
	     content
	     (list
	       ; General MySQL quoting
	       (cons "[\\\\]" "\\\\")
	       (cons "'" "\\'"))))]
       [content-convert
	 (lambda (content lang)
	   (string-substitute*
	     (mysql-convert content)
	     (list
	       ; Non-interpreted word links
	       (cons "{{([^}]*)}" "~np~-lcurly-\\1-rcurly-~/np~")
	       ; Non-interpreted page links
	       (cons "[[][[]([^]]*)[]]" "~np~-lsquare-\\1-rsquare-~/np~")
	       ; Basic natlang links
	       (cons "{([^}:!|]*)!}" "-lcurly-jvsn \\1 general=1-rcurly-")
	       ; Language-specific natlang links
	       (cons "{([^}:!|]*)!([^}:!|]*)}" "-lcurly-jvsn \\1 lang=\"\\2\" general=1-rcurly-")
	       ; Meaning-specific natlang links
	       (cons "{([^}:!|]*)!([^}:!|]*)!}" "-lcurly-jvsn \\1 meaning=\"\\2\" general=1-rcurly-")
	       ; Basic valsi links
	       (cons "{([^}:!|]*)}" "-lcurly-jvsv \\1-rcurly-")
	       ; Best-guess valsi links
	       (cons "{([^}:!|]*):g}" "-lcurly-jvsv \\1 general=1-rcurly-")
	       ; Basic Page links
	       (cons "[[]([^][|!]*)[]]" (conc "((jbovlaste import: \\1 lang " lang "))"))
	       ; alt Page links
	       (cons "[[]([^][|!]*\\|[^][|!]*)[]]" (conc "((jbovlaste import: \\1 lang " lang "))"))
	       ; Basic URL links
	       (cons "[[]([^][|!]*)![]]" "-lsquare-\\1-rsquare-")
	       ; alt URL links
	       (cons "[[]([^][|!]*)!([^][|!]*)[]]" "-lsquare-\\1|\\2-rsquare-")
	       ; Handle anything word links left
	       (cons "{([^}]*)}" "NOT HANDLED: ~np~-lcurly-\\1-rcurly-~/np~")
	       ; Handle anything page links left
	       (cons "[[]([^]]*)[]]" "NOT HANDLED: ~np~-lsquare-\\1-rsquare-~/np~")
	       ; Put the curlies/squares back
	       (cons "-lcurly-" "{")
	       (cons "-rcurly-" "}")
	       (cons "-lsquare-" "[")
	       (cons "-rsquare-" "]")
	       )
	     #t))]
       [page-lang (list-ref languages (string->number (row "langid")))]
       [new-content (content-convert (row "content") page-lang)]
       [page-name-raw
	 (conc "jbovlaste import: "
	       (row "pagename")
	       " lang "
	       page-lang)]
       [page-name-mysql (mysql-convert page-name-raw)]
       [page-name
	 (string-map
	   (lambda (x)
	     (cond [(eq? x #\space) #\+]
		   [else x]))
	   page-name-raw)]
       )
      ;(fmt #t "convert test: " (content-convert "foo'bar\\baz\\qux\n" "lang"))
      (fmt #t "page-lang: " page-lang nl)
      (fmt #t "page-name: ((" page-name-mysql ")) " nl)
      ; Create and/or blank the page
      (process-run "curl" (list "-o" "/dev/null" "-s" "-b" session "-L" "-i"
				(conc "http://www.lojban.org/tiki/tiki-editpage.php?page=" page-name)))
      (process-wait)
      (process-run "curl" (list "-o" "/dev/null" "-s" "-b" session "-L" "-i"
				"-F" "edit=empty"
				"-F" (conc "lang=" page-lang)
				"-F" "minor=Minor"
				(conc "http://www.lojban.org/tiki/tiki-editpage.php?page=" page-name)))
      (process-wait)
      ;(fmt #t "new-content: " (wrt new-content) nl)
      (sleep 1)
      (mysql-query db
		   (conc
		     "update tiki_pages set data='"
		     new-content
		     "' where tiki_pages.pagename='" page-name-mysql "';"))
      ; Refresh the page
      (process-run "curl" (list "-o" "/dev/null" "-s" "-b" session "-L" "-i"
				(conc "http://www.lojban.org/tiki/tiki-index.php?refresh=1&page=" page-name)))
      (process-wait)
      )))
