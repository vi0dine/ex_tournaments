defmodule ExTournaments.Utils.Algorithms.EdmondsBlossom.Graph do
  use TypedStruct

  import ExTournaments.Utils.Algorithms.EdmondsBlossom.Helpers

  typedstruct do
    @typedoc "A struct for Edmond's Blossom algorithm"

    field(:max_cardinality, non_neg_integer(), enforce: true)
    field(:dual_var, list())
    field(:edges, list())
    field(:best_edge, list())
    field(:num_of_edges, non_neg_integer())
    field(:allow_edge, list())
    field(:num_of_vertices, non_neg_integer())
    field(:mate, list())
    field(:label, list())
    field(:label_end, list())
    field(:blossom_base, list())
    field(:blossom_parent, list())
    field(:blossom_children, list())
    field(:blossom_endpoints, list())
    field(:blossom_best_edges, list())
    field(:in_blossom, list())
    field(:unused_blossoms, list())
    field(:endpoints, list())
    field(:neighbours, list())
    field(:max_weight, non_neg_integer())
    field(:queue, list())
  end

  def init(edges, max_cardinality) do
    num_of_vertices = populate_vertices(edges)
    num_of_edges = length(edges)
    max_weight = Enum.max_by(edges, &Enum.at(&1, 2)) |> Enum.at(2)

    %__MODULE__{
      max_cardinality: max_cardinality,
      dual_var: populate_dual_var(num_of_vertices, max_weight),
      edges: edges,
      best_edge: populate_list(num_of_vertices, -1),
      num_of_edges: num_of_edges,
      allow_edge: populate_list(num_of_edges, false),
      num_of_vertices: num_of_vertices,
      mate: populate_list(num_of_vertices, -1),
      label: populate_list(2 * num_of_vertices, 0),
      label_end: populate_list(2 * num_of_vertices, -1),
      blossom_base: populate_blossom_base(num_of_vertices),
      blossom_parent: populate_list(2 * num_of_vertices, -1),
      blossom_children: populate_list(2 * num_of_vertices, []),
      blossom_endpoints: populate_list(2 * num_of_vertices, []),
      blossom_best_edges: populate_list(2 * num_of_vertices, []),
      in_blossom: 0..num_of_vertices,
      unused_blossoms: num_of_vertices..(2 * num_of_vertices),
      endpoints: populate_endpoints(edges),
      neighbours: populate_neighbours(edges, num_of_vertices),
      max_weight: max_weight,
      queue: []
    }
  end

  def reset_values(graph) do
    %{
      graph
      | label: populate_list(2 * graph.num_of_vertices, 0),
        best_edge: populate_list(2 * graph.num_of_vertices, -1),
        blossom_best_edges: populate_list(2 * graph.num_of_vertices, []),
        allow_edge: populate_list(graph.num_of_edges, false),
        queue: []
    }
  end

  defp populate_vertices(edges) do
    Enum.reduce(edges, 0, fn edge, acc ->
      [v1, v2, _] = edge
      vertices_count = acc

      vertices_count = if v1 >= vertices_count, do: v1 + 1, else: vertices_count
      vertices_count = if v2 >= vertices_count, do: v2 + 1, else: vertices_count

      vertices_count
    end)
  end

  defp populate_endpoints(edges) do
    Enum.reduce(0..(2 * length(edges) - 1), [], fn edge_index, acc ->
      endpoint =
        Enum.at(edges, Bitwise.bnot(Bitwise.bnot(div(edge_index, 2))))
        |> Enum.at(Integer.mod(edge_index, 2))

      List.insert_at(acc, edge_index, endpoint)
    end)
  end

  defp populate_neighbours(edges, num_of_vertices) do
    initial_neighbours = populate_list(num_of_vertices, [])

    Enum.reduce(0..(length(edges) - 1), initial_neighbours, fn edge_index, acc ->
      [v1, v2, _] = Enum.at(edges, edge_index)

      neighbour_1 = Enum.at(acc, v1) |> List.insert_at(0, 2 * edge_index + 1)
      neighbour_2 = Enum.at(acc, v2) |> List.insert_at(0, 2 * edge_index)

      acc
      |> List.replace_at(v1, neighbour_1)
      |> List.replace_at(v2, neighbour_2)
    end)
  end

  defp populate_blossom_base(num_of_vertices) do
    base = Enum.to_list(0..num_of_vertices)
    negs = populate_list(num_of_vertices, -1)

    base ++ negs
  end

  defp populate_dual_var(num_of_vertices, max_weight) do
    max_weights = populate_list(num_of_vertices, max_weight)
    zeros = populate_list(num_of_vertices, 0)

    max_weights ++ zeros
  end
end
