CC=emcc
DEBUGFLAGS = -O3
CFLAGS = $(DEBUGFLAGS) -s USE_ZLIB=1

pplibsources = $(wildcard src/*.c)
pplibutilsources = $(wildcard src/util/*.c)


pplibobjects = $(pplibsources:.c=.o)
pplibutilobjects = $(pplibutilsources:.c=.o)

pplib: $(pplibobjects) $(pplibutilobjects) 
	emar rcs pplib.a $(pplibobjects)  $(pplibutilobjects)

$(pplibobjects): %.o: %.c
	$(CC) -c $(CFLAGS) -I. -Isrc/ -Isrc/util/ $< -o $@

clean:
	rm -f src/*.o src/util/*.o
	
