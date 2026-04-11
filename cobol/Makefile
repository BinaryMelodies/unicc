
calc: parse.cob
	cobc -std=cobol85 -x -o $@ $<

parse.cob: parse.y cobol.def ../unicc.py
	python3 ../unicc.py cobol.def $< $@

clean:
	rm -rf calc parse.cob

.PHONY: clean

