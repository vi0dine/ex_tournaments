defmodule ExTournaments.Utils.EdmondsBlossom do
  @moduledoc """
  Edmond's Blossom algorithm NIF
  """

  use Rustler, otp_app: :ex_tournaments, crate: "ex_tournaments_blossom"

  @doc """
  Takes list of Vertex structs.

  Returns blossom algorithm pairing for given players.
  """
  def call(_edges), do: :erlang.nif_error(:nif_not_loaded)
end
