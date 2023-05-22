defmodule ExTournaments.Pairings.DoubleElimination.FlowTypes.BuildTypeOneFlow do
  @moduledoc """
  Module for building matches flow in the upper bracket when number of participant is power of 2
  """

  alias ExTournaments.Match
  alias ExTournaments.Utils.PairingHelpers

  @doc """
  Takes existing list of `%ExTournaments.Match{}` structs, indices of the round in the upper and lower bracket, difference between this indices,
  remainder and exponent from the difference between number of participants and power of 2.

  It will populate flow for the case when remainder is equal 0 which means number of participants is equal the power of 2.

  Returns list of `%ExTournaments.Match{}` structs with updated values for next matches after win or loss in the upper bracket.
  """
  @spec call(
          list(Match.t()),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          integer(),
          number(),
          number()
        ) :: %{
          fill_count: non_neg_integer(),
          lose_round: non_neg_integer(),
          matches: list(Match.t()),
          win_round: non_neg_integer()
        }
  def call(
        matches,
        win_round,
        lose_round,
        fill_count,
        _round_diff,
        _exponent,
        _remainder
      ) do
    win_matches = matches |> Enum.filter(fn match -> match.round == win_round end)
    fill = PairingHelpers.fill_pattern(length(win_matches), fill_count)

    %{matches: matches} =
      matches
      |> Enum.filter(fn match -> match.round == lose_round end)
      |> Enum.reduce(%{counter: 0, matches: matches}, fn lose_round_match,
                                                         %{
                                                           counter: counter,
                                                           matches: matches
                                                         } ->
        Enum.reduce(0..1, %{matches: matches, counter: counter}, fn _,
                                                                    %{
                                                                      matches: matches,
                                                                      counter: counter
                                                                    } ->
          matches = assign_on_loss_match(matches, win_matches, lose_round_match, fill, counter)

          %{counter: counter + 1, matches: matches}
        end)
      end)

    %{
      matches: matches,
      win_round: win_round + 1,
      lose_round: lose_round + 1,
      fill_count: fill_count + 1
    }
  end

  defp assign_on_loss_match(matches, win_matches, lose_round_match, fill, counter) do
    match =
      win_matches
      |> Enum.find(fn match -> match.match == Enum.at(fill, counter) end)

    matches = matches |> Enum.filter(fn m -> m != match end)

    Enum.concat(matches, [
      Map.merge(match, %{
        loss: %Match{
          round: lose_round_match.round,
          match: lose_round_match.match
        }
      })
    ])
  end
end
