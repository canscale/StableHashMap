default:
	for file in *.mo; do \
		$(shell vessel bin)/moc $(shell vessel sources) -wasi-system-api -o TestA.wasm "$$file" && wasmtime TestA.wasm && rm -f TestA.wasm; \
	done