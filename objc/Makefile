
calc: parse.m
	clang -Wall -o $@ $< -g -lgnustep-base -lobjc -fconstant-string-class=NSConstantString

parse.m: parse.y ../c/c.def ../unicc.py
	python3 ../unicc.py ../c/c.def $< $@

clean:
	rm -rf calc parse.m

.PHONY: clean

