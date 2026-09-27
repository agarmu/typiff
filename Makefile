.DEFAULT_GOAL := build

.PHONY: build test test-bundled docs fmt lint check clean

build:
	cargo build --locked --release --target wasm32-unknown-unknown
	wasm-tools validate target/wasm32-unknown-unknown/release/typiff_plugin.wasm
	cp target/wasm32-unknown-unknown/release/typiff_plugin.wasm plugin.wasm

test: build
	wasm-tools validate plugin.wasm
	cargo test --locked
	tt run --no-fail-fast --no-export-ephemeral

docs: build
	mkdir -p target/docs
	typst compile --root . docs/manual.typ target/docs/typiff.pdf

fmt:
	cargo fmt --check

lint: build
	cargo clippy --locked --all-targets -- -D warnings
	cargo clippy --locked --target wasm32-unknown-unknown -- -D warnings
	tinymist lint --root . lib.typ
	tinymist lint --root . docs/manual.typ

check: fmt lint test docs

clean:
	cargo clean
	tt util clean
	rm -f plugin.wasm
