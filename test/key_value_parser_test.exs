defmodule KeyValueParserTest do
  use ExUnit.Case, async: true
  doctest KeyValueParser

  test "parse/1 with a blank string" do
    keywords = KeyValueParser.parse("")
    assert keywords == []
  end

  test "parse/1 with invalid term" do
    assert_raise KeyValueParser.InvalidTokenSyntax, "The \"invalid\" term does not contain an equals delimiter, : or =", fn ->
      KeyValueParser.parse("invalid")
    end
  end

  test "parse/1 with valid : term" do
    keywords = KeyValueParser.parse("key:value")
    assert keywords == [key: "value"]
  end

  test "parse/1 with valid = term" do
    keywords = KeyValueParser.parse("key=value")
    assert keywords == [key: "value"]
  end

  test "parse/1 with valid : quoted term" do
    keywords = KeyValueParser.parse("key:\"this is a value\"")
    assert keywords == [key: "this is a value"]
  end

  test "parse/1 with mutliple terms and one invalid" do
    assert_raise KeyValueParser.InvalidTokenSyntax, "The \"invalid\" term does not contain an equals delimiter, : or =", fn ->
      KeyValueParser.parse("key:value invalid")
    end
  end

  test "parse/1 with mutliple valid : terms" do
    keywords = KeyValueParser.parse("key1:value1 key2:value2")
    assert keywords == [key1: "value1", key2: "value2"]
  end

  test "parse/1 with mutliple valid mixed terms" do
    keywords = KeyValueParser.parse("key1:value1 key2=value2")
    assert keywords == [key1: "value1", key2: "value2"]
  end
end