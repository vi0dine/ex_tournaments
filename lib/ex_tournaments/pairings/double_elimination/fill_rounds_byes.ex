defmodule ExTournaments.Pairings.DoubleElimination.FillRoundsByes do
  @moduledoc """
  Module for populating matches from BYEs
  """

  alias ExTournaments.Match

  @doc """
  Takes list of `%ExTournaments.Match{}`, round index and remainder and exponent from the difference
  between number of participants and power of 2. It will populate matches from the BYEs from the previous round.

  Returns an updated list of matches.
  """
  @spec call(list(Match.t()), number(), non_neg_integer(), number()) ::
          {list(Match.t()), non_neg_integer()}
  def call(matches, exponent, round, remainder) when remainder != 0 do
    if remainder <= trunc(:math.pow(2, :math.floor(exponent)) / 2) do
      matches =
        Enum.map(0..(remainder - 1), fn i ->
          %Match{
            round: round,
            match: i + 1,
            player1: nil,
            player2: nil
          }
        end)
        |> Enum.concat(matches)

      round = round + 1

      {matches, round}
    else
      matches =
        Enum.map(0..trunc(remainder - :math.pow(2, :math.floor(exponent) - 1) - 1), fn i ->
          %Match{
            round: round,
            match: i + 1,
            player1: nil,
            player2: nil
          }
        end)
        |> Enum.concat(matches)

      round = round + 1

      matches =
        Enum.map(0..trunc(:math.pow(2, :math.floor(exponent) - 1) - 1), fn i ->
          %Match{
            round: round,
            match: i + 1,
            player1: nil,
            player2: nil
          }
        end)
        |> Enum.concat(matches)

      round = round + 1

      {matches, round}
    end
  end

  def call(matches, _, round, _), do: {matches, round}
end
