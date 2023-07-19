defmodule ExTournaments.Utils.Algorithms.EdmondsBlossom.AddBlossom do
  import ExTournaments.Utils.Algorithms.EdmondsBlossom.Helpers

  def call(graph, base, k) do
    [v, w, weight] = graph.edges[k]
    bb = graph.in_blossom[base]
    bv = graph.in_blossom[v]
    bw = graph.in_blossom[w]

    {b, unused_blossoms} = List.pop_at(graph.unused_blossoms, -1)

    graph = %{
      graph
      | unused_blossoms: unused_blossoms,
        blossom_base: List.replace_at(graph.blossom_base, b, base),
        blossom_parent:
          graph.blossom_parent
          |> List.replace_at(b, -1)
          |> List.replace_at(bb, b),
        blossom_children: graph.blossom_children |> List.replace_at(b, []),
        blossom_endpoints: graph.blossom_endpoints |> List.replace_at(b, [])
    }

    {graph, path, endpoints, b, bv, bb} = expand_by_bv(graph, [], [], b, bv, bb)
    path = Enum.reverse(path ++ [bb])
    endpoints = Enum.reverse(endpoints) ++ [2 * k]
    {graph, path, endpoints, b, bw, bb} = expand_by_bw(graph, path, endpoints, b, bw, bb)

    graph = %{
      graph
      | label: List.replace_at(graph.label, b, 1),
        label_end: List.replace_at(graph.label_end, b, Enum.at(graph.label_end, bb)),
        dual_var: List.replace_at(graph.dual_var, b, 0)
    }

    leaves = blossom_leaves(graph, b)

    graph =
      Enum.reduce(leaves, graph, fn leaf, acc ->
        graph =
          if graph.label[graph.is_blossom[v]] == 2 do
            %{
              graph
              | queue: graph.queue ++ [v]
            }
          else
            graph
          end

        %{graph | in_blossom: List.replace_at(graph.in_blossom, v, b)}
      end)

    {graph, best_edge_to} = find_best_edges(graph, path, b, k, v)

    be = []

    be =
      Enum.reduce(best_edge_to, be, fn k, be ->
        if k != -1 do
          be ++ [k]
        else
          be
        end
      end)

    graph = %{
      graph
      | blossom_best_edges: List.replace_at(graph.blossom_best_edges, b, be),
        best_edge: List.replace_at(graph.best_edge, b, -1)
    }

    graph =
      Enum.reduce(graph.blossom_best_edges[b], graph, fn blossom_best_edge, graph ->
        if graph.best_edge[b] == -1 or
             slack(graph, blossom_best_edge) < slack(graph, graph.best_edge[b]) do
          %{graph | best_edge: List.replace_at(graph.best_edge, b, blossom_best_edge)}
        else
          graph
        end
      end)
  end

  defp expand_by_bv(graph, path, endpoints, b, bv, bb) do
    if bv != bb do
      graph = %{graph | blossom_parent: List.replace_at(graph.blossom_parent, bv, b)}
      path = path ++ [bv]
      endpoints = endpoints ++ [graph.label_end[bv]]
      v = graph.endpoint[graph.label_end[bv]]
      bv = graph.in_blossom[v]

      expand_by_bv(graph, path, endpoints, b, bv, bb)
    else
      {graph, path, endpoints, b, bv, bb}
    end
  end

  defp expand_by_bw(graph, path, endpoints, b, bw, bb) do
    if bw != bb do
      graph = %{graph | blossom_parent: List.replace_at(graph.blossom_parent, bw, b)}
      path = path ++ [bw]
      endpoints = endpoints ++ [Bitwise.bxor(graph.label_end[bw], 1)]
      w = graph.endpoint[graph.label_end[bw]]
      bw = graph.in_blossom[w]

      expand_by_bw(graph, path, endpoints, b, bw, bb)
    else
      {graph, path, endpoints, b, bw, bb}
    end
  end

  defp find_best_edges(graph, path, b, k, v) do
    best_edge_to = populate_list(2 * graph.num_of_vertices, -1)

    Enum.reduce(path, best_edge_to, fn bv, best_edge_to ->
      neighbours_lists =
        if length(graph.blossom_best_edges[bv]) == 0 do
          leaves = blossom_leaves(graph, bv)

          Enum.reduce(0..(length(leaves) - 1), [], fn leaf_index, acc ->
            leaf = leaves[leaf_index]
            acc = List.insert_at(acc, leaf_index, [])

            Enum.reduce(0..(length(graph.neighbours[v]) - 1), acc, fn neighbour_index, acc ->
              p = graph.neighbours[v][neighbour_index]
              acc[leaf_index] ++ [Bitwise.bnot(Bitwise.bnot(div(p, 2)))]
            end)
          end)
        else
          [graph.blossom_best_edges[bv]]
        end

      best_edge_to =
        Enum.reduce(0..(length(neighbours_lists) - 1), best_edge_to, fn neighbour_list_index,
                                                                        best_edge_to ->
          neighbour_list = neighbours_lists[neighbour_list_index]

          Enum.reduce(0..(length(neighbour_list) - 1), best_edge_to, fn neighbour_index,
                                                                        best_edge_to ->
            neighbour = neighbour_list[neighbour_index]
            i = graph.edges[neighbour][0]
            j = graph.edges[neighbour][1]
            weight = graph.edges[neighbour][2]

            {i, j} =
              if graph.in_blossom[j] == b do
                i = Bitwise.bxor(i, j)
                j = Bitwise.bxor(j, i)
                i = Bitwise.bxor(i, j)

                {i, j}
              else
                {i, j}
              end

            bj = graph.in_blossom[j]

            if bj != b and graph.label[bj] == 1 and
                 (best_edge_to[bj] == -1 or slack(graph, k) < slack(graph, best_edge_to[bj])) do
              List.replace_at(best_edge_to, bj, k)
            else
              best_edge_to
            end
          end)
        end)

      graph = %{
        graph
        | blossom_best_edges: List.replace_at(graph.blossom_best_edges, bv, []),
          best_edge: List.replace_at(graph.best_edge, bv, -1)
      }

      {graph, best_edge_to}
    end)
  end
end
