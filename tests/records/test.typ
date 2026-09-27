#import "/lib.typ" as typiff

// Compare the complete public records, including nested fields, against readable
// JSON fixtures. Dictionary order and JSON whitespace are not significant.
#for case in json("expected.json") {
  assert.eq(
    (dictionary(typiff).at("parse-" + case.kind))(case.input),
    case.expected,
    message: "Record mismatch: " + case.name,
  )
}
