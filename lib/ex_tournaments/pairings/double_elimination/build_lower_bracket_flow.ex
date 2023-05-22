defmodule ExTournaments.Pairings.DoubleElimination.BuildLowerBracketFlow do
  @moduledoc """
  Module for building matches flow in the lower bracket
  """

  alias ExTournaments.Match

  @doc """
  Takes existing list of `%ExTournaments.Match{}` structs, remainder indicating difference beetween number of participants
  and power of two and difference between indices of the upper bracket and lower bracket.

  Returns list of `%ExTournaments.Match{}` structs with updated values for next matches after win or loss in the lower bracket.
  """
  @spec call(list(Match.t()), number(), integer()) :: list(Match.t())
  def call(matches, remainder, round_diff) do
    lower_bracket_first_round = if remainder == 0, do: round_diff + 1, else: round_diff + 2

    lower_bracket_last_round =
      Enum.reduce(matches, 0, fn match, acc ->
        Enum.max([acc, match.round])
      end)

    Enum.reduce(lower_bracket_first_round..lower_bracket_last_round, matches, fn round_index,
                                                                                 matches ->
      current_lower_round_matches =
        matches
        |> Enum.filter(fn m -> m.round == round_index end)

      next_lower_round_matches =
        matches
        |> Enum.filter(fn m -> m.round == round_index + 1 end)

      current_lower_round_matches
      |> Enum.with_index()
      |> Enum.reduce(matches, fn {current_lower_round_match, match_index}, matches ->
        update_lower_bracket_on_win_matches(
          matches,
          current_lower_round_matches,
          next_lower_round_matches,
          current_lower_round_match,
          match_index
        )
      end)
    end)
  end

  @spec update_lower_bracket_on_win_matches(
          list(Match.t()),
          list(Match.t()),
          list(Match.t()),
          Match.t(),
          non_neg_integer()
        ) :: list(Match.t())
  defp update_lower_bracket_on_win_matches(
         matches,
         current_lower_round_matches,
         next_lower_round_matches,
         current_lower_round_match,
         match_index
       ) do
    on_win_match =
      get_on_win_match(match_index, current_lower_round_matches, next_lower_round_matches)

    matches = matches |> Enum.filter(fn match -> match != current_lower_round_match end)

    Enum.concat(matches, [
      Map.merge(current_lower_round_match, %{
        win: %Match{
          round: get_in(on_win_match, [Access.key!(:round)]),
          match: get_in(on_win_match, [Access.key!(:match)])
        }
      })
    ])
  end

  @spec get_on_win_match(non_neg_integer(), list(Match.t()), list(Match.t())) :: Match.t()
  defp get_on_win_match(match_index, lose_matches_a, lose_matches_b)
       when length(lose_matches_a) == length(lose_matches_b) do
    Enum.at(lose_matches_b, match_index)
  end

  defp get_on_win_match(match_index, _lose_matches_a, lose_matches_b) do
    Enum.at(lose_matches_b, trunc(:math.floor(match_index / 2)))
  end
end
