defmodule ExTournaments.Pairings.DoubleElimination do
  @moduledoc """
  Module for creation of a double elimination ladder
  """

  require Integer

  alias ExTournaments.Match
  alias ExTournaments.Utils.PairingHelpers

  alias ExTournaments.Pairings.DoubleElimination.{
    BuildLowerBracket,
    BuildMatchesFlow,
    FillRoundsByes
  }

  @spec call(list(integer()), non_neg_integer(), boolean()) :: list(Match.t())
  def call(players, starting_round, ordered \\ false) do
    players_list = PairingHelpers.prepare_players_list(players, ordered)
    {exponent, remainder} = PairingHelpers.calculate_factors(players_list)
    bracket = PairingHelpers.prefill_bracket(exponent)
    matches = PairingHelpers.generate_preliminary_matches(remainder, starting_round)

    first_round = if remainder != 0, do: starting_round + 1, else: starting_round

    {matches, round} =
      PairingHelpers.generate_regular_matches(
        matches,
        first_round,
        starting_round,
        exponent,
        :math.floor(exponent) - 1,
        false
      )

    matches =
      matches
      |> PairingHelpers.set_players_for_first_round(
        bracket,
        starting_round,
        players_list,
        remainder
      )
      |> PairingHelpers.set_byes_for_first_round(
        players_list,
        starting_round,
        exponent,
        remainder
      )
      |> prepend_first_match(round)
      |> Enum.map(&assign_on_win_match(&1, round))

    round_diff = round

    {matches, round} = FillRoundsByes.call(matches, exponent, round + 1, remainder)
    matches = BuildLowerBracket.call(matches, round, :math.floor(exponent) - 2)

    %{matches: matches, fill_count: fill_count, win_round: win_round, lose_round: lose_round} =
      BuildMatchesFlow.call(
        matches,
        starting_round,
        round_diff + 1,
        0,
        round_diff,
        exponent,
        remainder
      )

    matches =
      assign_on_loss_matches(matches, win_round, win_round, lose_round, round_diff, fill_count, 0)

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

  defp prepend_first_match(matches, round) do
    [
      %Match{
        round: round,
        match: 1,
        player1: nil,
        player2: nil
      }
      | matches
    ]
  end

  defp assign_on_win_match(match, round) when match.round != round - 1, do: match

  defp assign_on_win_match(match, round) do
    Map.merge(match, %{
      win: %Match{
        round: round,
        match: 1
      }
    })
  end

  defp assign_on_loss_matches(
         matches,
         round_index,
         win_round,
         lose_round,
         round_diff,
         fill_count,
         ffwd
       ) do
    lose_matches_a =
      matches
      |> Enum.filter(fn m -> m.round == lose_round - win_round + ffwd + round_index end)

    lost_matches_b =
      matches
      |> Enum.filter(fn m -> m.round == lose_round - win_round + ffwd + round_index + 1 end)

    {ffwd, lose_matches_a} =
      if length(lose_matches_a) == length(lost_matches_b) do
        {ffwd + 1, lost_matches_b}
      else
        {ffwd, lose_matches_a}
      end

    win_matches =
      matches
      |> Enum.filter(fn m -> m.round == round_index end)

    matches =
      lose_matches_a
      |> Enum.with_index()
      |> Enum.reduce(matches, fn {lose_match, index}, acc ->
        match =
          win_matches
          |> Enum.find(fn m ->
            m.match ==
              Enum.at(PairingHelpers.fill_pattern(length(win_matches), fill_count), index)
          end)

        acc = acc |> Enum.filter(fn m -> m != match end)

        match =
          Map.merge(match, %{
            loss: %Match{
              round: lose_match.round,
              match: lose_match.match
            }
          })

        acc |> Enum.concat([match])
      end)

    if round_index < round_diff - 1 do
      assign_on_loss_matches(
        matches,
        round_index + 1,
        win_round,
        lose_round,
        round_diff,
        fill_count + 1,
        ffwd
      )
    else
      matches
    end
  end
end
