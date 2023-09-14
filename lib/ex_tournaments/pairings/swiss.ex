defmodule ExTournaments.Pairings.Swiss do
  @moduledoc """
  Module for creation of a Swiss format round
  """

  require Logger

  alias ExTournaments.Utils.MaximumWeightedMatching
  alias ExTournaments.Utils.MaximumWeightedMatching.Edge

  alias ExTournaments.Pairings.Swiss.Weight
  alias ExTournaments.Utils.PairingHelpers

  @doc """
  Takes list with players IDs, index of the first round, and lists of additional options for calculations.

  Returns list of `%ExTournaments.Match{}` structs for the SINGLE ROUND of Swiss tournament.
  """
  @spec generate_round(list(integer()), integer(), keyword()) :: list
  def generate_round(
        players,
        round,
        opts \\ [
          ordered: false,
          rated: false,
          colors: false,
          bye_factor: 1.5,
          byes_by_seed: false,
          up_down_factor: 1.2,
          group_diff_factor: 3
        ]
      ) do
    players =
      players
      |> assign_rating(opts)
      |> assign_colors(opts)
      |> PairingHelpers.prepare_players_list(opts[:ordered])
      |> Enum.with_index()
      |> Enum.map(fn {player, index} ->
        %{player | index: index}
      end)

    score_pools =
      players
      |> Enum.map(& &1.score)
      |> Enum.uniq()
      |> Enum.sort()

    score_sums =
      score_pools
      |> Enum.with_index()
      |> Enum.map(fn {score, i} ->
        Enum.map(i..(length(score_pools) - 1), fn j ->
          score + Enum.at(score_pools, j)
        end)
      end)
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort()

    pairs =
      players
      |> build_pairs(score_pools, score_sums, opts)
      |> Enum.sort_by(&{elem(&1, 0), elem(&1, 1)}, :asc)

    matching =
      pairs
      |> format_for_matching()
      |> MaximumWeightedMatching.call()
      |> Enum.uniq_by(&Enum.max([&1.player_1, &1.player_2]))

    matching_weight = calculate_weight(pairs, matching)

    Logger.debug("Overall matching weight is #{matching_weight}.")

    bye_player = find_player_with_bye(players, matching)

    generate_matches(round, players, matching, bye_player)
  end

  # DEBUG
  defp calculate_weight(pairs, matching) do
    Enum.reduce(matching, 0, fn %{player_1: player_1, player_2: player_2}, acc ->
      weight = calculate_absolute_weight(pairs, player_1, player_2)

      if weight == 0 do
        Logger.debug("Player #{player_1} got a BYE.")
      else
        Logger.debug("Weight for #{player_1} and #{player_2} is #{weight}.")
      end

      acc + weight
    end)
  end

  defp calculate_absolute_weight(pairs, player_1, player_2) do
    case Enum.find(pairs, fn {p1, p2, _wt} ->
           (p1 == player_1 and p2 == player_2) or (p1 == player_2 and p2 == player_1)
         end) do
      {_, _, weight} ->
        weight

      nil ->
        0
    end
  end

  defp assign_rating(players, opts) do
    if Keyword.get(opts, :rated, false) do
      players
      |> Enum.map(&assign_rating/1)
    else
      players
    end
  end

  defp assign_rating(%{rating: nil} = player), do: %{player | rating: 0}
  defp assign_rating(player), do: player

  defp assign_colors(players, opts) do
    if Keyword.get(opts, :colors, false) do
      players
      |> Enum.map(&assign_colors/1)
    else
      players
    end
  end

  defp assign_colors(%{colors: nil} = player), do: %{player | colors: []}
  defp assign_colors(player), do: player

  defp build_pairs(players, score_pools, score_sums, opts) do
    Enum.reduce(0..(length(players) - 1), [], fn player_index, acc ->
      current = Enum.at(players, player_index)
      next = Enum.slice(players, (player_index + 1)..-1)

      allow_rematch = Enum.all?(next, &Enum.member?(current.avoid, &1.id))

      sorted_players =
        if Keyword.get(opts, :rated, false) do
          next
          |> Enum.sort(fn a, b ->
            abs(current.rating - a.rating) >= abs(current.rating - b.rating)
          end)
        else
          []
        end

      Enum.reduce_while(next, acc, fn opponent, acc ->
        find_pairing(
          acc,
          current,
          opponent,
          score_sums,
          score_pools,
          sorted_players,
          allow_rematch,
          opts
        )
      end)
    end)
  end

  defp find_pairing(
         acc,
         current,
         opponent,
         score_sums,
         score_pools,
         sorted_players,
         allow_rematch,
         opts
       ) do
    if Enum.member?(current.avoid, opponent.id) and !allow_rematch do
      {:cont, acc}
    else
      score_sum_index = score_sum_index(current, opponent, score_sums)
      score_group_index = score_group_index(current, opponent, score_pools)

      weight =
        Weight.calculate_weight(current, opponent, score_sum_index, score_group_index,
          ordered: Keyword.get(opts, :ordered, false),
          rated: Keyword.get(opts, :rated, false),
          sorted_players: sorted_players,
          colors: Keyword.get(opts, :colors, false),
          bye_factor: Keyword.get(opts, :bye_factor, 1.5),
          up_down_factor: Keyword.get(opts, :up_down_factor, 1.2),
          group_diff_factor: Keyword.get(opts, :group_diff_factor, 8)
        )

      {:cont, acc ++ [{current.index, opponent.index, weight}]}
    end
  end

  defp score_sum_index(current, opponent, score_sums) do
    Enum.find_index(score_sums, fn s -> s == current.score + opponent.score end)
  end

  defp score_group_index(current, opponent, score_pools) do
    Enum.find_index(score_pools, fn s -> s == current.score end) -
      Enum.find_index(score_pools, fn s -> s == opponent.score end)
  end

  defp format_for_matching(pairs) do
    pairs
    |> Enum.map(fn {i, j, weight} ->
      %Edge{
        i: i,
        j: j,
        weight: trunc(weight * 1_000_000)
      }
    end)
  end

  defp find_player_with_bye(players, pairs) do
    players_indices = Enum.map(players, & &1.index)
    paired_indices = Enum.map(pairs, &[&1.player_1, &1.player_2]) |> List.flatten()

    (players_indices -- paired_indices)
    |> List.first()
    |> then(&Enum.find(players, fn player -> player.index == &1 end))
  end

  defp generate_matches(round, players, pairs, bye) do
    regular =
      pairs
      |> Enum.with_index(1)
      |> Enum.map(fn {pair, index} ->
        %ExTournaments.Match{
          round: round,
          match: index,
          player1: Enum.find(players, &(&1.index == pair.player_1)),
          player2: Enum.find(players, &(&1.index == pair.player_2))
        }
      end)

    byes =
      if is_nil(bye),
        do: [],
        else: [
          %ExTournaments.Match{
            round: round,
            match: length(regular) + 1,
            player1: bye,
            player2: nil
          }
        ]

    regular ++ byes
  end
end
