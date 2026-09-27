#import "/lib.typ": *

#let diagnostic = test.catch(() => parse-zoned("2024-03-10T02:30:00-05:00[America/New_York]"))
#assert.ne(diagnostic, none, message: "Expected an error")
#assert(diagnostic.contains("invalid zoned datetime:"), message: diagnostic)
