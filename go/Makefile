
calc: parse.go
	go build -o $@ $<

parse.go: parse.y go.def ../unicc.py
	python3 ../unicc.py go.def $< $@

clean:
	rm -rf calc parse.go

.PHONY: clean

