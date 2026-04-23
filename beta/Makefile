
calc: calc.bet
	beta $<

calc.bet: parse.y beta.def ../unicc.py
	python3 ../unicc.py beta.def $< $@

clean:
	rm -rf calc calc.bet *.ast linux

.PHONY: clean

