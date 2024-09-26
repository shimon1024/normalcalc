.PHONE: all image wasm clean

all: image wasm

image:
	cd .. && docker build . -f play/Dockerfile -t normalcalc-wasm

wasm:
	docker run --rm -v "$$(pwd):/home/app/play" normalcalc-wasm cp nci.wasm play/

clean:
	rm -f nci.wasm
