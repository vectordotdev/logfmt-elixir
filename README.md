# Key Value Parser for Elixir

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
KeyValueParser.parse("key1=value1 key2=\"This is a quoted value\"")
```

## Shoutout

If you appreciate this library, head over to [timber.io](https://timber.io). Perhaps we upgrade
your logging infrastructure?

## License

Key Value Parser is released into the public domain (see `UNLICENSE`).
Key Value Parser is also optionally available under the ISC License (see `LICENSE`),
meant especially for jurisdictions that do not recognize public domain works.