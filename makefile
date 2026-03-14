.PHONY: build pack install publish dev clean test

build:
	sh scripts/build.sh

pack:
	sh scripts/pack.sh

install:
	sh scripts/install.sh

publish:
	sh scripts/publish.sh

dev:
	sh scripts/dev.sh

clean:
	rm -rf build dist

test:
	sh test/run.sh
