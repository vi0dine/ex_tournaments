defmodule ExTournaments.Utils.Algorithms.EdmondsBlossom.AugmentBlossom do
  import ExTournaments.Utils.Algorithms.EdmondsBlossom.Helpers

  def call(graph, v, b) do
    t = find_top(graph, v, b)

    if t > graph.num_of_vertices do
      call(graph, t, v)
    else
      i = Enum.find_index(graph.blossom_children[b], &(&1 == t))
      j = Enum.find_index(graph.blossom_children[b], &(&1 == t))

      {j, j_step, endpoint_trick} =
        if Bitwise.band(i, 1) do
          j = length(graph.blossom_children[b])
          j_step = 1
          endpoint_trick = 0

          {j, j_step, endpoint_trick}
        else
          j_step = -1
          endpoint_trick = 1

          {j, j_step, endpoint_trick}
        end

      graph = append_mates(graph, j, j_step, endpoint_trick, b)

      %{
        graph
        | blossom_children:
            List.replace_at(
              graph.blossom_children,
              b,
              graph.blossom_children[b]
              |> Enum.slice(i..-1)
              |> Enum.concat(Enum.slice(graph.blossom_children[b], 0..i))
            ),
          blossom_endpoints:
            List.replace_at(
              graph.blossom_endpoints,
              b,
              graph.blossom_endpoints[b]
              |> Enum.slice(i..-1)
              |> Enum.concat(Enum.slice(graph.blossom_endpoints[b], 0..i))
            ),
          blossom_base:
            List.replace_at(
              graph.blossom_base,
              b,
              graph.blossom_base[graph.blossom_children[b][0]]
            )
      }
    end
  end

  defp find_top(graph, t, b) do
    if graph.blossom_parent[t] != b do
      find_top(graph, graph.blossom_parent[t], b)
    else
      t
    end
  end

  defp append_mates(graph, j, j_step, endpoint_trick, b) do
    if j != 0 do
      j = j + j_step
      t = p_index(graph.blossom_children[b], j)
      p = Bitwise.bxor(p_index(graph.blossom_enpoints[b], j - endpoint_trick), endpoint_trick)

      graph =
        if t >= graph.num_of_vertices do
          call(graph, t, graph.endpoint[p])
        else
          graph
        end

      j = j + j_step
      t = p_index(graph.blossom_children[b], j)

      graph =
        if t >= graph.num_of_vertices do
          call(graph, t, graph.endpoint[Bitwise.bxor(p, 1)])
        else
          graph
        end

      graph = %{
        graph
        | mate:
            graph.mate
            |> List.replace_at(graph.endpoint[p], Bitwise.bxor(p, 1))
            |> List.replace_at(graph.endpoint[Bitwise.bxor(p, 1)], p)
      }

      append_mates(graph, j, j_step, endpoint_trick, b)
    else
      graph
    end
  end
end
