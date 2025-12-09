# mix run scripts/parse_json.exs
# mix format scripts/parse_json.exs
project_root =
  __ENV__.file
  |> Path.dirname()
  |> Path.join("..")
  |> Path.expand()

json_path = Path.join(project_root, "internal/ref_ai.json")

data =
  json_path
  |> File.read!()
  |> JSON.decode!()

items = data["applicationIdentifiers"] || raise "Not found: applicationIdentifiers"

fixed_ais_list = fn items ->
  fixed_ais =
    Enum.filter(items, fn item ->
      case item["separatorRequired"] do
        false -> true
        _any_other -> false
      end
    end)
    |> Enum.flat_map(fn %{"applicationIdentifier" => ai, "components" => components} ->
      if length(components) != 1,
        do: raise(ArgumentError, "Invalid struct: components length mismatch.")

      case components do
        [%{"fixedLength" => true, "length" => length}] ->
          stripped_ai = ai |> String.slice(0, 2)
          ai_len = ai |> String.length()
          [{stripped_ai, ai_len + length}]

        _ ->
          raise(ArgumentError, "Components struct mismatch.")
      end
    end)
    |> Map.new()

  IO.inspect(fixed_ais, label: :fixed_ais)
end

# fixed_ais_list.(items)

group_len_by_prefix = fn list, len when len >= 2 ->
  list
  |> Enum.filter(&(String.length(&1) == len))
  |> Enum.group_by(fn s -> String.slice(s, 0, 2) end)
end

grouped_by_len_list = fn items ->
  identifiers =
    items
    |> Enum.flat_map(fn item ->
      case item["applicationIdentifier"] do
        nil -> []
        ai -> [ai]
      end
    end)

  IO.puts("# two digit")

  for {key, _value} <- group_len_by_prefix.(identifiers, 2) do
    IO.puts("\"#{key}\" -> 2")
  end

  IO.puts("# three digit")

  for {key, _value} <- group_len_by_prefix.(identifiers, 3) do
    IO.puts("\"#{key}\" -> 3")
  end

  IO.puts("# four digit")

  for {key, _value} <- group_len_by_prefix.(identifiers, 4) do
    IO.puts("\"#{key}\" -> 4")
  end
end

grouped_by_len_list.(items)

update_ai_range = fn acc, prefix, ai_int ->
  case acc do
    %{^prefix => {min, max}} ->
      new_min = if ai_int < min, do: ai_int, else: min
      new_max = if ai_int > max, do: ai_int, else: max
      %{acc | prefix => {new_min, new_max}}

    _ ->
      Map.put(acc, prefix, {ai_int, ai_int})
  end
end

group_ai_ranges = fn items when is_list(items) ->
  identifiers =
    items
    |> Enum.flat_map(fn item ->
      case item["applicationIdentifier"] do
        nil -> []
        ai -> [ai]
      end
    end)

  ranges =
    identifiers
    |> Enum.reduce(%{}, fn ai, acc ->
      case String.length(ai) do
        2 ->
          # skip two-digit AIs completely
          acc

        3 ->
          prefix = String.slice(ai, 0, 2)
          ai_int = String.to_integer(ai)
          update_ai_range.(acc, prefix, ai_int)

        4 ->
          prefix = String.slice(ai, 0, 3)
          ai_int = String.to_integer(ai)
          update_ai_range.(acc, prefix, ai_int)

        _ ->
          raise ArgumentError, "Unsupported AI length: #{ai}"
      end
    end)

  sorted =
    ranges
    |> Enum.sort_by(fn {prefix, {min, _max}} -> {String.length(prefix), prefix, min} end)

  for {k, {s, e}} <- sorted do
    IO.puts("\"#{k}\" -> {#{s}, #{e}}")
  end
end

# group_ai_ranges.(items)

# fixed_ai_len =
#   items
#   |> Enum.flat_map(fn
#     %{"applicationIdentifier" => ai, "components" => components} ->
#       case Enum.find(components, &(&1["fixedLength"] == true)) do
#         %{"length" => len} ->
#           stripped = String.slice(ai, 0, 2)
#           # stripped = ai
#           [{stripped, len}]
#         _ -> []
#       end

#     _ ->
#       []
#   end)
#   |> MapSet.new()

# IO.inspect(fixed_ai_len)
