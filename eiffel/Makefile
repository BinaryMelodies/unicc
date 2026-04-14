
calc: calc.e parse.e yystype.e yyinteger.e yystring.e
	compile $< -o $@

parse.e: parse.y eiffel.def ../unicc.py
	python3 ../unicc.py eiffel.def $< $@

clean:
	rm -rf parse.e

.PHONY: clean

