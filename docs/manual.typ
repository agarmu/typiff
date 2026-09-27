#import "@preview/min-manual:0.1.0": manual
#import "@preview/tidy:0.4.3"
#import "/lib.typ" as typiff

#let package = toml("../typst.toml").package


#show link: set text(font: "Inconsolata", fill:rgb("#008000"))
#show raw: set text(font: "Inconsolata")

#show: manual.with(
  title: package.name,
  description: package.description,
  cmd: none,
  version: package.version,
  license: package.license,
  authors: package.authors,
  font: "Libertinus Serif",
  paper: "us-letter",
)

This package provides thin wrappers around Jiff (#link("https://github.com/BurntSushi/jiff")).

#outline(title: none, depth: 2)

// Keep code and previews at the same size, including Tidy's doc-comment examples.
#let example-layout(code, preview, ..options) = {
  set text(size: 12.5pt)
  show raw: set text(size: 12.5pt)
  tidy.show-example.default-layout-example(code, preview, ..options)
}

// Tidy expects `typ` for markup examples; retain `typst` in the source fences.
#show raw.where(lang: "typst"): code => tidy.show-example.show-example(
  raw(code.text, lang: "typ", block: true),
  scope: dictionary(typiff),
  mode: "markup",
  layout: example-layout.with(
    dir: ttb,
    code-block: block.with(fill: luma(96%), radius: 3pt),
    preview-block: block.with(stroke: (left: 1.5pt + luma(70%))),
    col-spacing: 3pt,
  ),
)

= Usage

== Parsing
We define several parsers, which each return dictionaries. Here are some examples of usage:
#table(
  columns: (auto, 1fr),
  inset: 6pt,
  align: left,
  table.header([*Function*], [*Example Input*]),
  [`parse-date`], [`"2024-02-29"`.],
  [`parse-time`], [`"15:04:05.123456789"`.],
  [`parse-datetime`], [`"2024-07-10T21:14:00"`.],
  [`parse-timestamp`], [ `"2024-07-10T21:14:00-04:00"`],
  [`parse-zoned`], [
    `"2024-07-10T21:14:00-04:00[America/New_York]"`.
    ],
  [`parse-span`], [`"P1Y2M3DT4H5M6S"` (a calendar span)],
)

Below are a few short examples of usage:
```typst
#parse-date("2024-02-29")
```

```typst
#parse-zoned("2024-07-10T21:14:00[America/New_York]")
```

Notice that the input (after some normalization), is returned as the `text` field in the output.

== Formatting

We define a convenience function `to-datetime(`$dot$`)` which converts the type of record we work with to a native typst `datetime` object.

```typst
#let meeting = parse-zoned(
  "2024-07-10T21:14:00-04:00[America/New_York]",
)
*Meeting in Local Time:* #to-datetime(meeting, clock: "local").display(
  "[Day] [month repr:short], [hour]:[minute]"
) \
*Meeting in UTC:* #to-datetime(meeting, clock: "utc").display(
  "[Day] [month repr:short], [hour]:[minute]"
) \
```

Notice that `clock: "local"` does not use the local clock time used by the machine doing the compiling, but rather the local clock time observed by the parsed record.

#pagebreak()
= Function reference

#let api = tidy.parse-module(read("../lib.typ"), scope: dictionary(typiff))
// Fail the documentation build if a public function or annotation is omitted.
#let exports = dictionary(typiff).pairs().filter(pair => type(pair.last()) == function).map(pair => pair.first())
#assert.eq(api.functions.map(fn => fn.name).sorted(), exports.sorted())
#for fn in api.functions {
  assert(fn.description != "", message: "Missing documentation for " + fn.name)
  assert(fn.return-types != none, message: "Missing return type for " + fn.name)
  for (name, parameter) in fn.args {
    assert(parameter.description != "", message: "Missing parameter documentation: " + fn.name + "." + name)
    assert(parameter.at("types", default: none) != none, message: "Missing parameter type: " + fn.name + "." + name)
  }
}
// Use Tidy’s built-in reference renderer within the min-manual layout.
#tidy.show-module(
  api,
  style: (
    ..dictionary(tidy.styles.default),
    show-example: tidy.show-example.show-example.with(
      layout: example-layout.with(
        dir: ttb,
        code-block: block.with(fill: luma(96%), radius: 3pt),
        preview-block: block.with(stroke: (left: 1.5pt + blue)),
      ),
    ),
  ),
  first-heading-level: 1,
  show-module-name: false,
  show-outline: false,
  sort-functions: none,
  enable-tests: true,
)
