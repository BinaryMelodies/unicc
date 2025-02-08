
all: c java cs pascal basic f77

clean:
	make -C c clean
	make -C java clean
	make -C cs clean
	make -C pascal clean
	make -C basic clean
	make -C f77 clean

distclean: clean
	rm -rf *~ */*~

c:
	make -C c

java:
	make -C java

cs:
	make -C cs

pascal:
	make -C pascal

basic:
	make -C basic

f77:
	make -C f77

.PHONY: all clean distclean c java cs pascal basic f77
