compile:
	mkdir -p buildDir
	bsc -u -g mkAddTest -sim -bdir buildDir -info-dir buildDir -simdir buildDir -vdir buildDir -aggressive-conditions -p +:/afs/csail.mit.edu/group/csg/tools/tools_lx86/bluespec/Bluespec-2012.10.beta2/lib/board_support/bluenoc/bridges PipelineAdder.bsv

add: compile
	bsc -sim -e mkAddTest -bdir buildDir -info-dir buildDir -simdir buildDir -o simAdd

all: add

clean:
	rm -rf buildDir sim*

.PHONY: clean all compile comb pipe mult
.DEFAULT_GOAL := all
