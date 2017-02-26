# Logfmt for Elixir

[![Travis](https://img.shields.io/travis/timberio/logfmt-elixir.svg?style=flat-square)](https://travis-ci.org/timberio/logfmt-elixir)
[![Hex.pm](https://img.shields.io/hexpm/v/timber_logfmt.svg?style=flat-square)](https://hex.pm/packages/timber_logfmt)
[![Hex.pm](https://img.shields.io/hexpm/dt/timber_logfmt.svg?style=flat-square)](https://hex.pm/packages/timber_logfmt)

A simple logfmt decoder for elixir that uses binary scanning for high performance.

Brought to you by [Timber.io](https://timber.io). This library is used to parse millions of log
lines every day.

## Installation

```elixir
# mix.exs

def deps do
  [{:timber_logfmt, "~> 1.0"}]
end
```

## Usage

<details><summary><strong>Using = as the delimiter</strong></summary><p>

```elixir
Logfmt.parse("key1=value1 key2=\"This is a quoted value\" key3=1")
=> {:ok, [key1: "value1", key2: "This is a quoted value", key3: "1"]}
```

</p></details>

<details><summary><strong>Using : as the delimiter</strong></summary><p>

```elixir
Logfmt.parse("key1:value1 key2:\"This is a quoted value\" key3:1 key4")
=> {:ok, [key1: "value1", key2: "This is a quoted value", key3: "1", key4=true]}
```

</p></details>

## Notable logfmt deviations

We deviated slightly from the logfmt spec:

1. We accept `:` as a delimited in addition to `=`
2. We do not cast or coerce values. All values will parsed into a string. This is because logfmt does not have any syntax for types. Ex: `key:true` could evaluate to `true` or `"true"`.
3. Values are decoded into a `Keyword.t` to preserve the order.
4. Valueless keywords will error. In the context of logging, this makes virtually any string valid, which is not ideal.

## Shoutout

If you appreciate this library, head over to [timber.io](https://timber.io).

## License

Released into the public domain (see `UNLICENSE`).
Optionally available under the ISC License (see `LICENSE`),
meant especially for jurisdictions that do not recognize public domain works.