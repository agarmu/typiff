use super::*;
use serde_json::{Value, json};

fn parser(kind: &str) -> fn(&[u8]) -> PluginResult {
    match kind {
        "date" => parse_date,
        "time" => parse_time,
        "datetime" => parse_datetime,
        "timestamp" => parse_timestamp,
        "zoned" => parse_zoned,
        "span" => parse_span,
        _ => panic!("unknown fixture kind: {kind}"),
    }
}

fn parsed(kind: &str, value: &str) -> Value {
    serde_json::from_slice(&parser(kind)(value.as_bytes()).unwrap()).unwrap()
}

#[test]
fn invalid_utf8_is_rejected_by_every_export() {
    for kind in ["date", "time", "datetime", "timestamp", "zoned", "span"] {
        let error = parser(kind)(&[0xff]).unwrap_err();
        assert!(error.starts_with("invalid UTF-8:"), "{kind}: {error}");
    }
}

#[test]
fn invalid_values_report_the_selected_kind() {
    for (kind, value, label) in [
        ("date", "2023-02-29", "date"),
        ("time", "25:00:00", "time"),
        ("datetime", "2024-02-30T12:00:00", "datetime"),
        ("timestamp", "2024-01-01T12:00:00", "timestamp"),
        (
            "zoned",
            "2024-03-10T02:30:00-05:00[America/New_York]",
            "zoned datetime",
        ),
        ("span", "not a span", "span"),
    ] {
        let error = parser(kind)(value.as_bytes()).unwrap_err();
        let should_start_with = format!("invalid {label}:");
        assert!(error.starts_with(&should_start_with));
    }
}

#[test]
fn timestamps_normalize_offsets_without_losing_nanoseconds() {
    assert_eq!(
        parsed("timestamp", "2024-07-10T21:14:00.123456789-04:00"),
        parsed("timestamp", "2024-07-11T01:14:00.123456789Z")
    );
    assert_eq!(
        parsed("timestamp", "1969-12-31T23:59:59.999999999Z")["epoch"],
        json!({ "seconds": -1, "nanosecond": 999999999 })
    );
}

#[test]
fn fixed_offset_zones_have_no_iana_name() {
    let value = parsed("zoned", "2024-01-01T12:00:00+05:30[+05:30]");
    assert_eq!(value["zone"], Value::Null);
    assert_eq!(value["offset"], "+05:30");
    assert_eq!(
        value["timestamp"],
        parsed("timestamp", "2024-01-01T06:30:00Z")
    );
}

#[test]
fn daylight_saving_overlap_offsets_select_distinct_instants() {
    let early = parsed("zoned", "2024-11-03T01:30:00-04:00[America/New_York]");
    let late = parsed("zoned", "2024-11-03T01:30:00-05:00[America/New_York]");
    assert_eq!(early["hour"], late["hour"]);
    assert_eq!(
        late["timestamp"]["epoch"]["seconds"].as_i64().unwrap()
            - early["timestamp"]["epoch"]["seconds"].as_i64().unwrap(),
        3600
    );
}

#[test]
fn span_records_match_component_fixtures() {
    let cases: Value =
        serde_json::from_str(include_str!("../tests/records/expected.json")).unwrap();
    for case in cases.as_array().unwrap() {
        if case["kind"] == "span" {
            assert_eq!(
                parsed("span", case["input"].as_str().unwrap()),
                case["expected"],
                "{}",
                case["name"]
            );
        }
    }
}
