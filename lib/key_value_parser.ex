defmodule KeyValueParser do
  @moduledoc """
  This module contains functions to parse key value pairs.
  """

  defmodule InvalidSyntaxError do
    @moduledoc """
    Exception raised when a token does not contain an equals delimiter. (: or =)
    """
    defexception message: "String is invalid, it does not contain an equals delimiter, : or ="
  end

  @type t :: Keyword.t
  @valid_delimiters [":", "="]
  @valid_delimiters_binary [?:, ?=]

  @doc ~S"""
  Splits a string into a Keyword.

  This function splits the given `string` into a list of key value pairs
  as outlined in the Keyword module.

  ## Examples
      iex> KeyValueParser.parse("name:\"Timber Technologies\" domain:timber.io awesome:true")
      [name: "Timber Technologies", domain: "timber.io", awesome: "true"]
  """
  @spec parse(String.t) :: t
  def parse!(input) do
    if String.contains?(input, @valid_delimiters) do
      keywords = do_split(trim_leading(input), "", Keyword.new, nil, nil)
      if Keyword.values(keywords) == [true] do
        raise InvalidSyntaxError
      else
        keywords
      end
    else
      raise InvalidSyntaxError
    end
  end

  def parse(input) do
    parse!(input)
  rescue
    _ -> nil
  end

  defp trim_leading(string) do
    case Version.compare(System.version, "1.3.0") do
    :gt -> String.trim_leading(string)
    :eq -> String.trim_leading(string)
    :lt -> String.lstrip(string)
    end
  end

  # If we have an escaped quote, simply remove the escape
  defp do_split(<<?\\, quote, t::binary>>, buffer, acc, quote, delimiter),
    do: do_split(t, <<buffer::binary, quote>>, acc, quote, delimiter)

  # If we have a quote and we were not in a quote, start one
  defp do_split(<<quote, t::binary>>, buffer, acc, nil, delimiter) when quote in [?", ?'],
    do: do_split(t, buffer, acc, quote, delimiter)

  # If we have a quote and we were inside it, close it
  defp do_split(<<quote, t::binary>>, buffer, acc, quote, delimiter),
    do: do_split(t, buffer, acc, nil, delimiter)

  # If we have an escaped quote/space, simply remove the escape as long as we are not inside a quote
  defp do_split(<<?\\, h, t::binary>>, buffer, acc, nil, delimiter) when h in [?\s, ?', ?"],
    do: do_split(t, <<buffer::binary, h>>, acc, nil, delimiter)

  # If we have a delimiter, are not inside a quote, and we have not already supplied a delimiter, record it
  defp do_split(<<delimiter, t::binary>>, buffer, acc, nil, nil) when delimiter in @valid_delimiters_binary,
    do: do_split(t, <<buffer::binary, delimiter>>, acc, nil, delimiter)

  # If we have space and we are outside of a quote, start new segment
  defp do_split(<<?\s, t::binary>>, buffer, acc, nil, delimiter),
    do: do_split(trim_leading(t), "", Keyword.merge(to_keyword(buffer, delimiter), acc), nil, nil)

  # All other characters are moved to buffer
  defp do_split(<<h, t::binary>>, buffer, acc, quote, delimiter) do
    do_split(t, <<buffer::binary, h>>, acc, quote, delimiter)
  end

  # Finish the string expecting a nil marker
  defp do_split(<<>>, "", acc, nil, _delimiter),
    do: acc

  # Throw the last part into a keyword
  defp do_split(<<>>, buffer, acc, nil, delimiter),
    do: Enum.reverse(Keyword.merge(to_keyword(buffer, delimiter), acc))

  # Otherwise raise
  defp do_split(<<>>, _, _acc, marker, _delimiter) do
    raise InvalidSyntaxError, message: "string did not terminate properly, a #{<<marker>>} was opened but never closed"
  end

  defp to_keyword(term, nil) do
    Keyword.new(["#{term}": true])
  end

  defp to_keyword(term, delimiter) do
    [key, value] = String.split(term, <<delimiter>>, parts: 2)
    Keyword.new(["#{key}": value])
  end
end