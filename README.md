# typiff

This is a small typst library which wraps [Jiff](https://github.com/BurntSushi/jiff)
to parse dates, times, timestampts, time zones, and calendar spans in Typst.

Here is a small example:

```typst
#import "lib.typ": parse-date, to-datetime

#let date = parse-date("2024-02-29")
#date.weekday // "thursday"
#to-datetime(date).display("[day] [month repr:long] [year]")
```

See the [manual](docs/manual.typ) for more detailed documentation.

## Development

The easiest way to get started is with a nix shell:
```sh
nix-shell
make build  # Build the WASM plugin
make check  # Lint, test, build docs
```
