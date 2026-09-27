#import "/lib.typ": *

#let diagnostic = test.catch(() => to-datetime(parse-zoned("2024-01-01T12:00:00+00:00[UTC]")))
#assert.ne(diagnostic, none, message: "Expected an error")
#assert(diagnostic.contains("choose clock:"), message: diagnostic)
