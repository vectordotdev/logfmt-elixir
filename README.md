# Key Value Parser for Elixir

[![Travis](https://img.shields.io/travis/timberio/elixir-key-value-parser.svg?style=flat-square)](https://travis-ci.org/timberio/elixir-key-value-parser)
[![Hex.pm](https://img.shields.io/hexpm/v/key_value_parser.svg?style=flat-square)](https://hex.pm/packages/key_value_parser)
[![Hex.pm](https://img.shields.io/hexpm/dt/key_value_parser.svg?style=flat-square)](https://hex.pm/packages/key_value_parser)

A simple key value parser for Elixir, brought to you by [Timber.io](https://timber.io). This
library is used to parse millions of log lines every day.

## Installation

First, add Key Value Parser to your `mix.exs` dependencies:

```elixir
def deps do
  [{:key_value_parser, "~> 1.0"}]
end
```

Then, update your dependencies:

```sh-session
$ mix deps.get
```

## Usage

```elixir
# with an = delimiter
KeyValueParser.parse("key1=value1 key2=\"This is a quoted value\"")
=> [key1: "value1", key2: "This is a quoted value"]

# with a : delimiter
KeyValueParser.parse("key1:value1 key2:\"This is a quoted value\"")
=> [key1: "value1", key2: "This is a quoted value"]
```

## Type casting

This library does not attempt to type cast values into booleans, integers, floats, etc, for a couple of reasons:

1. Strings are not strictly defined with quotes. Notice `value1` above.
2. There isn't a RFC for the key value format.

Type casting should be the responsibility of the underlying data structure. Treat this like user input. For example, if you're using an Ecto model, it advised to cast your input through a changeset.

## Shoutout

If you appreciate this library, head over to [timber.io](https://timber.io). Perhaps we can
upgrade your logging system?

## License

Key Value Parser is released into the public domain (see `UNLICENSE`).
Key Value Parser is also optionally available under the ISC License (see `LICENSE`),
meant especially for jurisdictions that do not recognize public domain works.