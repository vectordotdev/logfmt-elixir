defmodule KeyValueParserTest do
  use ExUnit.Case, async: true
  doctest KeyValueParser

  test "parse/1 does not raise an exception" do
    keywords = KeyValueParser.parse("invalid")
    assert keywords == nil
  end

  test "parse!/1 with a blank string" do
    assert_raise KeyValueParser.InvalidSyntaxError, "String is invalid, it does not contain an equals delimiter, : or =", fn ->
      KeyValueParser.parse!("")
    end
  end

  test "parse!/1 with unclosed quote" do
    assert_raise KeyValueParser.InvalidSyntaxError, "string did not terminate properly, a \" was opened but never closed", fn ->
      KeyValueParser.parse!("key:\"invalid")
    end
  end

  test "parse!/1 with invalid term" do
    assert_raise KeyValueParser.InvalidSyntaxError, "String is invalid, it does not contain an equals delimiter, : or =", fn ->
      KeyValueParser.parse!("invalid")
    end
  end

  test "parse!/1 with split inside quotes" do
    assert_raise KeyValueParser.InvalidSyntaxError, "String is invalid, it does not contain an equals delimiter, : or =", fn ->
      raise KeyValueParser.parse!("key\"value:test\"")
    end
  end

  test "parse!/1 with a single term / boolean" do
    keywords = KeyValueParser.parse!("key:value is_awesome")
    assert keywords == [key: "value", is_awesome: true]
  end

  test "parse!/1 with valid : term" do
    keywords = KeyValueParser.parse!("key:value")
    assert keywords == [key: "value"]
  end

  test "parse!/1 with valid = term" do
    keywords = KeyValueParser.parse!("key=value")
    assert keywords == [key: "value"]
  end

  test "parse!/1 with valid : quoted term" do
    keywords = KeyValueParser.parse!("key:\"this is a value\"")
    assert keywords == [key: "this is a value"]
  end

  test "parse!/1 with mutliple terms and one is a boolean" do
    keywords = KeyValueParser.parse!("key:value another")
    assert keywords == [key: "value", another: true]
  end

  test "parse!/1 with mutliple valid : terms" do
    keywords = KeyValueParser.parse!("key1:value1 key2:value2")
    assert keywords == [key1: "value1", key2: "value2"]
  end

  test "parse!/1 with mutliple valid mixed terms" do
    keywords = KeyValueParser.parse!("key1:value1 key2=value2")
    assert keywords == [key1: "value1", key2: "value2"]
  end

  test "parse!/1 with leading and trailing whitespace" do
    keywords = KeyValueParser.parse!("    key1:value1 key2=value2     ")
    assert keywords == [key2: "value2", key1: "value1"]
  end
end