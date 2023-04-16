defmodule ExTournaments.Match do
  @moduledoc """
  A struct representing a single match in the tournament.
  """

  use TypedStruct

  typedstruct do
    @typedoc "A match"

    field(:round, non_neg_integer())
    field(:match, non_neg_integer())
    field(:player1, non_neg_integer())
    field(:player2, non_neg_integer())
    field(:win, __MODULE__.t())
    field(:loss, __MODULE__.t())
  end

  def from_map(map) do
    win = if is_nil(map[:win]), do: nil, else: struct(__MODULE__, map[:win])
    loss = if is_nil(map[:loss]), do: nil, else: struct(__MODULE__, map[:loss])

    struct(
      __MODULE__,
      Map.merge(map, %{
        win: win,
        loss: loss
      })
    )
  end
end
