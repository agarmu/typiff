#{
  import "/lib.typ": *

  let date = parse-date("2024-02-29")
  assert.eq(date.text, "2024-02-29")
  assert.eq(date.year, 2024)
  assert.eq(date.month, 2)
  assert.eq(date.day, 29)
  assert.eq(date.weekday, "thursday")
  assert.eq(date.at("day-of-year"), 60)

  let time = parse-time("15:04:05.123")
  assert.eq(time.hour, 15)
  assert.eq(time.minute, 4)
  assert.eq(time.second, 5)
  assert.eq(time.nanosecond, 123000000)

  let dt = parse-datetime("2024-07-11T01:14:00")
  assert.eq(dt.text, "2024-07-11T01:14:00")

  let timestamp = parse-timestamp("2024-07-11T01:14:00Z")
  assert.eq(timestamp.epoch.seconds, 1720660440)

  let zoned = parse-zoned("2024-07-10T21:14:00-04:00[America/New_York]")
  assert.eq(zoned.zone, "America/New_York")
  assert.eq(zoned.offset, "-04")
  assert.eq(zoned.timestamp.text, "2024-07-11T01:14:00Z")

  let span = parse-span("P1Y2M3DT4H5M6S")
  assert.eq(span.text, "P1Y2M3DT4H5M6S")
  assert.eq((span.years, span.months, span.days, span.hours, span.minutes, span.seconds), (1, 2, 3, 4, 5, 6))
  assert.eq(parse-span("-P1DT2H").days, -1)
  assert.eq(parse-span("-P1DT2H").hours, -2)
  assert.eq(parse-span("P2W").weeks, 2)
  assert.eq(parse-span("PT90M").minutes, 90)

  assert.eq(to-datetime(parse-date("2024-02-29")), datetime(year: 2024, month: 2, day: 29))
  assert.eq(to-datetime(parse-time("15:04:05")), datetime(hour: 15, minute: 4, second: 5))
  assert.eq(
    to-datetime(parse-datetime("2024-07-11T01:14:00")),
    datetime(year: 2024, month: 7, day: 11, hour: 1, minute: 14, second: 0),
  )
  assert.eq(
    to-datetime(parse-timestamp("2024-07-11T01:14:00Z")),
    datetime(year: 2024, month: 7, day: 11, hour: 1, minute: 14, second: 0),
  )
  assert.eq(
    to-datetime(parse-zoned("2024-07-10T21:14:00-04:00[America/New_York]"), clock: "local"),
    datetime(year: 2024, month: 7, day: 10, hour: 21, minute: 14, second: 0),
  )

  // Parsing preserves fractional seconds; native conversion truncates them.
  assert.eq(parse-time("23:59:59.999999999").nanosecond, 999999999)
  assert.eq(to-datetime(parse-time("23:59:59.999999999")), datetime(hour: 23, minute: 59, second: 59))
  assert.eq(
    to-datetime(parse-datetime("2024-12-31T23:59:59.999999999")),
    datetime(year: 2024, month: 12, day: 31, hour: 23, minute: 59, second: 59),
  )

  // Epoch seconds use floor division; all nanosecond fields are nonnegative.
  let before-epoch = parse-timestamp("1969-12-31T23:59:58.75Z")
  assert.eq(before-epoch.epoch.seconds, -2)
  assert.eq(before-epoch.nanosecond, 750000000)
  assert.eq(before-epoch.second, 58)
  assert.eq(parse-timestamp("1969-12-31T23:59:59.5Z").epoch.seconds, -1)
  assert.eq(parse-timestamp("1969-12-31T23:59:59.5Z").nanosecond, 500000000)
  assert.eq(
    to-datetime(parse-timestamp("1969-12-31T23:59:59.5Z")),
    datetime(year: 1969, month: 12, day: 31, hour: 23, minute: 59, second: 59),
  )
  assert.eq(parse-timestamp("1970-01-01T00:00:00Z").epoch.seconds, 0)

  // UTC conversion can cross a calendar boundary.
  assert.eq(
    to-datetime(parse-timestamp("2024-01-01T00:30:00+01:00")),
    datetime(year: 2023, month: 12, day: 31, hour: 23, minute: 30, second: 0),
  )

  // Both occurrences of a repeated DST wall time have distinct instants.
  let early = "2024-11-03T01:30:00-04:00[America/New_York]"
  let late = "2024-11-03T01:30:00-05:00[America/New_York]"
  assert.eq(parse-zoned(early).timestamp.text, "2024-11-03T05:30:00Z")
  assert.eq(parse-zoned(late).timestamp.text, "2024-11-03T06:30:00Z")
  assert.eq(to-datetime(parse-zoned(early), clock: "local"), to-datetime(parse-zoned(late), clock: "local"))
  assert.eq(
    parse-zoned("2024-03-10T01:59:59-05:00[America/New_York]").timestamp.text,
    "2024-03-10T06:59:59Z",
  )
  assert.eq(
    parse-zoned("2024-03-10T03:00:00-04:00[America/New_York]").timestamp.text,
    "2024-03-10T07:00:00Z",
  )

  // Fixed-offset zones do not have an IANA name.
  let fixed = parse-zoned("2024-01-01T12:00:00+05:30[+05:30]")
  assert.eq(fixed.zone, none)
  assert.eq(fixed.offset, "+05:30")
  assert.eq(fixed.timestamp.text, "2024-01-01T06:30:00Z")
  assert.eq(parse-zoned("2024-01-01T12:00:00.123+05:30[+05:30]").nanosecond, 123000000)
  assert.eq(
    to-datetime(parse-zoned("2024-01-01T12:00:00.123+05:30[+05:30]"), clock: "local"),
    datetime(year: 2024, month: 1, day: 1, hour: 12, minute: 0, second: 0),
  )

  // Calendar limits, year zero, and century leap-year rules.
  for (text, year) in (("-009999-01-01", -9999), ("0000-01-01", 0), ("9999-12-31", 9999)) {
    assert.eq(parse-date(text).year, year)
    assert.eq(to-datetime(parse-date(text)).year(), year)
  }
  assert.eq(parse-date("2000-02-29").at("day-of-year"), 60)
  assert.eq(parse-date("1900-03-01").at("day-of-year"), 60)
  assert.eq(parse-span("-P1DT2H").text, "-P1DT2H")

  // Lock down the serialized schema, including absent fields and weekday spelling.
  let date-fields = ("year", "month", "day", "weekday", "day-of-year")
  let time-fields = ("hour", "minute", "second", "nanosecond")
  for (result, fields) in (
    (date, date-fields),
    (time, time-fields),
    (dt, date-fields + time-fields),
    (timestamp, date-fields + time-fields + ("epoch",)),
    (zoned, date-fields + time-fields + ("timestamp", "zone", "offset")),
    (span, ("years", "months", "weeks", "days", "hours", "minutes", "seconds", "milliseconds", "microseconds", "nanoseconds")),
  ) {
    assert.eq(result.keys().sorted(), (("text",) + fields).sorted())
    assert.eq(type(result.text), str)
    for field in fields {
      if field not in ("weekday", "timestamp", "zone", "offset", "epoch") {
        assert.eq(type(result.at(field)), int)
      }
    }
  }
  for (index, weekday) in ("monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday").enumerate() {
    assert.eq(parse-date("2024-01-0" + str(index + 1)).weekday, weekday)
  }

  // Structured timestamp composition and explicit conversion agree.
  assert.eq(zoned.timestamp, parse-timestamp(zoned.timestamp.text))
  assert.eq(to-datetime(zoned, clock: "utc"), to-datetime(zoned.timestamp))
  assert.eq(to-datetime(timestamp, clock: "utc"), to-datetime(timestamp))
  assert.eq(before-epoch.epoch, (seconds: -2, nanosecond: 750000000))
  assert.eq(parse-span("P1M").months, 1)
  assert.eq(date.day-of-year, 60)
  assert.eq(to-datetime(date).display("[weekday repr:long]"), "Thursday")
  assert.eq(to-datetime(zoned, clock: "local").display("[hour]:[minute]"), "21:14")
  assert.eq(to-datetime(zoned, clock: "utc").display("[hour]:[minute]"), "01:14")
  assert.ne(to-datetime(parse-zoned(early), clock: "utc"), to-datetime(parse-zoned(late), clock: "utc"))

  // Results remain ordinary data: serializable, comparable, and reconstructible.
  let encoded = bytes(json.encode(zoned))
  let decoded = json(encoded)
  assert.eq(decoded, zoned)
  assert.eq(to-datetime(decoded, clock: "utc"), to-datetime(zoned, clock: "utc"))
  for (parser, result) in (
    (parse-date, date), (parse-time, time), (parse-datetime, dt),
    (parse-timestamp, timestamp), (parse-zoned, zoned), (parse-span, span),
  ) {
    assert.eq(parser(result.text), result)
  }
  // Conversion also accepts dictionaries assembled by callers.
  assert.eq(to-datetime((year: 2024, month: 2, day: 29, label: "birthday")),
    datetime(year: 2024, month: 2, day: 29))
  assert.eq(to-datetime((hour: 12, minute: 30, second: 5, text: none, epoch: "ignored")),
    datetime(hour: 12, minute: 30, second: 5))
  assert.eq(to-datetime((timestamp: (year: 2024, month: 2, day: 29)), clock: "utc"),
    datetime(year: 2024, month: 2, day: 29))
  assert.eq(to-datetime((hour: 12, minute: 0, second: 0, timestamp: none), clock: "local"),
    datetime(hour: 12, minute: 0, second: 0))

}
