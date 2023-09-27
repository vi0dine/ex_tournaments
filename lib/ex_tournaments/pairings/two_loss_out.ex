defmodule ExTournaments.Pairings.TwoLossOut do
  @moduledoc """
  Module for creation of a TwoLossOut format round
  """

  require Logger

  alias ExTournaments.Utils.EdmondsBlossom
  alias ExTournaments.Utils.EdmondsBlossom.Vertex

  alias ExTournaments.Pairings.Swiss.Weight
  alias ExTournaments.Utils.PairingHelpers

  @doc """
  Takes list with players IDs, index of the first round, and lists of additional options for calculations.

  Returns list of `%ExTournaments.Match{}` structs for the SINGLE ROUND of 2LO tournament.
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
          group_diff_factor: 8
        ]
      ) do
    {rewarded, players} =
      if round == 1, do: Enum.split_with(players, & &1.rewarded_with_bye), else: {[], players}

    Logger.info("Find #{length(rewarded)} rewarded players...")

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
      |> assign_bye(score_pools, opts)
      |> build_pairs(score_pools, score_sums, opts)
      |> Enum.sort_by(&{elem(&1, 0), elem(&1, 1)}, :asc)

    matching =
      pairs
      |> format_for_matching()
      |> EdmondsBlossom.call()

    matching_weight = calculate_weight(pairs, matching)

    Logger.debug("Overall matching weight is #{matching_weight}.")

    generate_matches(round, players, rewarded, matching)
  end

  # DEBUG
  defp calculate_weight(pairs, matching) do
    Enum.reduce(matching, 0, fn %{player_1: player_1, player_2: player_2}, acc ->
      {_, _, weight} =
        Enum.find(pairs, fn {p1, p2, _wt} ->
          p1 == player_1 and p2 == player_2
        end)

      Logger.debug("Weight for #{player_1} and #{player_2} is #{weight}.")

      acc + weight
    end)
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
        |> Kernel./(100)
        |> Float.round(4)

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
    |> Enum.reduce([], fn {v1, v2, weight} = edge, acc ->
      reversed_edge = {v2, v1, weight}
      acc ++ [edge, reversed_edge]
    end)
    |> Enum.group_by(&elem(&1, 0))
    |> Enum.map(fn {vertex, edges_data} ->
      %Vertex{
        index: vertex,
        edges: Enum.map(edges_data, &elem(&1, 1)),
        weights: Enum.map(edges_data, &elem(&1, 2))
      }
    end)
  end

  defp assign_bye(players, score_pools, opts) when rem(length(players), 2) !== 0 do
    max_score_pool = Enum.max(score_pools)
    byes_by_seed = Keyword.get(opts, :byes_by_seed)

    byes_pool =
      players
      |> Enum.reject(fn player ->
        player.received_bye
      end)
      |> Enum.filter(&(&1.score == max_score_pool))

    byes_pool =
      if byes_pool == [] do
        players
      else
        byes_pool
      end

    bye =
      if byes_by_seed do
        byes_pool
        |> Enum.sort_by(& &1.index)
        |> List.first()
      else
        Enum.random(byes_pool)
      end

    Enum.reject(players, &(&1.id == bye.id))
  end

  defp assign_bye(players, _score_pools, _opts), do: players

  defp find_players_with_bye(players, rewarded, pairs) do
    players_indices = Enum.map(players, & &1.index)
    paired_indices = Enum.map(pairs, &[&1.player_1, &1.player_2]) |> List.flatten()

    random_bye =
      (players_indices -- paired_indices)
      |> List.first()
      |> then(&Enum.find(players, fn player -> player.index == &1 end))

    [random_bye | rewarded]
  end

  defp generate_matches(round, players, rewarded, pairs) do
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
      find_players_with_bye(players, rewarded, pairs)
      |> Enum.reject(&is_nil(&1))
      |> Enum.with_index(1)
      |> Enum.map(fn {bye, index} ->
        %ExTournaments.Match{
          round: round,
          match: length(regular) + index,
          player1: bye,
          player2: nil
        }
      end)

    regular ++ byes
  end
end
