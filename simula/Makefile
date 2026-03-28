
calc: parse.sim
	cim $< -o $@

parse.sim: parse.y sim.def ../unicc.py
	python3 ../unicc.py sim.def $< $@

clean:
	rm -rf calc parse.sim *.o

.PHONY: clean

