defmodule ExTournaments.Pairings.DoubleElimination do
  @moduledoc """
  Module for creation of a double elimination ladder
  """

  require Integer

  alias ExTournaments.Match

  @spec call(list(integer()), non_neg_integer(), boolean()) :: list(Match.t())
  def call(players, starting_round, ordered \\ false) do
    players_list = players_list(players, ordered)
    exponent = :math.log2(length(players_list))
    remainder = rem(round(:math.pow(2, exponent)), trunc(:math.pow(2, :math.floor(exponent))))
    bracket = fill_bracket(exponent)

    round = starting_round
    matches = placehold_initial_round(remainder, round)

    round = if remainder != 0, do: round + 1, else: round

    match_exponent = :math.floor(exponent) - 1
    iterated = false

    %{matches: matches, round: round, match_exponent: _match_exponent, iterated: _iterated} =
      build_ladder_draft(matches, round, starting_round, exponent, match_exponent, iterated)

    matches =
      place_players_for_first_round(matches, bracket, starting_round, players_list, remainder)

    matches =
      place_byes_for_first_round(matches, players_list, starting_round, exponent, remainder)

    matches = [
      %Match{
        round: round,
        match: 1,
        player1: nil,
        player2: nil
      }
      | matches
    ]

    matches =
      matches
      |> Enum.map(fn match ->
        if match.round == round - 1 do
          Map.merge(match, %{
            win: %Match{
              round: round,
              match: 1
            }
          })
        else
          match
        end
      end)

    round = round + 1
    round_diff = round - 1

    %{matches: matches, round: round} =
      fill_later_rounds_byas(matches, exponent, round, remainder)

    loser_exponent = :math.floor(exponent) - 2

    %{matches: matches, round: _round, loser_exponent: _loser_exponent} =
      build_losers_ladder_draft(matches, round, loser_exponent)

    fill_count = 0
    win_round = starting_round
    lose_round = round_diff + 1

    %{matches: matches, fill_count: fill_count, win_round: win_round, lose_round: lose_round} =
      fill_rounds_flow(
        matches,
        win_round,
        lose_round,
        fill_count,
        round_diff,
        exponent,
        remainder
      )

    ffwd = 0

    %{matches: matches, ffwd: _ffwd, fill_count: _fill_count} =
      Enum.reduce(
        win_round..(round_diff - 1),
        %{matches: matches, ffwd: ffwd, fill_count: fill_count},
        fn index,
           %{
             matches: matches,
             ffwd: ffwd,
             fill_count: fill_count
           } ->
          lose_matches_a =
            matches
            |> Enum.filter(fn m -> m.round == lose_round - win_round + ffwd + index end)

          lost_matches_b =
            matches
            |> Enum.filter(fn m -> m.round == lose_round - win_round + ffwd + index + 1 end)

          %{lose_matches_a: lose_matches_a, ffwd: ffwd} =
            if length(lose_matches_a) == length(lost_matches_b) do
              %{lose_matches_a: lost_matches_b, ffwd: ffwd + 1}
            else
              %{ffwd: ffwd, lose_matches_a: lose_matches_a}
            end

          win_matches =
            matches
            |> Enum.filter(fn m -> m.round == index end)

          fill = fill_pattern(length(win_matches), fill_count)

          fill_count = fill_count + 1

          matches =
            lose_matches_a
            |> Enum.with_index()
            |> Enum.reduce(matches, fn {m, j}, acc ->
              match =
                win_matches
                |> Enum.find(fn m -> m.match == Enum.at(fill, j) end)

              acc = acc |> Enum.filter(fn m -> m != match end)

              match =
                Map.merge(match, %{
                  loss: %Match{
                    round: m.round,
                    match: m.match
                  }
                })

              acc |> Enum.concat([match])
            end)

          %{matches: matches, ffwd: ffwd, fill_count: fill_count}
        end
      )

    start = if remainder == 0, do: round_diff + 1, else: round_diff + 2

    finish =
      Enum.reduce(matches, 0, fn match, acc ->
        Enum.max([acc, match.round])
      end)

    %{matches: matches} =
      Enum.reduce(start..finish, %{matches: matches}, fn i, %{matches: matches} ->
        lose_matches_a =
          matches
          |> Enum.filter(fn m -> m.round == i end)

        lose_matches_b =
          matches
          |> Enum.filter(fn m -> m.round == i + 1 end)

        lose_matches_a
        |> Enum.with_index()
        |> Enum.reduce(%{matches: matches}, fn {m, j}, %{matches: matches} ->
          match =
            if length(lose_matches_a) == length(lose_matches_b) do
              Enum.at(lose_matches_b, j)
            else
              Enum.at(lose_matches_b, trunc(:math.floor(j / 2)))
            end

          matches = matches |> Enum.filter(fn match -> match != m end)

          m =
            Map.merge(m, %{
              win: %Match{
                round: get_in(match, [Access.key!(:round)]),
                match: get_in(match, [Access.key!(:match)])
              }
            })

          matches = matches |> Enum.concat([m])

          %{matches: matches}
        end)
      end)

    filter =
      matches
      |> Enum.reduce(0, fn match, acc -> Enum.max([acc, match.round]) end)

    match =
      matches
      |> Enum.filter(fn m -> m.round == filter end)
      |> Enum.at(0)

    matches = matches |> Enum.filter(fn m -> m != match end)

    match =
      Map.merge(match, %{
        win: %Match{
          round: round_diff,
          match: 1
        }
      })

    matches = matches |> Enum.concat([match])

    Enum.sort_by(matches, & &1.round, :asc)
  end

  defp fill_rounds_flow(
         matches,
         win_round,
         lose_round,
         fill_count,
         _round_diff,
         _exponent,
         remainder
       )
       when remainder == 0 do
    win_matches = matches |> Enum.filter(fn match -> match.round == win_round end)

    fill = fill_pattern(length(win_matches), fill_count)
    fill_count = fill_count + 1

    %{matches: matches} =
      matches
      |> Enum.filter(fn match -> match.round == lose_round end)
      |> Enum.reduce(%{counter: 0, matches: matches}, fn m,
                                                         %{
                                                           counter: counter,
                                                           matches: matches
                                                         } ->
        Enum.reduce(0..1, %{matches: matches, counter: counter}, fn _,
                                                                    %{
                                                                      matches: matches,
                                                                      counter: counter
                                                                    } ->
          match = win_matches |> Enum.find(fn match -> match.match == Enum.at(fill, counter) end)

          matches = matches |> Enum.filter(fn m -> m != match end)

          match =
            Map.merge(match, %{
              loss: %Match{
                round: m.round,
                match: m.match
              }
            })

          matches = matches |> Enum.concat([match])

          %{counter: counter + 1, matches: matches}
        end)
      end)

    %{
      matches: matches,
      win_round: win_round + 1,
      lose_round: lose_round + 1,
      fill_count: fill_count
    }
  end

  defp fill_rounds_flow(
         matches,
         win_round,
         lose_round,
         fill_count,
         round_diff,
         exponent,
         remainder
       ) do
    if remainder <= :math.pow(2, :math.floor(exponent)) / 2 do
      win_matches = matches |> Enum.filter(fn match -> match.round == win_round end)

      fill = fill_pattern(length(win_matches), fill_count)
      fill_count = fill_count + 1

      matches =
        matches
        |> Enum.filter(fn match -> match.round == lose_round end)
        |> Enum.with_index()
        |> Enum.reduce(matches, fn {m, i}, acc ->
          match = win_matches |> Enum.find(fn m -> m.match == Enum.at(fill, i) end)
          acc = acc |> Enum.filter(fn m -> m != match end)

          match =
            Map.merge(match, %{
              loss: %Match{
                round: m.round,
                match: m.match
              }
            })

          acc |> Enum.concat([match])
        end)

      win_round = win_round + 1
      lose_round = lose_round + 1

      win_matches = matches |> Enum.filter(fn m -> m.round == win_round end)

      fill = fill_pattern(length(win_matches), fill_count)
      fill_count = fill_count + 1

      count_a = 0
      count_b = 0

      route_numbers =
        matches
        |> Enum.filter(fn match ->
          match.round == 2 and (match.player1 == nil or match.player2 == nil)
        end)
        |> Enum.sort_by(& &1.match)
        |> Enum.map(fn match -> trunc(:math.ceil(match.match / 2)) end)

      route_copy = route_numbers

      %{matches: matches, route_copy: _route_copy, count_a: _count_a, count_b: _count_b} =
        matches
        |> Enum.filter(fn match -> match.round == lose_round end)
        |> Enum.reduce(
          %{matches: matches, route_copy: route_copy, count_a: count_a, count_b: count_b},
          fn m, %{matches: matches, route_copy: route_copy, count_a: count_a, count_b: count_b} ->
            Enum.reduce(
              0..1,
              %{matches: matches, route_copy: route_copy, count_a: count_a, count_b: count_b},
              fn _,
                 %{matches: matches, route_copy: route_copy, count_a: count_a, count_b: count_b} ->
                match =
                  win_matches
                  |> Enum.find(fn match -> match.match == Enum.at(fill, count_a) end)

                %{matches: matches, route_copy: route_copy, count_b: count_b} =
                  if Enum.any?(route_copy, fn n -> n == m.match end) do
                    loss_match =
                      matches
                      |> Enum.filter(fn x -> x.round == lose_round - 1 end)
                      |> Enum.at(count_b)

                    count_b = count_b + 1

                    matches = matches |> Enum.filter(fn m -> m != match end)

                    match =
                      Map.merge(match, %{
                        loss: %Match{
                          round: loss_match.round,
                          match: loss_match.match
                        }
                      })

                    matches = matches |> Enum.concat([match])

                    route_copy =
                      route_copy
                      |> List.delete(m.match)

                    %{matches: matches, route_copy: route_copy, count_b: count_b}
                  else
                    matches = matches |> Enum.filter(fn m -> m != match end)

                    match =
                      Map.merge(match, %{
                        loss: %Match{
                          round: m.round,
                          match: m.match
                        }
                      })

                    matches = matches |> Enum.concat([match])

                    %{matches: matches, route_copy: route_copy, count_b: count_b}
                  end

                count_a = count_a + 1

                %{matches: matches, count_a: count_a, count_b: count_b, route_copy: route_copy}
              end
            )
          end
        )

      win_round = win_round + 1
      lose_round = lose_round + 1

      matches =
        matches
        |> Enum.filter(fn m -> m.round == round_diff + 1 end)
        |> Enum.with_index()
        |> Enum.reduce(matches, fn {m, i}, acc ->
          match =
            acc
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

      %{matches: matches, win_round: win_round, lose_round: lose_round, fill_count: fill_count}
    else
      win_matches = matches |> Enum.filter(fn m -> m.round == win_round end)
      lose_matches_a = matches |> Enum.filter(fn m -> m.round == lose_round end)

      lose_round = lose_round + 1
      lose_matches_b = matches |> Enum.filter(fn m -> m.round == lose_round end)

      fill = fill_pattern(length(win_matches), fill_count)
      fill_count = fill_count + 1

      count_a = 0
      count_b = 0

      route_numbers =
        matches
        |> Enum.sort_by(& &1.match)
        |> Enum.filter(fn m -> m.round == 2 and m.player1 == nil and m.player2 == nil end)
        |> Enum.map(fn m -> m.match end)

      %{matches: matches, count_a: _count_a, count_b: _count_b} =
        lose_matches_b
        |> Enum.reduce(%{matches: matches, count_a: count_a, count_b: count_b}, fn m,
                                                                                   %{
                                                                                     matches:
                                                                                       matches,
                                                                                     count_a:
                                                                                       count_a,
                                                                                     count_b:
                                                                                       count_b
                                                                                   } ->
          win_match_a =
            win_matches
            |> Enum.find(fn x -> x.match == Enum.at(fill, count_a) end)

          %{count_a: count_a, count_b: count_b, matches: matches} =
            if Enum.any?(route_numbers, fn n -> n == m.match end) do
              loss_match = Enum.at(lose_matches_a, count_b)

              matches = matches |> Enum.filter(fn match -> match != win_match_a end)

              win_match_a =
                Map.merge(win_match_a, %{
                  loss: %Match{
                    round: loss_match.round,
                    match: loss_match.match
                  }
                })

              matches = matches |> Enum.concat([win_match_a])

              count_a = count_a + 1
              count_b = count_b + 1

              win_match_b =
                win_matches
                |> Enum.find(fn x -> x.match == Enum.at(fill, count_a) end)

              matches = matches |> Enum.filter(fn match -> match != win_match_b end)

              win_match_b =
                Map.merge(win_match_b, %{
                  loss: %Match{
                    round: loss_match.round,
                    match: loss_match.match
                  }
                })

              matches = matches |> Enum.concat([win_match_b])

              %{count_a: count_a, count_b: count_b, matches: matches}
            else
              matches = matches |> Enum.filter(fn match -> match != win_match_a end)

              win_match_a =
                Map.merge(win_match_a, %{
                  loss: %Match{
                    round: m.round,
                    match: m.match
                  }
                })

              matches = matches |> Enum.concat([win_match_a])

              %{count_a: count_a, count_b: count_b, matches: matches}
            end

          count_a = count_a + 1

          %{matches: matches, count_a: count_a, count_b: count_b}
        end)

      win_round = win_round + 1

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

      %{matches: matches, win_round: win_round, lose_round: lose_round, fill_count: fill_count}
    end
  end

  defp fill_bracket(exponent) do
    if :math.floor(exponent) >= 3 do
      Enum.reduce(3..trunc(:math.floor(exponent)), [1, 4, 2, 3], fn i, acc ->
        Enum.reduce_while(0..999, acc, fn j, acc_j ->
          if j <= length(acc_j) - 1 do
            if Integer.is_even(j) do
              new_element = trunc(:math.pow(2, i) + 1 - Enum.at(acc_j, j))

              {:cont, List.insert_at(acc_j, j + 1, new_element)}
            else
              {:cont, acc_j}
            end
          else
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
                match = %Match{
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
                  if match.round == round - 1 do
                    Map.merge(match, %{
                      win: %Match{
                        round: round,
                        match: trunc(:math.ceil(match.match / 2))
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

  defp build_losers_ladder_draft(matches, round, loser_exponent) do
    Enum.reduce_while(
      0..999,
      %{matches: matches, round: round, loser_exponent: loser_exponent},
      fn _, %{matches: matches, round: round, loser_exponent: loser_exponent} = acc ->
        if loser_exponent > -1 do
          {:cont,
           Enum.reduce(0..1, %{matches: matches, round: round}, fn _,
                                                                   %{
                                                                     matches: matches,
                                                                     round: round
                                                                   } ->
             matches =
               Enum.reduce(0..trunc(:math.pow(2, loser_exponent) - 1), matches, fn j, acc_j ->
                 acc_j
                 |> Enum.concat([
                   %Match{
                     round: round,
                     match: j + 1,
                     player1: nil,
                     player2: nil
                   }
                 ])
               end)

             round = round + 1

             %{matches: matches, round: round}
           end)
           |> Map.merge(%{loser_exponent: loser_exponent - 1})}
        else
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
      |> Enum.filter(fn match -> match.round == first_round end)
      |> Enum.sort_by(& &1.match, :asc)
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
    |> Enum.filter(fn match -> match.round != first_round end)
    |> Enum.concat(first_round_matches)
  end

  defp place_byes_for_first_round(matches, players_list, starting_round, exponent, remainder) do
    if remainder != 0 do
      {_, placed_matches} =
        matches
        |> Enum.filter(fn match -> match.round == starting_round end)
        |> Enum.with_index()
        |> Enum.map_reduce(matches, fn {match, index}, acc ->
          player1 = Enum.at(players_list, trunc(:math.pow(2, :math.floor(exponent)) + index))
          player2 = Enum.at(players_list, trunc(:math.pow(2, :math.floor(exponent)) - index - 1))

          next_match =
            acc
            |> Enum.filter(fn match ->
              match.round == starting_round + 1
            end)
            |> Enum.find(fn match ->
              match.player1 == player2 or match.player2 == player2
            end)

          next_match =
            if next_match.player1 == player2 do
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
              win: %Match{
                round: starting_round + 1,
                match: next_match.match
              }
            })

          acc =
            acc
            |> Enum.reject(
              &((&1.round == match.round and &1.match == match.match) or
                  (&1.round == next_match.round and &1.match == next_match.match))
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
        %Match{
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

  defp fill_later_rounds_byas(matches, exponent, round, remainder) when remainder != 0 do
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

      %{matches: matches, round: round}
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

      %{matches: matches, round: round}
    end
  end

  defp fill_later_rounds_byas(matches, _, round, _), do: %{matches: matches, round: round}

  defp players_list(players, ordered) when is_list(players) do
    case ordered do
      true -> players
      false -> Enum.shuffle(players)
    end
  end

  defp players_list(players, _ordered) when is_integer(players) do
    Enum.map(1..players, & &1)
  end

  defp fill_pattern(match_count, fill_count) do
    a = Enum.map(0..(match_count - 1), &(&1 + 1))
    c = rem(fill_count, 4)

    [x, y] =
      case Enum.chunk_every(a, trunc(:math.ceil(length(a) / 2))) do
        [x, y] -> [x, y]
        [x, y, _] -> [x, y]
        [[x]] -> [[], [x]]
      end

    case c do
      0 -> a
      1 -> Enum.reverse(a)
      2 -> Enum.reverse(x) |> Enum.concat(Enum.reverse(y))
      _ -> Enum.concat(y, x)
    end
  end
end
