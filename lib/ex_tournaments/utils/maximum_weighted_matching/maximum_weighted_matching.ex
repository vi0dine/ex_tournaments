defmodule ExTournaments.Utils.MaximumWeightedMatching do
  @moduledoc """
  Van Rantwijk's algorithm port NIF
  """

  use Rustler, otp_app: :ex_tournaments, crate: "ex_tournaments_mwm"

  @doc """
  Takes list of Edge structs with i, j, weight values where i and j are player indices.

  Returns maximum weighted matching for given players.
  """
  def call(_edges), do: :erlang.nif_error(:nif_not_loaded)
end
