defmodule ExTournaments.Pairings.DoubleElimination.FlowTypes.BuildTypeTwoFlow do
  @moduledoc """
  Module for building matches flow in the upper bracket when remainder of participants is lower than half of them
  """

  alias ExTournaments.Match
  alias ExTournaments.Utils.PairingHelpers

  @doc """
  Takes existing list of `%ExTournaments.Match{}` structs, indices of the round in the upper and lower bracket, difference between this indices,
  remainder and exponent from the difference between number of participants and power of 2.

  It will populate flow for the case when remainder is lower than half of participant to the nearest power of 2.

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
        round_diff,
        _exponent,
        _remainder
      ) do
    win_matches = matches |> Enum.filter(fn match -> match.round == win_round end)
    fill = PairingHelpers.fill_pattern(length(win_matches), fill_count)
    matches = assign_on_loss_matches(matches, lose_round, win_matches, fill)

    next_win_round_matches = matches |> Enum.filter(fn m -> m.round == win_round + 1 end)
    fill = PairingHelpers.fill_pattern(length(next_win_round_matches), fill_count + 1)

    route_numbers = generate_route_numbers(matches)

    matches =
      update_on_loss_matches(matches, next_win_round_matches, lose_round, fill, route_numbers)

    matches = assign_on_win_matches(matches, route_numbers, round_diff)

    %{
      matches: matches,
      win_round: win_round + 2,
      lose_round: lose_round + 2,
      fill_count: fill_count + 2
    }
  end

  defp assign_on_loss_matches(matches, lose_round, win_matches, fill) do
    matches
    |> Enum.filter(fn match -> match.round == lose_round end)
    |> Enum.with_index()
    |> Enum.reduce(matches, fn {lose_round_match, index}, acc ->
      match = win_matches |> Enum.find(fn m -> m.match == Enum.at(fill, index) end)

      acc
      |> Enum.filter(fn m -> m != match end)
      |> Enum.concat([
        Map.merge(match, %{
          loss: %Match{
            round: lose_round_match.round,
            match: lose_round_match.match
          }
        })
      ])
    end)
  end

  defp generate_route_numbers(matches) do
    matches
    |> Enum.filter(fn match ->
      match.round == 2 and (match.player1 == nil or match.player2 == nil)
    end)
    |> Enum.sort_by(& &1.match)
    |> Enum.map(fn match -> trunc(:math.ceil(match.match / 2)) end)
  end

  defp update_on_loss_matches(matches, next_win_round_matches, lose_round, fill, route_numbers) do
    %{matches: matches} =
      matches
      |> Enum.filter(fn match -> match.round == lose_round + 1 end)
      |> Enum.reduce(
        %{matches: matches, route_numbers: route_numbers, count_a: 0, count_b: 0},
        fn next_lose_round_match,
           %{matches: matches, route_numbers: route_numbers, count_a: count_a, count_b: count_b} ->
          Enum.reduce(
            0..1,
            %{matches: matches, route_numbers: route_numbers, count_a: count_a, count_b: count_b},
            fn _,
               %{
                 matches: matches,
                 route_numbers: route_numbers,
                 count_a: count_a,
                 count_b: count_b
               } ->
              {matches, route_numbers, count_b} =
                update_on_loss_match_by_route(
                  matches,
                  next_win_round_matches,
                  lose_round,
                  next_lose_round_match,
                  route_numbers,
                  count_a,
                  count_b,
                  fill
                )

              %{
                matches: matches,
                count_a: count_a + 1,
                count_b: count_b,
                route_numbers: route_numbers
              }
            end
          )
        end
      )

    matches
  end

  defp assign_on_win_matches(matches, route_numbers, round_diff) do
    matches
    |> Enum.filter(fn m -> m.round == round_diff + 1 end)
    |> Enum.with_index()
    |> Enum.reduce(matches, fn {next_round_match, index}, matches ->
      match =
        matches
        |> Enum.find(fn match ->
          match.round == next_round_match.round + 1 and
            match.match == Enum.at(route_numbers, index)
        end)

      matches = matches |> Enum.filter(fn match -> match != next_round_match end)

      next_round_match =
        Map.merge(next_round_match, %{
          win: %Match{
            round: match.round,
            match: match.match
          }
        })

      Enum.concat(matches, [next_round_match])
    end)
  end

  defp update_on_loss_match_by_route(
         matches,
         next_win_round_matches,
         lose_round,
         next_lose_round_match,
         route_numbers,
         count_a,
         count_b,
         fill
       ) do
    next_win_round_match =
      next_win_round_matches
      |> Enum.find(fn match -> match.match == Enum.at(fill, count_a) end)

    if Enum.any?(route_numbers, fn n -> n == next_lose_round_match.match end) do
      assign_on_loss_by_route_number(
        matches,
        lose_round,
        next_win_round_match,
        next_lose_round_match,
        route_numbers,
        count_b
      )
    else
      matches = matches |> Enum.filter(fn match -> match != next_win_round_match end)

      {Enum.concat(matches, [
         Map.merge(next_win_round_match, %{
           loss: %Match{
             round: next_lose_round_match.round,
             match: next_lose_round_match.match
           }
         })
       ]), route_numbers, count_b}
    end
  end

  defp assign_on_loss_by_route_number(
         matches,
         lose_round,
         next_win_round_match,
         next_lose_round_match,
         route_numbers,
         count_b
       ) do
    loss_round_match =
      matches
      |> Enum.filter(fn match -> match.round == lose_round end)
      |> Enum.at(count_b)

    matches = matches |> Enum.filter(fn m -> m != next_win_round_match end)

    {Enum.concat(matches, [
       Map.merge(next_win_round_match, %{
         loss: %Match{
           round: loss_round_match.round,
           match: loss_round_match.match
         }
       })
     ]), List.delete(route_numbers, next_lose_round_match.match), count_b + 1}
  end
end
