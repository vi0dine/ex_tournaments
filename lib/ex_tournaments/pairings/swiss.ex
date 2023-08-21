defmodule ExTournaments.Pairings.Swiss do
  @moduledoc """
  Module for creation of a Swiss format round
  """

  alias ExTournaments.Utils.EdmondsBlossom
  alias ExTournaments.Utils.EdmondsBlossom.Vertex

  alias ExTournaments.Pairings.Swiss.Weight

  def generate_round(
        players,
        round,
        opts \\ [
          rated: false,
          colors: false,
          bye_factor: 1.5,
          up_down_factor: 1.2
        ]
      ) do
    players =
      players
      |> assign_rating(opts)
      |> assign_colors(opts)
      |> Enum.shuffle()
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
      |> assign_bye(score_pools)
      |> build_pairs(score_pools, score_sums, opts)
      |> Enum.sort_by(&{elem(&1, 0), elem(&1, 1)}, :asc)
      |> format_for_matching()
      |> EdmondsBlossom.call()

    bye_player = find_player_with_bye(players, pairs)

    generate_matches(round, players, pairs, bye_player)
  end

  defp assign_rating(players, opts) do
    if Keyword.get(opts, :rated, false) do
      players
      |> Enum.map(fn player ->
        if is_nil(player.rating) do
          %{player | rating: 0}
        else
          player
        end
      end)
    else
      players
    end
  end

  defp assign_colors(players, opts) do
    if Keyword.get(opts, :colors, false) do
      players
      |> Enum.map(fn player ->
        if is_nil(player.colors) do
          %{player | colors: []}
        else
          player
        end
      end)
    else
      players
    end
  end

  defp build_pairs(players, score_pools, score_sums, opts) do
    Enum.reduce(0..(length(players) - 1), [], fn player_index, acc ->
      current = Enum.at(players, player_index)
      next = Enum.slice(players, (player_index + 1)..-1)

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
        if Enum.member?(current.avoid, opponent.id) do
          {:cont, acc}
        else
          score_sum_index =
            Enum.find_index(score_sums, fn s -> s == current.score + opponent.score end)

          score_group_index =
            Enum.find_index(score_pools, fn s -> s == current.score end) -
              Enum.find_index(score_pools, fn s -> s == opponent.score end)

          weight =
            Weight.calculate_weight(current, opponent, score_sum_index, score_group_index,
              rated: Keyword.get(opts, :rated, false),
              sorted_players: sorted_players,
              colors: Keyword.get(opts, :colors, false),
              bye_factor: Keyword.get(opts, :bye_factor, 1.5),
              up_down_factor: Keyword.get(opts, :up_down_factor, 1.2)
            )

          {:cont, acc ++ [{current.index, opponent.index, weight}]}
        end
      end)
    end)
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

  defp assign_bye(players, score_pools) when rem(length(players), 2) !== 0 do
    max_score_pool = Enum.max(score_pools)

    bye =
      players
      |> Enum.reject(fn player ->
        player.received_bye
      end)
      |> Enum.filter(&(&1.score == max_score_pool))
      |> Enum.random()

    bye =
      if is_nil(bye) do
        Enum.random(players)
      else
        bye
      end

    Enum.reject(players, &(&1.id == bye.id))
  end

  defp assign_bye(players, _score_pools), do: players

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
