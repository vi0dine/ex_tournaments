defmodule ExTournaments.Utils.Algorithms.EdmondsBlossom.FindMaxWeightMatching do
  require Logger
  import ExTournaments.Utils.Algorithms.EdmondsBlossom.Helpers

  alias ExTournaments.Utils.Algorithms.EdmondsBlossom.{AddBlossom, Graph}

  def call(graph) do
    Enum.reduce(0..(graph.num_of_vertices - 1), %{augmented: false}, fn vertex, acc ->
      Logger.debug("Stage #{vertex}")
      graph = Graph.reset_values(graph)
      graph = assign_labels(graph)

      perform_substage(graph, acc)
    end)
  end

  defp perform_substage(graph, acc) do
    Logger.debug("Substage")

    if length(graph.queue) > 0 and !acc.augmented do
      vertex = List.last(graph.queue)
      Logger.debug("Popped vertex: #{vertex}")

      Enum.reduce_while(graph.neighbour[vertex], graph, fn neighbour, graph ->
        p = neighbour
        k = Bitwise.bnot(Bitwise.bnot(div(p, 2)))
        w = graph.endpoint[p]

        if graph.in_blossom[vertex] == graph.in_blossom[w] do
          {:cont, graph}
        else
          graph =
            if !graph.allow_edge[k] do
              k_slack = slack(graph, k)

              if k_slack <= 0 do
                %{
                  graph
                  | allow_edge: List.replace_at(graph.allow_edge, k, true)
                }
              else
                graph
              end
            end

          graph =
            if !graph.allow_edge[k] do
              if Enum.at(graph.label, graph.in_blossom[w]) == 0 do
                assign_label(graph, w, 2, Bitwise.bxor(p, 1))
              else
                if Enum.at(graph.label, graph.in_blossom[w] == 1) do
                  {graph, base} = scan_blossom(graph, vertex, w)

                  if base >= 0 do
                    AddBlossom.call(graph, base, k)
                  else
                    # this.augmentMatching(k)
                    # augmented = true
                    # break
                  end
                else
                end
              end
            end
        end
      end)
    end
  end

  defp scan_blossom(graph, v, w, base \\ -1, path \\ []) do
    {graph, base} =
      if v !== -1 or w !== -1 do
        b = graph.in_blossom[v]

        if Bitwise.band(graph.label[b], 4) do
          base = graph.blossom_base[b]

          {graph, base}
        else
          path = path ++ [b]
          graph = %{graph | label: List.replace_at(graph.label, b, 5)}

          {v, _b} =
            if graph.label_end[b] == -1 do
              {-1, b}
            else
              v = graph.endpoint[graph.label_end[b]]
              b = graph.in_blossom[v]
              {graph.endpoint[graph.label_end[b]], b}
            end

          {v, w} =
            if w !== -1 do
              v = Bitwise.bxor(v, w)
              w = Bitwise.bxor(w, v)
              v = Bitwise.bxor(v, w)

              {v, w}
            end

          scan_blossom(graph, v, w, base, path)
        end
      else
        Enum.reduce(0..(length(path) - 1), {graph, base}, fn index, {graph, base} ->
          b = path[index]
          graph = %{graph | label: List.replace_at(graph.label, b, 1)}

          {graph, base}
        end)
      end
  end

  defp assign_labels(graph) do
    Enum.reduce(0..(graph.num_of_vertices - 1), graph, fn vertex, acc ->
      if Enum.at(graph.mate, vertex) == -1 and
           Enum.at(graph.label, Enum.at(graph.in_blossom, vertex)) == 0 do
        assign_label(acc, vertex, 1, -1)
      else
        acc
      end
    end)
  end

  defp assign_label(graph, vertex, label, label_end) do
    Logger.debug("Assign label: #{vertex}, #{label}, #{label_end}")
    blossom = Enum.at(graph.in_blossom, vertex)

    graph_label =
      graph.label
      |> List.replace_at(vertex, label)
      |> List.replace_at(blossom, label)

    graph_label_end =
      graph.label_end
      |> List.replace_at(vertex, label_end)
      |> List.replace_at(blossom, label_end)

    graph_best_edge =
      graph.best_edge
      |> List.replace_at(vertex, -1)
      |> List.replace_at(blossom, -1)

    graph = %{graph | label: graph_label, label_end: graph_label_end, best_edge: graph_best_edge}

    case label do
      1 ->
        Logger.debug("Pushed leaves: #{blossom_leaves(graph, blossom)}")
        graph_queue = graph.queue ++ blossom_leaves(graph, blossom)

        %{graph | queue: graph_queue}

      2 ->
        base = Enum.at(graph.blossom_base, blossom)
        endpoint = Enum.at(graph.endpoint, graph.mate[base])
        assign_label(graph, endpoint, 1, Bitwise.bxor(graph.mate[base], 1))

      _ ->
        graph
    end
  end
end
