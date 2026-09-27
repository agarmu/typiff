// Dates and Times in Typst (wrapper for Jiff)

/// Parse a calendar date.
///
/// ```example
/// #let date = parse-date("2024-02-29")
/// #to-datetime(date).display("[weekday repr:long]")
/// ```
/// #test(`eq(parse-date("2024-02-29").day-of-year, 60)`)
///
/// *Returned fields*
/// #table(
///   columns: (1fr, auto),
///   align: left,
///   inset: 6pt,
///   table.header([*Field*], [*Type*]),
///   [`text`], [`str`],
///   [`year`, `month`, `day`], [`int`],
///   [`weekday`], [`str`],
///   [`day-of-year`], [`int`],
/// )
/// -> dictionary
#let parse-date(
  /// Date text.
  /// -> str
  value,
) = {
  assert(type(value) == str, message: "typiff: value must be a string")
  json(plugin("plugin.wasm").parse_date(bytes(value)))
}

/// Parse a time of day.
///
/// ```example
/// #parse-time("15:04:05.123456789").nanosecond
/// ```
/// #test(`eq(parse-time("15:04:05.123456789").nanosecond, 123456789)`)
///
/// *Returned fields*
/// #table(
///   columns: (1fr, auto),
///   align: left,
///   inset: 6pt,
///   table.header([*Field*], [*Type*]),
///   [`text`], [`str`],
///   [`hour`, `minute`, `second`, `nanosecond`], [`int`],
/// )
/// -> dictionary
#let parse-time(
  /// Time text.
  /// -> str
  value,
) = {
  assert(type(value) == str, message: "typiff: value must be a string")
  json(plugin("plugin.wasm").parse_time(bytes(value)))
}

/// Parse a date and time without a timezone.
/// Any offset or timezone in the input is discarded without converting the time.
///
/// ```example
/// #parse-datetime("2024-07-11T01:14:00").text
/// ```
/// #test(`eq(parse-datetime("2024-07-11T01:14:00").hour, 1)`)
///
/// *Returned fields*
/// #table(
///   columns: (1fr, auto),
///   align: left,
///   inset: 6pt,
///   table.header([*Field*], [*Type*]),
///   [`text`], [`str`],
///   [`year`, `month`, `day`], [`int`],
///   [`weekday`], [`str`],
///   [`day-of-year`], [`int`],
///   [`hour`, `minute`, `second`, `nanosecond`], [`int`],
/// )
/// -> dictionary
#let parse-datetime(
  /// Date and time text.
  /// -> str
  value,
) = {
  assert(type(value) == str, message: "typiff: value must be a string")
  json(plugin("plugin.wasm").parse_datetime(bytes(value)))
}

/// Convert an offset date and time to UTC.
/// `epoch.seconds` rounds down; `epoch.nanosecond` is always nonnegative.
///
/// ```example
/// #parse-timestamp("2024-07-10T21:14:00-04:00").text
/// ```
/// #test(`eq(parse-timestamp("1969-12-31T23:59:58.75Z").epoch, (seconds: -2, nanosecond: 750000000))`)
///
/// *Returned fields*
/// #table(
///   columns: (1fr, auto),
///   align: left,
///   inset: 6pt,
///   table.header([*Field*], [*Type*]),
///   [`text`], [`str`],
///   [`year`, `month`, `day`], [`int`],
///   [`weekday`], [`str`],
///   [`day-of-year`], [`int`],
///   [`hour`, `minute`, `second`, `nanosecond`], [`int`],
///   [`epoch.seconds`, `epoch.nanosecond`], [`int`],
/// )
/// -> dictionary
#let parse-timestamp(
  /// Date and time with `Z` or a numeric UTC offset.
  /// -> str
  value,
) = {
  assert(type(value) == str, message: "typiff: value must be a string")
  json(plugin("plugin.wasm").parse_timestamp(bytes(value)))
}

