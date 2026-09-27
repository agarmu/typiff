#import "/lib.typ": *

#let diagnostic = test.catch(() => parse-date(2024))
#assert.ne(diagnostic, none, message: "Expected an error")
#assert(diagnostic.contains("typiff: value must be a string"), message: diagnostic)
