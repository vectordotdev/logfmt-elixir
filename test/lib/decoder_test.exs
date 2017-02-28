defmodule Logfmt.DecoderTest do
  use ExUnit.Case, async: true

  alias Logfmt.Decoder

  doctest Decoder

  describe "Logfmt.Decoder.decode/1" do
    test "does not raise an exception" do
      result = Decoder.decode("invalid")
      assert result == {:error, "String is invalid, it does not contain a key/value delimiter, : or ="}
    end

    test "success" do
      result = Decoder.decode("key=value")
      assert result == {:ok, [key: "value"]}
    end
  end

  describe "Logfmt.Decode.decode!/1" do
    test "with a blank string" do
      assert_raise Decoder.InvalidSyntaxError, "String is invalid, it does not contain a key/value delimiter, : or =", fn ->
        Decoder.decode!("")
      end
    end

    test "with unclosed quote" do
      assert_raise Decoder.InvalidSyntaxError, "string did not terminate properly, a \" was opened but never closed", fn ->
        Decoder.decode!("key:\"invalid")
      end
    end

    test "with invalid term" do
      assert_raise Decoder.InvalidSyntaxError, "String is invalid, it does not contain a key/value delimiter, : or =", fn ->
        Decoder.decode!("invalid")
      end
    end

    test "with split inside quotes" do
      assert_raise Decoder.InvalidSyntaxError, "a \" was detected but was not at the begginning of the key value", fn ->
        Decoder.decode!("key\"value:test\"")
      end
    end

    test "with quote inside the value" do
      assert_raise Decoder.InvalidSyntaxError, "a \" was detected but was not at the begginning of the value", fn ->
        Decoder.decode!("key:val\"ue")
      end
    end

    test "with valid : term" do
      keywords = Decoder.decode!("key:value")
      assert keywords == [key: "value"]
    end

    test "with valid : term that has a delimiter in the value" do
      keywords = Decoder.decode!("key:value1:value2")
      assert keywords == [key: "value1:value2"]
    end

    test "with valid = term" do
      keywords = Decoder.decode!("key=value")
      assert keywords == [key: "value"]
    end

    test "with valid = term that has a delimiter in the value" do
      keywords = Decoder.decode!("key=value1=value2")
      assert keywords == [key: "value1=value2"]
    end

    test "with valid : quoted term" do
      keywords = Decoder.decode!("key:\"this is a value\"")
      assert keywords == [key: "this is a value"]
    end

    test "with mutliple valid : terms" do
      keywords = Decoder.decode!("key1:value1 key2:value2")
      assert keywords == [key1: "value1", key2: "value2"]
    end

    test "with mutliple valid mixed terms" do
      keywords = Decoder.decode!("key1:value1 key2=value2")
      assert keywords == [key1: "value1", key2: "value2"]
    end

    test "with leading and trailing whitespace" do
      keywords = Decoder.decode!("    key1:value1 key2=value2     ")
      assert keywords == [key2: "value2", key1: "value1"]
    end

    test "with commas in the value" do
      keywords = Decoder.decode!("key:1,2,3")
      assert keywords == [key: "1,2,3"]
    end

    test "with an array like value" do
      keywords = Decoder.decode!("key:[1,2,3]")
      assert keywords == [key: "[1,2,3]"]
    end

    test "with json" do
      assert_raise Decoder.InvalidSyntaxError, "a \" was detected but was not at the begginning of the key value", fn ->
        Decoder.decode!("{\"key\":\"value\"}")
      end
    end

    test "with tags" do
      keywords = Decoder.decode!("sample#time=35ms")
      assert keywords == ["sample#time": "35ms"]
    end

    test "backtraces" do
      assert_raise Decoder.InvalidSyntaxError, "white space was enountered within a key before a value was specified", fn ->
        Decoder.decode!("(app name) path/to/file.ex:34")
      end
    end
  end
end