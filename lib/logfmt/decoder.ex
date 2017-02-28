defmodule Logfmt.Decoder do
  @moduledoc """
  This module contains functions to decode logfmt strings into a Keyword.t
  """

  alias __MODULE__.InvalidSyntaxError

  @type t :: Keyword.t

  @quotes [?", ?']
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
      do_decode(trim_leading(input), "", "", Keyword.new(), nil, nil)
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
  defp do_decode(<<?\\, quote, t::binary>>, key_buffer, value_buffer, keywords, quote, nil),
    do: do_decode(t, <<key_buffer::binary, quote>>, value_buffer, keywords, quote, nil)

  defp do_decode(<<?\\, quote, t::binary>>, key_buffer, value_buffer, keywords, quote, delimiter),
    do: do_decode(t, key_buffer, <<value_buffer::binary, quote>>, keywords, quote, delimiter)

  # If we have a quote, we were not in a quote, and we are not buffering, start buffering
  defp do_decode(<<quote, t::binary>>, "", value_buffer, keywords, nil, nil) when quote in @quotes do
    do_decode(t, "", value_buffer, keywords, quote, nil)
  end

  # If we have a quote, we were not in a quote, and we are not buffering, start buffering
  defp do_decode(<<quote, t::binary>>, key_buffer, "", keywords, nil, delimiter) when not is_nil(delimiter) and quote in @quotes do
    do_decode(t, key_buffer, "", keywords, quote, delimiter)
  end

  # If we have a quote, we were not in a quote, and we *are* buffering, raise
  defp do_decode(<<quote, _t::binary>>, _key_buffer, _value_buffer, _keywords, nil, nil) when quote in @quotes do
    raise InvalidSyntaxError, message: "a #{<<quote>>} was detected but was not at the begginning of the key value"
  end

  # If we have a quote, we were not in a quote, and we *are* buffering, raise
  defp do_decode(<<quote, _t::binary>>, _key_buffer, _value_buffer, _keywords, nil, _delimiter) when quote in @quotes do
    raise InvalidSyntaxError, message: "a #{<<quote>>} was detected but was not at the begginning of the value"
  end

  # If we have a quote and we were inside it, close it
  defp do_decode(<<quote, t::binary>>, key_buffer, value_buffer, keywords, quote, delimiter),
    do: do_decode(t, key_buffer, value_buffer, keywords, nil, delimiter)

  # If we have an escaped quote/space, simply remove the escape as long as we are not inside a quote
  defp do_decode(<<?\\, h, t::binary>>, key_buffer, value_buffer, keywords, nil, nil) when h in [?\s, ?', ?"],
    do: do_decode(t, <<key_buffer::binary, h>>, value_buffer, keywords, nil, nil)

  # If we have an escaped quote/space, simply remove the escape as long as we are not inside a quote
  defp do_decode(<<?\\, h, t::binary>>, key_buffer, value_buffer, keywords, nil, delimiter) when not is_nil(delimiter) and h in [?\s, ?', ?"],
    do: do_decode(t, key_buffer, <<value_buffer::binary, h>>, keywords, nil, delimiter)

  # If we have a delimiter, are not inside a quote, and we have not already supplied a delimiter, discard it
  defp do_decode(<<delimiter, t::binary>>, key_buffer, value_buffer, keywords, nil, nil) when delimiter in @valid_delimiters_binary,
    do: do_decode(t, key_buffer, value_buffer, keywords, nil, delimiter)

  # If we have space, we are outside of a quote, and we do not have a delimiter, raise
  defp do_decode(<<?\s, t::binary>>, key_buffer, value_buffer, keywords, nil, nil) do
    raise InvalidSyntaxError, message: "white space was enountered within a key before a value was specified"
  end

  # If we have space and we are outside of a quote, start new segment
  defp do_decode(<<?\s, t::binary>>, key_buffer, value_buffer, keywords, nil, delimiter) when not is_nil(delimiter),
    do: do_decode(trim_leading(t), "", "", Keyword.merge(to_keyword(key_buffer, value_buffer), keywords), nil, nil)

  # All other characters are moved to buffer
  defp do_decode(<<h, t::binary>>, key_buffer, value_buffer, keywords, quote, nil) do
    do_decode(t, <<key_buffer::binary, h>>, value_buffer, keywords, quote, nil)
  end

  # All other characters are moved to buffer
  defp do_decode(<<h, t::binary>>, key_buffer, value_buffer, keywords, quote, delimiter) when not is_nil(delimiter) do
    do_decode(t, key_buffer, <<value_buffer::binary, h>>, keywords, quote, delimiter)
  end

  # Finish the string expecting a nil marker
  defp do_decode(<<>>, "", "", keywords, nil, _delimiter),
    do: keywords

  # Throw the last part into a keyword
  defp do_decode(<<>>, key_buffer, value_buffer, keywords, nil, _delimiter),
    do: Enum.reverse(Keyword.merge(to_keyword(key_buffer, value_buffer), keywords))

  # Otherwise raise
  defp do_decode(<<>>, _key_buffer, _value_buffer, _keywords, marker, _delimiter) do
    raise InvalidSyntaxError, message: "string did not terminate properly, a #{<<marker>>} was opened but never closed"
  end

  defp to_keyword(key_buffer, nil) do
    raise InvalidSyntaxError, message: "No value detected for key #{key_buffer}, all keys must contain a value delimited by : or ="
  end

  defp to_keyword(key_buffer, value_buffer) do
    Keyword.new(["#{key_buffer}": value_buffer])
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