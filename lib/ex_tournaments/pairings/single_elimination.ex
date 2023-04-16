defmodule ExTournaments.Pairings.SingleElimination do
  require Integer

  def call(players, starting_round \\ 1, consolation \\ false, ordered \\ false) do
    players_list = players_list(players, ordered)
    exponent = :math.log2(length(players_list))
    remainder = rem(round(:math.pow(2, exponent)), trunc(:math.pow(2, :math.floor(exponent))))
    bracket = fill_bracket(exponent)

    round = starting_round
    matches = placehold_initial_round(remainder, round)

    round = if remainder != 0, do: round + 1, else: round

    match_exponent = :math.floor(exponent) - 1
    iterated = false

    %{matches: matches, round: _round, match_exponent: _match_exponent, iterated: _iterated} =
      build_ladder_draft(matches, round, starting_round, exponent, match_exponent, iterated)

    matches =
      place_players_for_first_round(matches, bracket, starting_round, players_list, remainder)

    matches =
      place_byes_for_first_round(matches, players_list, starting_round, exponent, remainder)

    add_consolation_match(matches, consolation)
  end

  defp add_consolation_match(matches, false), do: matches

  defp add_consolation_match(matches, true) do
    last_round =
      matches
      |> Enum.reduce(0, &Enum.max([&2, &1[:round]]))

    last_match =
      matches
      |> Enum.filter(&(&1[:round] == last_round))
      |> Enum.reduce(0, &Enum.max([&2, &1[:match]]))

    matches = [
      %{
        round: last_round,
        match: last_match + 1,
        player1: nil,
        player2: nil
      }
      | matches
    ]

    matches
    |> Enum.filter(&(&1[:round] == last_round - 1))
    |> Enum.reduce(matches, fn prev_round_match, acc ->
      acc = Enum.filter(acc, &(&1 != prev_round_match))

      prev_round_match =
        Map.merge(prev_round_match, %{
          loss: %{
            round: last_round,
            match: last_match + 1
          }
        })

      Enum.concat(acc, [prev_round_match])
    end)
  end

  defp players_list(players, ordered) when is_list(players) do
    case ordered do
      true -> players
      false -> Enum.shuffle(players)
    end
  end

  defp players_list(players, _ordered) when is_integer(players) do
    Enum.map(1..players, & &1)
  end

  defp fill_bracket(exponent) do
    if :math.floor(exponent) >= 3 do
      Enum.reduce(3..trunc(:math.floor(exponent)), [1, 4, 2, 3], fn i, acc ->
        Enum.reduce_while(0..999, acc, fn j, acc_j ->
          cond do
            j <= length(acc_j) - 1 ->
              if Integer.is_even(j) do
                new_element = trunc(:math.pow(2, i) + 1 - Enum.at(acc_j, j))

                {:cont, List.insert_at(acc_j, j + 1, new_element)}
              else
                {:cont, acc_j}
              end

            true ->
              {:halt, acc_j}
          end
        end)
      end)
    else
      [1, 4, 2, 3]
    end
  end

  defp build_ladder_draft(matches, round, starting_round, exponent, match_exponent, iterated) do
    Enum.reduce_while(
      0..9999,
      %{matches: matches, round: round, match_exponent: match_exponent, iterated: iterated},
      fn _,
         %{matches: matches, round: round, match_exponent: match_exponent, iterated: iterated} =
           acc ->
        case round < starting_round + :math.ceil(exponent) do
          true ->
            matches =
              Enum.reduce(0..trunc(:math.pow(2, match_exponent) - 1), matches, fn index, acc ->
                match = %{
                  round: round,
                  match: index + 1,
                  player1: nil,
                  player2: nil
                }

                [match | acc]
              end)

            matches =
              if iterated do
                Enum.map(matches, fn match ->
                  if match[:round] == round - 1 do
                    Map.merge(match, %{
                      win: %{
                        round: round,
                        match: trunc(:math.ceil(match[:match] / 2))
                      }
                    })
                  else
                    match
                  end
                end)
              else
                matches
              end

            {:cont,
             %{
               matches: matches,
               round: round + 1,
               match_exponent: match_exponent - 1,
               iterated: true
             }}

          false ->
            {:halt, acc}
        end
      end
    )
  end

  defp place_players_for_first_round(matches, bracket, starting_round, players_list, remainder) do
    first_round_offset = if remainder == 0, do: 0, else: 1
    first_round = starting_round + first_round_offset

    first_round_matches =
      matches
      |> Enum.filter(fn match -> match[:round] == first_round end)
      |> Enum.sort_by(& &1[:match], :asc)
      |> Enum.with_index()
      |> Enum.map(fn {match, index} ->
        player1 =
          (Enum.at(bracket, trunc(2 * index)) - 1)
          |> then(&Enum.at(players_list, &1))

        player2 =
          (Enum.at(bracket, trunc(2 * index + 1)) - 1)
          |> then(&Enum.at(players_list, &1))

        Map.merge(match, %{
          player1: player1,
          player2: player2
        })
      end)

    matches
    |> Enum.filter(fn match -> match[:round] != first_round end)
    |> Enum.concat(first_round_matches)
  end

  defp place_byes_for_first_round(matches, players_list, starting_round, exponent, remainder) do
    if remainder != 0 do
      {_, placed_matches} =
        matches
        |> Enum.filter(fn match -> match[:round] == starting_round end)
        |> Enum.with_index()
        |> Enum.map_reduce(matches, fn {match, index}, acc ->
          player1 = Enum.at(players_list, trunc(:math.pow(2, :math.floor(exponent)) + index))
          player2 = Enum.at(players_list, trunc(:math.pow(2, :math.floor(exponent)) - index - 1))

          next_match =
            acc
            |> Enum.filter(fn match ->
              match[:round] == starting_round + 1
            end)
            |> Enum.find(fn match ->
              match[:player1] == player2 or match[:player2] == player2
            end)

          next_match =
            if next_match[:player1] == player2 do
              Map.merge(next_match, %{
                player1: nil
              })
            else
              Map.merge(next_match, %{
                player2: nil
              })
            end

          match =
            Map.merge(match, %{
              player1: player1,
              player2: player2,
              win: %{
                round: starting_round + 1,
                match: next_match.match
              }
            })

          acc =
            acc
            |> Enum.reject(&(&1[:round] == match[:round] and &1[:match] == match[:match]))
            |> Enum.reject(
              &(&1[:round] == next_match[:round] and &1[:match] == next_match[:match])
            )
            |> Enum.concat([match, next_match])

          {match, acc}
        end)

      placed_matches
    else
      matches
    end
  end

  defp placehold_initial_round(remainder, round) do
    if remainder !== 0 do
      Enum.map(0..(remainder - 1), fn index ->
        %{
          round: round,
          match: index + 1,
          player1: nil,
          player2: nil
        }
      end)
    else
      []
    end
  end
end
