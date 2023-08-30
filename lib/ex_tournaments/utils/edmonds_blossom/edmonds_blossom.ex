defmodule ExTournaments.Utils.EdmondsBlossom do
  @moduledoc """
  Edmond's Blossom algorithm NIF
  """

  use Rustler, otp_app: :ex_tournaments, crate: "ex_tournaments_blossom"

  # When your NIF is loaded, it will override this function.
  def call(_edges), do: :erlang.nif_error(:nif_not_loaded)
end
