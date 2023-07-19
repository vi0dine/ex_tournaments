defmodule ExTournaments.Utils.Algorithms.EdmondsBlossom.Helpers do
  def blossom_leaves(graph, blossom) do
    if blossom < graph.num_of_vertices do
      [blossom]
    else
      blossom_children = graph.blossom_children[blossom]

      Enum.reduce(blossom_children, [], fn child, leaves ->
        if child <= graph.num_of_vertices do
          leaves ++ [child]
        else
          leaf_list = blossom_leaves(graph, child)

          Enum.reduce(leaf_list, leaves, fn leaf, acc ->
            acc ++ [leaf]
          end)
        end
      end)
    end
  end

  def slack(graph, edge_index) do
    edge_x = graph.edges[edge_index][0]
    edge_y = graph.edges[edge_index][1]
    weight = graph.edges[edge_index][2]

    graph.dual_var[edge_x] + graph.dual_var[edge_y] - 2 * weight
  end

  def populate_list(length, element) do
    0..length
    |> Enum.map(fn _index ->
      element
    end)
  end

  def p_index(list, index) when index < 0, do: Enum.at(list, length(list) + index)
  def p_index(list, index), do: Enum.at(list, index)
end
