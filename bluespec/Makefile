compile: mkdir -p buildDir

add: 
	bsc -u -g mkAddTest -sim -bdir buildDir -info-dir buildDir -simdir buildDir -vdir buildDir -aggressive-conditions -p +:/afs/csail.mit.edu/group/csg/tools/tools_lx86/bluespec/Bluespec-2012.10.beta2/lib/board_support/bluenoc/bridges PipelineAdder.bsv
	bsc -sim -e mkAddTest -bdir buildDir -info-dir buildDir -simdir buildDir -o simAdd

modmult: 	
	bsc -u -g mkModMultTest -sim -bdir buildDir -info-dir buildDir -simdir buildDir -vdir buildDir -aggressive-conditions -p +:/afs/csail.mit.edu/group/csg/tools/tools_lx86/bluespec/Bluespec-2012.10.beta2/lib/board_support/bluenoc/bridges ModMultIlvd.bsv
	bsc -sim -e mkModMultTest -bdir buildDir -info-dir buildDir -simdir buildDir -o simMult

modexpt: 	
	bsc -u -g mkModExptTest -sim -bdir buildDir -info-dir buildDir -simdir buildDir -vdir buildDir -aggressive-conditions -p +:/afs/csail.mit.edu/group/csg/tools/tools_lx86/bluespec/Bluespec-2012.10.beta2/lib/board_support/bluenoc/bridges ModExpt.bsv
	bsc -sim -e mkModExptTest -bdir buildDir -info-dir buildDir -simdir buildDir -o simExpt


all: add

clean:
	rm -rf buildDir sim*

.PHONY: clean all compile comb pipe mult
.DEFAULT_GOAL := all
