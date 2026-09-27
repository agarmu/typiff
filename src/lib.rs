//! UTF-8 parsing exports for the Typst plugin.
//!
//! Each export accepts raw UTF-8 text and returns a JSON record with normalized
//! text and fields for that parser. Timestamps use UTC; zoned records also keep
//! local time and timezone data. Invalid UTF-8, parsing failures, and response
//! encoding failures return human-readable errors.

#[cfg(test)]
mod tests;

use jiff::{
    Span, Timestamp, Zoned,
    civil::{Date, DateTime, Time},
};
use serde_json::{Value, json};
use std::{fmt::Display, str::FromStr};
#[cfg(target_arch = "wasm32")]
use wasm_minimal_protocol::*;

#[cfg(target_arch = "wasm32")]
initiate_protocol!();

pub type PluginResult = Result<Vec<u8>, String>;

fn response(value: Value) -> PluginResult {
    serde_json::to_vec(&value).map_err(|err| format!("could not encode response: {err}"))
}

fn parse_raw<T>(input: &[u8], kind: &str) -> Result<T, String>
where
    T: FromStr,
    T::Err: Display,
{
    std::str::from_utf8(input)
        .map_err(|err| format!("invalid UTF-8: {err}"))?
        .parse()
        .map_err(|err| format!("invalid {kind}: {err}"))
}

#[cfg_attr(target_arch = "wasm32", wasm_func)]
pub fn parse_date(input: &[u8]) -> PluginResult {
    let value: Date = parse_raw(input, "date")?;
    let mut record = json!({ "text": value.to_string() });
    populate_date_fields(&mut record, value);
    response(record)
}

#[cfg_attr(target_arch = "wasm32", wasm_func)]
pub fn parse_time(input: &[u8]) -> PluginResult {
    let value: Time = parse_raw(input, "time")?;
    let mut record = json!({ "text": value.to_string() });
    populate_time_fields(&mut record, value);
    response(record)
}

#[cfg_attr(target_arch = "wasm32", wasm_func)]
pub fn parse_datetime(input: &[u8]) -> PluginResult {
    let value: DateTime = parse_raw(input, "datetime")?;
    let mut record = json!({ "text": value.to_string() });
    populate_date_fields(&mut record, value.date());
    populate_time_fields(&mut record, value.time());
    response(record)
}

#[cfg_attr(target_arch = "wasm32", wasm_func)]
pub fn parse_timestamp(input: &[u8]) -> PluginResult {
    let value: Timestamp = parse_raw(input, "timestamp")?;
    let utc = value.to_zoned(jiff::tz::TimeZone::UTC);
    let nanos = value.as_nanosecond();
    // Round seconds down so pre-epoch timestamps keep a nonnegative remainder.
    let mut record = json!({
        "text": value.to_string(),
        "epoch": {
            "seconds": nanos.div_euclid(1_000_000_000) as i64,
            "nanosecond": nanos.rem_euclid(1_000_000_000) as i32,
        },
    });
    populate_date_fields(&mut record, utc.date());
    populate_time_fields(&mut record, utc.time());
    response(record)
}

#[cfg_attr(target_arch = "wasm32", wasm_func)]
pub fn parse_zoned(input: &[u8]) -> PluginResult {
    let value: Zoned = parse_raw(input, "zoned datetime")?;
    let ts = value.timestamp();
    let utc = ts.to_zoned(jiff::tz::TimeZone::UTC);
    let nanos = ts.as_nanosecond();
    let mut record = json!({
        "text": value.to_string(),
        "timestamp": {
            "text": ts.to_string(),
            "epoch": {
                "seconds": nanos.div_euclid(1_000_000_000) as i64,
                "nanosecond": nanos.rem_euclid(1_000_000_000) as i32,
            },
        },
        "zone": value.time_zone().iana_name(),
        "offset": value.offset().to_string(),
    });
    populate_date_fields(&mut record["timestamp"], utc.date());
    populate_time_fields(&mut record["timestamp"], utc.time());
    populate_date_fields(&mut record, value.date());
    populate_time_fields(&mut record, value.time());
    response(record)
}

#[cfg_attr(target_arch = "wasm32", wasm_func)]
pub fn parse_span(input: &[u8]) -> PluginResult {
    let value: Span = parse_raw(input, "span")?;
    response(json!({
        "text": value.to_string(),
        "years": value.get_years(),
        "months": value.get_months(),
        "weeks": value.get_weeks(),
        "days": value.get_days(),
        "hours": value.get_hours(),
        "minutes": value.get_minutes(),
        "seconds": value.get_seconds(),
        "milliseconds": value.get_milliseconds(),
        "microseconds": value.get_microseconds(),
        "nanoseconds": value.get_nanoseconds(),
    }))
}

fn populate_date_fields(record: &mut Value, date: Date) {
    record["year"] = json!(date.year());
    record["month"] = json!(date.month());
    record["day"] = json!(date.day());
    record["weekday"] = json!(date.strftime("%A").to_string().to_ascii_lowercase());
    record["day-of-year"] = json!(date.day_of_year());
}

fn populate_time_fields(record: &mut Value, time: Time) {
    record["hour"] = json!(time.hour());
    record["minute"] = json!(time.minute());
    record["second"] = json!(time.second());
    record["nanosecond"] = json!(time.subsec_nanosecond());
}
