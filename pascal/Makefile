
calc: parse.pas
	fpc -o$@ $< -g

parse.pas: parse.y pas.def ../unicc.py
	python3 ../unicc.py pas.def < $< > $@

clean:
	rm -rf calc parse.pas parse.o

.PHONY: clean

