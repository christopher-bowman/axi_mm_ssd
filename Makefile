#
#	Copyright (c) 2023 by Christopher R. Bowman. All rights reserved.
#

fake:
	(cd hardware && make)
	(cd software && make)

clean:
	(cd hardware && make clean)
	(cd software && make clean)
	
.PHONY: fake clean
