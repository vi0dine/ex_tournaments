defmodule ExTournaments.Pairings.DoubleElimination.BuildLowerBracket do
  @moduledoc """
  Module for populating matches in the lower bracket
  """

  alias ExTournaments.Match

  @doc """
  Takes existing list of `%ExTournaments.Match{}` structs, current round index and exponent.
  It append matches for the lower bracket.

  Returns list of `%ExTournaments.Match{}` structs with newly created matches for the lower bracket.
  """
  @spec call(list(Match.t()), non_neg_integer(), number()) :: list(Match.t())
  def call(matches, _round, loser_exponent) when loser_exponent <= -1, do: matches

  def call(matches, round, loser_exponent) do
    {matches, round} =
      Enum.reduce(0..1, {matches, round}, fn _, {matches, round} ->
        matches =
          Enum.reduce(0..trunc(:math.pow(2, loser_exponent) - 1), matches, fn match, matches ->
            matches
            |> Enum.concat([
              %Match{
                round: round,
                match: match + 1,
                player1: nil,
                player2: nil
              }
            ])
          end)

        {matches, round + 1}
      end)

    call(matches, round, loser_exponent - 1)
  end
end