/// Parse a zoned date and time. Outer fields use local time; `timestamp` uses UTC.
/// `zone` is an IANA name, or `none` for a fixed offset.
/// Conflicting offsets and nonexistent local times are rejected.
///
/// ```example
/// #let meeting = parse-zoned(
///   "2024-07-10T21:14:00-04:00[America/New_York]",
/// )
/// #meeting.zone \
/// #meeting.timestamp.text
/// ```
/// #test(`eq(parse-zoned("2024-01-01T12:00:00+05:30[+05:30]").zone, none)`)
///
/// *Returned fields*
/// #table(
///   columns: (1fr, auto),
///   align: left,
///   inset: 6pt,
///   table.header([*Field*], [*Type*]),
///   [`text`], [`str`],
///   [`zone`], [`str` or `none`],
///   [`offset`], [`str`],
///   [`year`, `month`, `day`], [`int`],
///   [`weekday`], [`str`],
///   [`day-of-year`], [`int`],
///   [`hour`, `minute`, `second`, `nanosecond`], [`int`],
///   [`timestamp`], [`dictionary`],
/// )
/// The nested `timestamp` has the same fields as the dictionary returned by `parse-timestamp`.
/// -> dictionary
#let parse-zoned(
  /// Date and time with a bracketed timezone.
  /// -> str
  value,
) = {
  assert(type(value) == str, message: "typiff: value must be a string")
  json(plugin("plugin.wasm").parse_zoned(bytes(value)))
}

/// Parse a calendar span.
///
/// ```example
/// #let span = parse-span("P1Y2M3DT4H5M6S")
/// #span.years years, #span.months months, #span.days days
/// ```
/// #test(`eq(parse-span("-P1DT2H").text, "-P1DT2H")`)
///
/// *Returned fields*
/// #table(
///   columns: (1fr, auto),
///   align: left,
///   inset: 6pt,
///   table.header([*Field*], [*Type*]),
///   [`text`], [`str`],
///   [`years`, `months`, `weeks`, `days`], [`int`],
///   [`hours`, `minutes`, `seconds`], [`int`],
///   [`milliseconds`, `microseconds`, `nanoseconds`], [`int`],
/// )
/// -> dictionary
#let parse-span(
  /// Span text.
  /// -> str
  value,
) = {
  assert(type(value) == str, message: "typiff: value must be a string")
  json(plugin("plugin.wasm").parse_span(bytes(value)))
}

/// Convert to Typst's `datetime`. Fractional seconds are truncated.
/// The result has no timezone or offset. Spans are not supported.
///
/// ```example
/// #let meeting = parse-zoned(
///   "2024-07-10T21:14:00-04:00[America/New_York]",
/// )
/// #to-datetime(meeting, clock: "local").display("[hour]:[minute]") \
/// #to-datetime(meeting, clock: "utc").display("[hour]:[minute]")
/// ```
/// #test(`eq(to-datetime(parse-time("23:59:59.999")), datetime(hour: 23, minute: 59, second: 59))`)
/// -> datetime
#let to-datetime(
  /// Integer `year`, `month`, `day` and/or `hour`, `minute`, `second` fields.
  /// Extra fields are ignored; parser-generated metadata is not required.
  /// -> dictionary
  value,
  /// With a nested `timestamp`, choose `"local"` for outer fields or `"utc"`
  /// for nested fields. Otherwise, conversion uses the outer fields.
  /// -> str | none
  clock: none,
) = {
  assert(type(value) == dictionary, message: "typiff: expected a dictionary of date or time fields")
  assert(clock in (none, "local", "utc"), message: "typiff: invalid `clock`: expected \"local\", \"utc\", or none")
  if "timestamp" in value {
    assert(clock != none, message: "typiff: choose clock: \"local\" or clock: \"utc\" for this zoned value")
    if clock == "utc" {
      return to-datetime(value.timestamp)
    }
  }
  let has-date = ("year", "month", "day").any(field => field in value)
  let has-time = ("hour", "minute", "second").any(field => field in value)
  assert(has-date or has-time, message: "typiff: expected year/month/day or hour/minute/second fields")
  let fields = (
    ..if has-date { ("year", "month", "day") } else { () },
    ..if has-time { ("hour", "minute", "second") } else { () },
  )
  let components = (:)
  for field in fields {
    let component = value.at(field, default: none)
    assert(type(component) == int, message: "typiff: expected an integer in `" + field + "`")
    components.insert(field, component)
  }
  datetime(..components)
}
