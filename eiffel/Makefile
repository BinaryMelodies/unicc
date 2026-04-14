
calc: calc.e parse.e yystype.e yyinteger.e yystring.e yydefinition.e
	compile $< -o $@

parse.e: parse.y eiffel.def ../unicc.py
	python3 ../unicc.py eiffel.def $< $@

clean:
	rm -rf calc parse.e calc*.c calc*.o calc*.h calc*.id

.PHONY: clean

