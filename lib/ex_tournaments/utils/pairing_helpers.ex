defmodule ExTournaments.Utils.PairingHelpers do
  @moduledoc """
  Collection of helpers to use in pairings algorithms
  """
  require Integer

  alias ExTournaments.Match

  @spec prepare_players_list(list(integer()), boolean()) :: list(integer())
  def prepare_players_list(players, ordered) when is_list(players) do
    case ordered do
      true -> players
      false -> Enum.shuffle(players)
    end
  end

  def prepare_players_list(players, _ordered) when is_integer(players) do
    Enum.map(1..players, & &1)
  end

  @spec calculate_factors(list(integer())) :: tuple()
  def calculate_factors(players) do
    exponent = :math.log2(length(players))
    remainder = rem(round(:math.pow(2, exponent)), trunc(:math.pow(2, :math.floor(exponent))))

    {exponent, remainder}
  end

  @spec prefill_bracket(float()) :: list(integer())
  def prefill_bracket(exponent) do
    if :math.floor(exponent) >= 3 do
      Enum.reduce(3..trunc(:math.floor(exponent)), [1, 4, 2, 3], fn exponent, seeds ->
        update_bracket(seeds, 0, exponent)
      end)
    else
      [1, 4, 2, 3]
    end
  end

  defp update_bracket(seeds, index, _exponent) when index > length(seeds) - 1, do: seeds

  defp update_bracket(seeds, index, exponent) do
    if Integer.is_even(index) do
      new_element = trunc(:math.pow(2, exponent) + 1 - Enum.at(seeds, index))

      update_bracket(List.insert_at(seeds, index + 1, new_element), index + 1, exponent)
    else
      update_bracket(seeds, index + 1, exponent)
    end
  end

  @spec generate_preliminary_matches(number(), integer()) :: list(Match.t())
  def generate_preliminary_matches(remainder, _round) when remainder == 0, do: []

  def generate_preliminary_matches(remainder, round) do
    Enum.map(0..(remainder - 1), fn index ->
      %Match{
        round: round,
        match: index + 1,
        player1: nil,
        player2: nil
      }
    end)
  end

  @spec generate_regular_matches(
          list(Match.t()),
          non_neg_integer(),
          non_neg_integer(),
          number(),
          number(),
          boolean()
        ) :: {list(Match.t()), integer()}
  def generate_regular_matches(matches, round, starting_round, exponent, match_exponent, iterated) do
    if round < starting_round + :math.ceil(exponent) do
      matches =
        matches
        |> prepend_empty_matches(round, match_exponent)
        |> assign_on_win_match(round, iterated)

      generate_regular_matches(
        matches,
        round + 1,
        starting_round,
        exponent,
        match_exponent - 1,
        true
      )
    else
      {matches, round}
    end
  end

  @spec prepend_empty_matches(list(Match.t()), non_neg_integer(), number()) :: list(Match.t())
  defp prepend_empty_matches(matches, round, match_exponent) do
    Enum.reduce(0..trunc(:math.pow(2, match_exponent) - 1), matches, fn index, acc ->
      match = %Match{
        round: round,
        match: index + 1,
        player1: nil,
        player2: nil
      }

      [match | acc]
    end)
  end

  @spec assign_on_win_match(list(Match.t()), non_neg_integer(), boolean()) :: list(Match.t())
  defp assign_on_win_match(matches, _round, false), do: matches

  defp assign_on_win_match(matches, round, _iterated) do
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
  end

  @spec set_players_for_first_round(
          list(Match.t()),
          list(integer()),
          non_neg_integer(),
          list(non_neg_integer()),
          number()
        ) :: list(Match.t())
  def set_players_for_first_round(matches, bracket, starting_round, players_list, remainder) do
    first_round_offset = if remainder == 0, do: 0, else: 1
    first_round = starting_round + first_round_offset

    matches
    |> Enum.filter(fn match -> match.round == first_round end)
    |> Enum.sort_by(& &1.match, :asc)
    |> Enum.with_index()
    |> Enum.map(fn {match, index} ->
      assign_players_to_match(match, index, bracket, players_list)
    end)
    |> append_first_round_matches(matches, first_round)
  end

  @spec assign_players_to_match(
          Match.t(),
          non_neg_integer(),
          list(non_neg_integer()),
          list(non_neg_integer())
        ) :: Match.t()
  defp assign_players_to_match(match, index, bracket, players_list) do
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
  end

  @spec append_first_round_matches(list(Match.t()), list(Match.t()), non_neg_integer()) ::
          list(Match.t())
  defp append_first_round_matches(first_round_matches, matches, first_round) do
    matches
    |> Enum.filter(fn match -> match.round != first_round end)
    |> Enum.concat(first_round_matches)
  end

  def set_byes_for_first_round(matches, _players_list, _starting_round, _exponent, 0), do: matches

  def set_byes_for_first_round(matches, players_list, starting_round, exponent, _remainder) do
    matches
    |> Enum.filter(fn match -> match.round == starting_round end)
    |> Enum.with_index()
    |> Enum.reduce(matches, fn {match, index}, acc ->
      player1 = Enum.at(players_list, trunc(:math.pow(2, :math.floor(exponent)) + index))
      player2 = Enum.at(players_list, trunc(:math.pow(2, :math.floor(exponent)) - index - 1))
      next_match = found_next_match(acc, starting_round, player2) |> assign_bye(player2)
      match = update_match_data(match, player1, player2, starting_round, next_match)

      update_matches_list(acc, match, next_match)
    end)
  end

  defp found_next_match(matches, starting_round, player2) do
    matches
    |> Enum.filter(fn match ->
      match.round == starting_round + 1
    end)
    |> Enum.find(fn match ->
      match.player1 == player2 or match.player2 == player2
    end)
  end

  defp assign_bye(next_match, player2) when next_match.player1 == player2 do
    Map.merge(next_match, %{
      player1: nil
    })
  end

  defp assign_bye(next_match, _player2) do
    Map.merge(next_match, %{
      player2: nil
    })
  end

  defp update_match_data(match, player1, player2, starting_round, next_match) do
    Map.merge(match, %{
      player1: player1,
      player2: player2,
      win: %Match{
        round: starting_round + 1,
        match: next_match.match
      }
    })
  end

  defp update_matches_list(matches, match, next_match) do
    matches
    |> Enum.reject(
      &((&1.round == match.round and &1.match == match.match) or
          (&1.round == next_match.round and &1.match == next_match.match))
    )
    |> Enum.concat([match, next_match])
  end

  def fill_pattern(match_count, fill_count) do
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
