#import "/lib.typ": *

#let diagnostic = test.catch(() => to-datetime(parse-span("P1M")))
#assert.ne(diagnostic, none, message: "Expected an error")
#assert(diagnostic.contains("expected year/month/day or hour/minute/second fields"), message: diagnostic)
