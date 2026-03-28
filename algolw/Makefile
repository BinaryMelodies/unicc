
calc: parse.alw
	awe $< -o $@

parse.alw: parse.y alw.def ../unicc.py
	python3 ../unicc.py alw.def $< $@

clean:
	rm -rf calc parse.alw

.PHONY: clean


