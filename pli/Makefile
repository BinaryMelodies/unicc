
calc: parse.o
	ld -z muldefs -Bstatic -M -o $@ --oformat=elf32-i386 -melf_i386 -e main $< --start-group ${PLIPATH}/lib/libprf.a --end-group > calc.map

parse.o: parse.pli
	${PLIPATH}/plic $< -o $@ || [ "$$?" -eq 4 ]

parse.pli: parse.y pli.def ../unicc.py
	python3 ../unicc.py pli.def < $< > $@

clean:
	rm -rf calc calc.map parse.o parse.lst parse.pli

.PHONY:
	clean

