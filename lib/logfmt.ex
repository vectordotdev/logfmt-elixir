defmodule Logfmt do
  alias __MODULE__.Decoder

  defdelegate decode!(message), to: Decoder
  defdelegate decode(message), to: Decoder
end