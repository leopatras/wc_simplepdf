%.42f: %.per 
	fglform -M $<

%.42m: %.4gl 
	fglcomp -Wall -M $*


MODS=$(patsubst %.4gl,%.42m,$(wildcard *.4gl))
FORMS=$(patsubst %.per,%.42f,$(wildcard *.per))

all:: $(MODS) $(FORMS)

run: all
	fglrun img

fglwebrun:
	git clone https://github.com/FourjsGenero/tool_fglwebrun.git fglwebrun

webrun: all fglwebrun
	fglwebrun/fglwebrun img

gdcwebrun: all fglwebrun
	GDC=1 fglwebrun/fglwebrun img

gwa.run: all
	gwarun img

clean:
	rm -f *.42? webcomponents/img/*.pdf
	rm -rf fglwebrun gwa_dist
