;
; Tools for running AIML in the AtomSpace.
;
(define-module (opencog nlp aiml))

(use-modules (srfi srfi-1))
(use-modules (opencog) (opencog nlp) (opencog exec) (opencog openpsi))

(load "aiml/bot.scm")

; ==============================================================

(define-public (token-seq-of-parse PARSE)
"
  token-seq-of-parse PARSE -- Create a list of words from input parse.

  PARSE is assumed to be a ParseNode, pointing to text that has been
  processed by RelEx.

  Example:
     (relex-parse \"I love you\")
     (map token-seq-of-parse
         (sentence-get-parses (car (get-new-parsed-sentences))))
"

	(Evaluation
		(PredicateNode "Token Sequence")
		PARSE
		(ListLink
			(remove null?
				(map word-inst-get-lemma (parse-get-words-in-order PARSE)))
		))
)

; ==============================================================

(define-public (token-seq-of-sent SENT)
"
  token-seq-of-sent -- Create a list of words from input sentence.

  SENT is assumed to be a SentenceNode, pointing to text that has been
  processed by RelEx.

  Example:
     (relex-parse \"I love you\")
     (token-seq-of-sent (car (get-new-parsed-sentences)))

  will create the following output:

     (Evaluation
        (PredicateNode \"Token Sequence\")
        (Parse \"sentence@3e975d3a-588c-400e-a884-e36d5181bb73_parse_0\")
        (List
           (Concept \"I\")
           (Concept \"love\")
           (Concept \"you\")
        ))
"
	(map token-seq-of-parse (sentence-get-parses SENT))
)

; ==============================================================

(define-public (string-tokenize SENT-STR)
"
  string-tokenize SENT-STR -- chop up SENT-STR string into word-nodes

  Example:
     (string-tokenize \"This is a test.\")
  produces the output:
     (List (Word \"this\") (Word \"is\") (Word \"a\") (Word \"test\"))

  This is a debugging utility, and not for general use!
"
	(ListLink (map
		(lambda (w) (Word w))
		(string-split SENT-STR (lambda (x) (eq? x #\ )))))
)

; --------------------------------------------------------------

(define (word-list-flatten LIST)
"
  word-list-flatten LIST -- remove nested ListLinks

  This is used for flattening out the assorted lists of words
  that result from the AIML processing utilities.

  This is not exported publically, so as to avoid pullotuing the
  namespace.

  Example: the input
     (List (Concept \"A\") (List (Concept \"B\") (Concept \"C\")))
  will be flattened to:
     (List (Concept \"A\") (Concept \"B\") (Concept \"C\"))
"

	(define (unwrap ATOM)
		(if (equal? 'ListLink (cog-type ATOM))
			(concatenate (map unwrap (cog-outgoing-set ATOM)))
			(list ATOM)))

	(if (equal? 'ListLink (cog-type LIST)) (ListLink (unwrap LIST)) LIST)
)

; --------------------------------------------------------------

(define (word-list-set-flatten SET)
"
  word-list-set-flatten LIST -- flatten all word-lists in a set.

  This is not exported publically, so as to avoid pullotuing the
  namespace.

  Example: the input
     (Set (List (Concept \"A\") (List (Concept \"B\") (Concept \"C\"))))
  will be flattened to:
     (Set (List (Concept \"A\") (Concept \"B\") (Concept \"C\")))
"
	(cond
		((equal? 'ListLink (cog-type SET))
			(word-list-flatten SET))
		((equal? 'SetLink (cog-type SET))
			(SetLink (map word-list-flatten (cog-outgoing-set SET))))
	)
)

; --------------------------------------------------------------

(define-public (aiml-get-response-wl SENT)
"
  aiml-get-response-wl SENT - Get AIML response to word-list SENT
"

	; Return #t if the rule is a aiml chat rule
	(define (chat-rule? r)
		(equal? (gdr r) (Concept "AIML chat goal")))

	; Create a BindLink
	(define (run-rule r)
(display "duuude run rule \n") (display r) (newline)
		(word-list-set-flatten
			(cog-execute!
				(Map (Implication (gaar r) (gdar r)) (Set SENT)))))

	; for now, just get the responses.
	(map run-rule
		(filter chat-rule? (psi-get-dual-rules SENT)))
)

; --------------------------------------------------------------

; AIML-tag srai -- Run AIML recursively
; srai == "stimulous-response ai"
(DefineLink
	(DefinedSchemaNode "AIML-tag srai")
	(GroundedSchemaNode "scm: do-aiml-srai"))

(define-public (do-aiml-srai x)
	(display "duuude srai recurse\n") (display x) (newline)
	(let ((resp (aiml-get-response-wl x)))
		(if (null? resp)
			'()
			(begin
				(display "duuude srai result is\n")
				(display resp) (newline)
				(display (gar (car resp))) (newline)
				; XXX FIXME -- if SRAI returns multiple repsonses, we
				; currently take just the first. Should we do something
				; else?
				(gar (car resp))))
	)
)

; AIML-tag think -- execute the arguments, silently.
(DefineLink
	(DefinedSchemaNode "AIML-tag think")
	(GroundedSchemaNode "scm: do-aiml-think"))

; Because do-aiml-think is a black-box, its arguments are
; force-evaluated by teh evaluator. Thus, there is nothing to
; do with the argument, when we get here.  Don't return anything
; (be silent).
(define-public (do-aiml-think x)
	(display "duuude think\n") (display x) (newline)
	; 'think' never returns anything
	'()
)

; AIML-tag set -- Use a StateLink to store a key-value pair
(DefineLink
	(DefinedSchemaNode "AIML-tag set")
	(GroundedSchemaNode "scm: do-aiml-set"))

(define-public (do-aiml-set KEY VALUE)
	(define flat-val (word-list-flatten VALUE))
	(display "duuude set key=") (display KEY) (newline)
	(display "duuude set value=") (display flat-val) (newline)
	(State KEY flat-val)
	flat-val
)

; AIML-tag get -- Fetch value from a StateLink key-value pair
(DefineLink
	(DefinedSchemaNode "AIML-tag get")
	(GroundedSchemaNode "scm: do-aiml-get"))

; gar discards the SetLink that the GetLink returns.
(define-public (do-aiml-get KEY)
	(gar (cog-execute! (Get (State KEY (Variable "$x"))))))

; AIML-tag bot -- Just like get, but for bot values.
(DefineLink
	(DefinedSchemaNode "AIML-tag bot")
	(GroundedSchemaNode "scm: do-aiml-get"))

; ==============================================================
;; mute the thing
*unspecified*
