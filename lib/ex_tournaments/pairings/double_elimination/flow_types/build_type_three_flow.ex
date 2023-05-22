defmodule ExTournaments.Pairings.DoubleElimination.FlowTypes.BuildTypeThreeFlow do
  @moduledoc """
  Module for building matches flow in the upper bracket when remainder of participants is higher than half of them
  """

  alias ExTournaments.Match
  alias ExTournaments.Utils.PairingHelpers

  @doc """
  Takes existing list of `%ExTournaments.Match{}` structs, indices of the round in the upper and lower bracket, difference between this indices,
  remainder and exponent from the difference between number of participants and power of 2.

  It will populate flow for the case when remainder is upper than half of participant to the nearest power of 2.

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
    current_lose_round_matches = matches |> Enum.filter(fn match -> match.round == lose_round end)

    next_lose_round_matches =
      matches |> Enum.filter(fn match -> match.round == lose_round + 1 end)

    fill = PairingHelpers.fill_pattern(length(win_matches), fill_count)

    route_numbers = generate_route_numbers(matches)

    matches =
      next_lose_round_matches
      |> Enum.reduce(%{matches: matches, count_a: 0, count_b: 0}, fn next_lose_round_match,
                                                                     %{
                                                                       matches: matches,
                                                                       count_a: count_a,
                                                                       count_b: count_b
                                                                     } ->
        {count_a, count_b, matches} =
          assign_on_loss_matches(
            matches,
            win_matches,
            route_numbers,
            current_lose_round_matches,
            next_lose_round_match,
            count_a,
            count_b,
            fill
          )

        %{matches: matches, count_a: count_a + 1, count_b: count_b}
      end)
      |> Map.fetch!(:matches)

    matches =
      matches
      |> Enum.filter(fn m -> m.round == round_diff + 1 end)
      |> Enum.with_index()
      |> Enum.reduce(matches, fn {m, i}, acc ->
        match =
          matches
          |> Enum.find(fn x ->
            x.round == m.round + 1 and x.match == Enum.at(route_numbers, i)
          end)

        acc = acc |> Enum.filter(fn match -> match != m end)

        m =
          Map.merge(m, %{
            win: %Match{
              round: match.round,
              match: match.match
            }
          })

        acc |> Enum.concat([m])
      end)

    %{
      matches: matches,
      win_round: win_round + 1,
      lose_round: lose_round + 1,
      fill_count: fill_count + 1
    }
  end

  defp generate_route_numbers(matches) do
    matches
    |> Enum.sort_by(& &1.match)
    |> Enum.filter(fn match ->
      match.round == 2 and match.player1 == nil and match.player2 == nil
    end)
    |> Enum.map(fn match -> match.match end)
  end

  defp assign_on_loss_matches(
         matches,
         win_matches,
         route_numbers,
         current_lose_round_matches,
         next_lose_round_match,
         count_a,
         count_b,
         fill
       ) do
    win_match_a =
      win_matches
      |> Enum.find(fn x -> x.match == Enum.at(fill, count_a) end)

    if Enum.any?(route_numbers, fn n -> n == next_lose_round_match.match end) do
      assign_on_loss_match_by_route(
        matches,
        current_lose_round_matches,
        win_matches,
        win_match_a,
        count_a,
        count_b,
        fill
      )
    else
      matches = matches |> Enum.filter(fn match -> match != win_match_a end)

      {count_a, count_b,
       Enum.concat(matches, [
         Map.merge(win_match_a, %{
           loss: %Match{
             round: next_lose_round_match.round,
             match: next_lose_round_match.match
           }
         })
       ])}
    end
  end

  defp assign_on_loss_match_by_route(
         matches,
         current_lose_round_matches,
         win_matches,
         win_match_a,
         count_a,
         count_b,
         fill
       ) do
    loss_match = Enum.at(current_lose_round_matches, count_b)

    matches = matches |> Enum.filter(fn match -> match != win_match_a end)

    win_match_a =
      Map.merge(win_match_a, %{
        loss: %Match{
          round: loss_match.round,
          match: loss_match.match
        }
      })

    win_match_b =
      win_matches
      |> Enum.find(fn x -> x.match == Enum.at(fill, count_a + 1) end)

    matches =
      matches
      |> Enum.concat([win_match_a])
      |> Enum.filter(fn match -> match != win_match_b end)

    win_match_b =
      Map.merge(win_match_b, %{
        loss: %Match{
          round: loss_match.round,
          match: loss_match.match
        }
      })

    matches = matches |> Enum.concat([win_match_b])

    {count_a + 1, count_b + 1, matches}
  end
end
