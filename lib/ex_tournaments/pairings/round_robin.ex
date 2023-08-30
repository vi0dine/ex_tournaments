defmodule ExTournaments.Pairings.RoundRobin do
  @moduledoc """
  Round Robin pairing using Berger Tables
  """
  require Integer

  alias ExTournaments.Match
  alias ExTournaments.Utils.PairingHelpers

  @spec call(list(integer()), integer(), boolean()) :: list(Match.t())
  def call(players, starting_round_index \\ 1, ordered \\ false) do
    players = PairingHelpers.prepare_players_list(players, ordered)
    players = maybe_add_bye(players)

    last_round = length(players) - 1

    Enum.reduce(starting_round_index..last_round, [], fn round_index, matches ->
      round = prepopulate_matches(round_index, players)
      round = fill_round_matches_info(starting_round_index, round_index, round, players, matches)

      matches ++ round
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(&{&1.round, &1.match})
  end

  defp maybe_add_bye(players) do
    if Integer.is_odd(length(players)) do
      players ++ [nil]
    else
      players
    end
  end

  defp prepopulate_matches(round_index, players) do
    matches_count = div(length(players), 2)

    Enum.map(1..matches_count, fn match_index ->
      %Match{
        round: round_index,
        match: match_index,
        player1: nil,
        player2: nil
      }
    end)
  end

  defp fill_round_matches_info(starting_round, round_index, round, players, _matches)
       when starting_round == round_index do
    round
    |> Enum.with_index()
    |> Enum.map(fn {match, index} ->
      opponent_index = length(players) - index - 1

      %{match | player1: Enum.at(players, index), player2: Enum.at(players, opponent_index)}
    end)
  end

  defp fill_round_matches_info(_starting_round, round_index, round, players, matches) do
    previous_round =
      matches
      |> Enum.reject(&is_nil/1)
      |> Enum.filter(&(&1.round == round_index - 1))

    Enum.map(0..(length(round) - 1), fn match_index ->
      current_round_match = Enum.at(round, match_index)
      previous_round_match = Enum.at(previous_round, match_index)

      if match_index == 0 do
        if previous_round_match.player2 == Enum.at(players, length(players) - 1) do
          opponent_index = Enum.find_index(players, &(&1 == previous_round_match.player1))

          %{
            current_round_match
            | player1: Enum.at(players, length(players) - 1),
              player2: Enum.at(players, find_player_index(opponent_index, players))
          }
        else
          opponent_index = Enum.find_index(players, &(&1 == previous_round_match.player2))

          %{
            current_round_match
            | player2: Enum.at(players, length(players) - 1),
              player1: Enum.at(players, find_player_index(opponent_index, players))
          }
        end
      else
        challenger_index = Enum.find_index(players, &(&1 == previous_round_match.player1))
        opponent_index = Enum.find_index(players, &(&1 == previous_round_match.player2))

        %{
          current_round_match
          | player1: Enum.at(players, find_player_index(challenger_index, players)),
            player2: Enum.at(players, find_player_index(opponent_index, players))
        }
      end
    end)
  end

  defp find_player_index(index, players) do
    if index + div(length(players), 2) > length(players) - 2 do
      index + 1 - div(length(players), 2)
    else
      index + div(length(players), 2)
    end
  end
end
