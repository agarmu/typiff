#let wasm = plugin("/plugin.wasm")

#let diagnostic = test.catch(() => wasm.parse_date(bytes((255,))))
#assert.ne(diagnostic, none, message: "Expected an error")
#assert(diagnostic.contains("invalid UTF-8:"), message: diagnostic)
