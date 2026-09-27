#import "/lib.typ": *

#let diagnostic = test.catch(() => parse-date("2023-02-29"))
#assert.ne(diagnostic, none, message: "Expected an error")
#assert(diagnostic.contains("invalid date:"), message: diagnostic)
