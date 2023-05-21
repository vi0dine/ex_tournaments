defmodule ExTournaments.Pairings.DoubleElimination.FlowTypes.BuildTypeThreeFlow do
  alias ExTournaments.Match
  alias ExTournaments.Utils.PairingHelpers

  def call(
        matches,
        win_round,
        lose_round,
        fill_count,
        round_diff,
        _exponent,
        _remainder
      ) do
    win_matches = matches |> Enum.filter(fn m -> m.round == win_round end)
    lose_matches_a = matches |> Enum.filter(fn m -> m.round == lose_round end)

    lose_round = lose_round + 1
    lose_matches_b = matches |> Enum.filter(fn m -> m.round == lose_round end)

    fill = PairingHelpers.fill_pattern(length(win_matches), fill_count)
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
