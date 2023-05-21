defmodule ExTournaments.Pairings.DoubleElimination.BuildLowerBracket do
  alias ExTournaments.Match

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
