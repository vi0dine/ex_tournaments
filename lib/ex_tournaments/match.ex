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

  @doc """
  Converting map to a `Match` struct

  ## Examples

  iex> ExTournaments.Match.from_map(%{
    round: 1,
    match: 1,
    player1: 1,
    player2: 2,
    win: %{
      round: 2,
      match: 1
    },
    loss: %{
      round: 7,
      match: 1
    }
  })
  %ExTournaments.Match{
    player2: 2,
    player1: 1,
    match: 1,
    round: 1
    loss: %ExTournaments.Match{
      loss: nil,
      win: nil,
      player2: nil,
      player1: nil,
      match: 1,
      round: 7
    },
    win: %ExTournaments.Match{
      loss: nil,
      win: nil,
      player2: nil,
      player1: nil,
      match: 1,
      round: 2
    },
  }
  """
  @spec from_map(map()) :: __MODULE__.t()
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
