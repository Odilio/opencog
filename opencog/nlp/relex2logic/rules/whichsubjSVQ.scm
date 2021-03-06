; This is for which-subjects of SV sentences, as in
; "Which movie sucks more, "Enemy Mine" or "Event Horizon"?
; (definitely Enemy Mine)
; (AN June 2015)


(define whichsubjSVQ
	(BindLink
		(VariableList
			(var-decl "$a-parse" "ParseNode")
			(var-decl "$subj" "WordInstanceNode")
			(var-decl "$verb" "WordInstanceNode")
			(var-decl "$subj-lemma" "WordNode")
			(var-decl "$verb-lemma" "WordNode")
			(var-decl "$obj" "WordInstanceNode")
			(var-decl "$qVar" "WordInstanceNode")
		)
		(AndLink
			(word-in-parse "$subj" "$a-parse")
			(word-in-parse "$verb" "$a-parse")
			(word-lemma "$subj" "$subj-lemma")
			(word-lemma "$verb" "$verb-lemma")
			(dependency "_subj" "$verb" "$subj")
			(AbsentLink (dependency "_obj" "$verb" "$obj"))
			(dependency "_det" "$subj" "$qVar")
			(word-feat "$qVar" "which")
		)
		(ExecutionOutputLink
; XXX this is not implemented anywhere!
			(GroundedSchemaNode "scm: whichsubjSVQ-rule")
			(ListLink
				(VariableNode "$subj-lemma")
				(VariableNode "$subj")
				(VariableNode "$verb-lemma")
				(VariableNode "$verb")

			)
		)
	)
)
