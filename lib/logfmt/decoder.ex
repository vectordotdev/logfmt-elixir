defmodule Logfmt.Decoder do
  @moduledoc """
  This module contains functions to decode logfmt strings into a Keyword.t
  """

  alias __MODULE__.InvalidSyntaxError

  @type t :: Keyword.t
  @valid_delimiters [":", "="]
  @valid_delimiters_binary [?:, ?=]

  @doc ~S"""
  Decodes a logfmt encoded string into a Keyword.t

  ## Examples
      iex> Logfmt.decode!("name:\"Timber Technologies\" domain:timber.io awesome:true")
      [name: "Timber Technologies", domain: "timber.io", awesome: "true"]
  """
  @spec decode!(binary) :: t
  def decode!(input) do
    if String.contains?(input, @valid_delimiters) do
      do_decode(trim_leading(input), "", Keyword.new(), nil, nil)
    else
      raise InvalidSyntaxError, "String is invalid, it does not contain a key/value delimiter, : or ="
    end
  end

  @doc ~S"""
  Same as `decode!/1` except that it returns the error inline instead of raises.

  ## Examples
      iex> Logfmt.decode("name:\"Timber Technologies\" domain:timber.io awesome:true")
      {:ok, [name: "Timber Technologies", domain: "timber.io", awesome: "true"]}
  """
  @spec decode(binary) :: {:ok, t} | {:error, String.t}
  def decode(input) do
    {:ok, decode!(input)}
  rescue
    exception -> {:error, Exception.message(exception)}
  end

  defp trim_leading(string) do
    case Version.compare(System.version, "1.3.0") do
      :gt -> String.trim_leading(string)
      :eq -> String.trim_leading(string)
      :lt -> String.lstrip(string)
    end
  end

  # If we have an escaped quote, simply remove the escape
  defp do_decode(<<?\\, quote, t::binary>>, buffer, acc, quote, delimiter),
    do: do_decode(t, <<buffer::binary, quote>>, acc, quote, delimiter)

  # If we have a quote and we were not in a quote, start one
  defp do_decode(<<quote, t::binary>>, buffer, acc, nil, delimiter) when quote in [?", ?'],
    do: do_decode(t, buffer, acc, quote, delimiter)

  # If we have a quote and we were inside it, close it
  defp do_decode(<<quote, t::binary>>, buffer, acc, quote, delimiter),
    do: do_decode(t, buffer, acc, nil, delimiter)

  # If we have an escaped quote/space, simply remove the escape as long as we are not inside a quote
  defp do_decode(<<?\\, h, t::binary>>, buffer, acc, nil, delimiter) when h in [?\s, ?', ?"],
    do: do_decode(t, <<buffer::binary, h>>, acc, nil, delimiter)

  # If we have a delimiter, are not inside a quote, and we have not already supplied a delimiter, record it
  defp do_decode(<<delimiter, t::binary>>, buffer, acc, nil, nil) when delimiter in @valid_delimiters_binary,
    do: do_decode(t, <<buffer::binary, delimiter>>, acc, nil, delimiter)

  # If we have space and we are outside of a quote, start new segment
  defp do_decode(<<?\s, t::binary>>, buffer, acc, nil, delimiter),
    do: do_decode(trim_leading(t), "", Keyword.merge(to_keyword(buffer, delimiter), acc), nil, nil)

  # All other characters are moved to buffer
  defp do_decode(<<h, t::binary>>, buffer, acc, quote, delimiter) do
    do_decode(t, <<buffer::binary, h>>, acc, quote, delimiter)
  end

  # Finish the string expecting a nil marker
  defp do_decode(<<>>, "", acc, nil, _delimiter),
    do: acc

  # Throw the last part into a keyword
  defp do_decode(<<>>, buffer, acc, nil, delimiter),
    do: Enum.reverse(Keyword.merge(to_keyword(buffer, delimiter), acc))

  # Otherwise raise
  defp do_decode(<<>>, _, _acc, marker, _delimiter) do
    raise InvalidSyntaxError, message: "string did not terminate properly, a #{<<marker>>} was opened but never closed"
  end

  defp to_keyword(term, nil) do
    raise InvalidSyntaxError, message: "No value detected, all keys must contain a value delimited by : or ="
  end

  defp to_keyword(term, delimiter) do
    [key, value] = String.split(term, <<delimiter>>, parts: 2)
    Keyword.new(["#{key}": value])
  end

  #
  # Errors
  #

  defmodule InvalidSyntaxError do
    @moduledoc """
    Exception raised when a string is malformed and cannot be decoded.
    """
    defexception [:message]
  end
end