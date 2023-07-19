defmodule ExTournaments.Utils.Algorithms.EdmondsBlossom do
  alias ExTournaments.Utils.Algorithms.EdmondsBlossom.{FindMaxWeightMatching, Graph}

  def call(edges, max_cardinality) do
    if length(edges) == 0 do
      edges
    else
      Graph.init(edges, max_cardinality)
      |> FindMaxWeightMatching.call()
    end
  end
end
