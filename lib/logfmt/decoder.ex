defmodule Logfmt.Decoder do
  @moduledoc """
  This module contains functions to decode logfmt strings into a map
  """

  alias __MODULE__.InvalidSyntaxError

  @type t :: map

  @quotes [?", ?']
  @valid_delimiters [?:, ?=]
  lower_case = (?a..?z) |> Enum.to_list()
  upper_case = (?A..?Z) |> Enum.to_list()
  numbers = (?0..?9) |> Enum.to_list()
  @valid_key_chars lower_case ++ upper_case ++ numbers ++ [?#, ?_, ?-, ?.]

  @doc ~S"""
  Decodes a logfmt encoded string into a map

  ## Examples
      iex> Logfmt.decode!("name:\"Timber Technologies\" domain:timber.io awesome:true")
      %{"name" => "Timber Technologies", "domain" => "timber.io", "awesome" => "true"}
  """
  @spec decode!(binary) :: t
  def decode!("") do
    raise InvalidSyntaxError, message: "blank strings cannot be decoded"
  end

  def decode!(input) do
    do_decode(trim_leading(input), "", "", %{}, nil, nil)
  end

  @doc ~S"""
  Same as `decode!/1` except that it returns the error inline instead of raises.

  ## Examples
      iex> Logfmt.decode("name:\"Timber Technologies\" domain:timber.io awesome:true")
      {:ok, %{"name" => "Timber Technologies", "domain" => "timber.io", "awesome" => "true"}}
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

  # If we have an escaped quote, and we haven't encountered a delimiter, simply remove the escape
  # append to the key_buffer
  defp do_decode(<<?\\, quote, t::binary>>, key_buffer, value_buffer, map, quote, nil),
    do: do_decode(t, <<key_buffer::binary, quote>>, value_buffer, map, quote, nil)

  # If we have an escaped quote, and we haven't encountered a delimiter, simply remove the escape
  # append to the value_buffer
  defp do_decode(<<?\\, quote, t::binary>>, key_buffer, value_buffer, map, quote, delimiter),
    do: do_decode(t, key_buffer, <<value_buffer::binary, quote>>, map, quote, delimiter)

  # If we have a quote, we were not in a quote, and we are not buffering, start buffering
  defp do_decode(<<quote, t::binary>>, "", value_buffer, map, nil, nil) when quote in @quotes do
    do_decode(t, "", value_buffer, map, quote, nil)
  end

  # If we have a quote, we were not in a quote, and we are not buffering, start buffering
  defp do_decode(<<quote, t::binary>>, key_buffer, "", map, nil, delimiter) when not is_nil(delimiter) and quote in @quotes do
    do_decode(t, key_buffer, "", map, quote, delimiter)
  end

  # If we have a quote, we were not in a quote, and we *are* buffering, raise
  defp do_decode(<<quote, _t::binary>>, _key_buffer, _value_buffer, _map, nil, nil) when quote in @quotes do
    raise InvalidSyntaxError, message: "a #{<<quote>>} was detected but was not at the begginning of the key value"
  end

  # If we have a quote, we were not in a quote, and we *are* buffering, raise
  defp do_decode(<<quote, _t::binary>>, _key_buffer, _value_buffer, _map, nil, _delimiter) when quote in @quotes do
    raise InvalidSyntaxError, message: "a #{<<quote>>} was detected but was not at the begginning of the value"
  end

  # If we have a quote and we were inside it, close it
  defp do_decode(<<quote, t::binary>>, key_buffer, value_buffer, map, quote, delimiter),
    do: do_decode(t, key_buffer, value_buffer, map, nil, delimiter)

  # If we have an escaped quote/space, simply remove the escape as long as we are not inside a quote
  defp do_decode(<<?\\, h, t::binary>>, key_buffer, value_buffer, map, nil, nil) when h in [?\s, ?', ?"],
    do: do_decode(t, <<key_buffer::binary, h>>, value_buffer, map, nil, nil)

  # If we have an escaped quote/space, simply remove the escape as long as we are not inside a quote
  defp do_decode(<<?\\, h, t::binary>>, key_buffer, value_buffer, map, nil, delimiter) when not is_nil(delimiter) and h in [?\s, ?', ?"],
    do: do_decode(t, key_buffer, <<value_buffer::binary, h>>, map, nil, delimiter)

  # If we have a delimiter, are not inside a quote, and we have not already supplied a delimiter, discard it
  defp do_decode(<<delimiter, t::binary>>, key_buffer, value_buffer, map, nil, nil) when delimiter in @valid_delimiters,
    do: do_decode(t, key_buffer, value_buffer, map, nil, delimiter)

  # If we have space, we are outside of a quote, and we do not have a delimiter, raise
  defp do_decode(<<?\s, _t::binary>>, _key_buffer, _value_buffer, _map, nil, nil) do
    raise InvalidSyntaxError, message: "white space was enountered within a key before a value was specified"
  end

  # If we have space and we are outside of a quote, start new segment
  defp do_decode(<<?\s, t::binary>>, key_buffer, value_buffer, map, nil, delimiter) when not is_nil(delimiter),
    do: do_decode(trim_leading(t), "", "", Map.merge(to_map(key_buffer, value_buffer), map), nil, nil)

  # If we are in a quote, move all characters to the buffer
  defp do_decode(<<h, t::binary>>, key_buffer, value_buffer, map, quote, nil) when not is_nil(quote) do
    do_decode(t, <<key_buffer::binary, h>>, value_buffer, map, quote, nil)
  end

  # If we are not in a quote, move all *valid* characters to the buffer
  defp do_decode(<<h, t::binary>>, key_buffer, value_buffer, map, quote, nil) when h in @valid_key_chars do
    do_decode(t, <<key_buffer::binary, h>>, value_buffer, map, quote, nil)
  end

  defp do_decode(<<h, _t::binary>>, _key_buffer, _value_buffer, _map, _quote, nil) do
    raise InvalidSyntaxError, message: "a #{<<h>>} was detected but is not a valid character for a key"
  end

  # All other characters are moved to buffer
  defp do_decode(<<h, t::binary>>, key_buffer, value_buffer, map, quote, delimiter) when not is_nil(delimiter) do
    do_decode(t, key_buffer, <<value_buffer::binary, h>>, map, quote, delimiter)
  end

  # Finish the string expecting a nil marker
  defp do_decode(<<>>, "", "", map, nil, _delimiter),
    do: map

  # Raise if we did not encounter a delimiter
  defp do_decode(<<>>, _key_buffer, _value_buffer, _map, nil, nil) do
    raise InvalidSyntaxError, message: "valueless maps are not allowed"
  end

  # Throw the last part into the map
  defp do_decode(<<>>, key_buffer, value_buffer, map, nil, _delimiter),
    do: Map.merge(to_map(key_buffer, value_buffer), map)

  # Otherwise raise
  defp do_decode(<<>>, _key_buffer, _value_buffer, _map, marker, _delimiter) do
    raise InvalidSyntaxError, message: "string did not terminate properly, a #{<<marker>>} was opened but never closed"
  end

  defp to_map(key_buffer, nil) do
    raise InvalidSyntaxError, message: "No value detected for key #{key_buffer}, all keys must contain a value delimited by : or ="
  end

  defp to_map(key_buffer, value_buffer) do
    %{key_buffer => value_buffer}
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