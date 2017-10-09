defmodule Xmlex.Decoder do
	require Logger
	require Record
	require XmerlRecords


	def decode!(body) when is_binary(body) do
		case try_parse_to_tree(body) do
			res = {:error, _} -> raise "Xmlex parser error #{inspect res}"
			some_else -> %Xmlex.XML{} = recurs_parse(some_else)
		end
	end
	def decode(body) when is_binary(body) do
		case try_parse_to_tree(body) do
			res = {:error, _} -> res
			some_else ->
				case ExTask.run(fn() ->  recurs_parse(some_else) end )
						|> ExTask.await(:infinity) do
					{:result, res = %Xmlex.XML{}} -> res
					err -> {:error, err}
				end
		end
	end
	def decode(body) do
		{:error, "body is not a binary #{inspect body}"}
	end



	defp try_parse_to_tree(body) when is_binary(body) do
		case ExTask.run(fn() -> :xmerl_scan.string(body |> :erlang.binary_to_list) end)
				|> ExTask.await(:infinity) do
		    {:result, {tree, _}} -> tree
		    {:result, res } -> 	{:error, {:wrong_return, res}}
		    {:exit, reason} -> 	{:error, reason}
		end
	end
	# input - xmlElement, DIRECTLY!
	defp recurs_parse(data) when Record.is_record(data) do
		# atom
		tagname = XmerlRecords.xmlElement(data, :name)
		# binary
		tagtext = :xmerl_xpath.string('/*/text()', data)
					|> get_text
		# map
		attrs = :xmerl_xpath.string('/*/@*', data)
					|> attr_list_to_map
		# list
		childs = :xmerl_xpath.string('/*/*', data)
					|> Enum.map(&( recurs_parse(&1) ))
		%Xmlex.XML{tagname: tagname, tagtext: tagtext, attrs: attrs, childs: childs}
	end


	# extract text from xmlText
	defp get_text([]) do
		""
	end
	defp get_text([data]) when Record.is_record(data) do
		XmerlRecords.xmlText(data, :value)
		|> to_string
		|> String.trim
	end
	# here we fixing bug when in xml are extra \n or \t symbols
	defp get_text(_) do
		""
	end

	# lst - list of xmlAttrs
	defp attr_list_to_map(lst) when is_list(lst) do
		Enum.reduce( lst, %{},
				fn(attr, resmap) ->
					Map.put(resmap, XmerlRecords.xmlAttribute(attr, :name), get_attr_val(attr))
				end	)
	end
	# from xmlAttribute record to string
	defp get_attr_val(data) when Record.is_record(data) do
		XmerlRecords.xmlAttribute(data, :value)
		|> to_string
		|> String.trim
	end

end
