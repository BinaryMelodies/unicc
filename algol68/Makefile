
calc: parse.a68
	${A68C} -o $@ $<

parse.a68: parse.y a68.def ../unicc.py
	python3 ../unicc.py a68.def < $< > $@

clean:
	rm -rf calc parse.a68

.PHONY: clean


