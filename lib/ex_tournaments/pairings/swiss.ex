defmodule ExTournaments.Pairings.Swiss do
  @moduledoc """
  Module for creation of a Swiss format round
  """

  alias ExTournaments.Utils.EdmondsBlossom
  alias ExTournaments.Utils.EdmondsBlossom.Vertex

  def generate_round(players, round, rated \\ false, colors \\ false) do
    players =
      players
      |> assign_rating(rated)
      |> assign_colors(colors)
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
      |> assign_bye()
      |> build_pairs(rated, colors, score_pools, score_sums)
      |> Enum.sort_by(&{elem(&1, 0), elem(&1, 1)}, :asc)
      |> format_for_matching()
      |> EdmondsBlossom.call()

    bye_player = find_player_with_bye(players, pairs)

    generate_matches(round, players, pairs, bye_player)
  end

  defp assign_rating(players, false), do: players

  defp assign_rating(players, true) do
    players
    |> Enum.map(fn player ->
      if is_nil(player.rating) do
        %{player | rating: 0}
      else
        player
      end
    end)
  end

  defp assign_colors(players, false), do: players

  defp assign_colors(players, true) do
    players
    |> Enum.map(fn player ->
      if is_nil(player.colors) do
        %{player | colors: []}
      else
        player
      end
    end)
  end

  defp build_pairs(players, rated, colors, score_pools, score_sums) do
    Enum.reduce(0..(length(players) - 1), [], fn player_index, acc ->
      current = Enum.at(players, player_index)

      next = Enum.slice(players, (player_index + 1)..-1)

      sorted =
        if rated do
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

          weight = 14 * :math.log10(score_sum_index + 1)

          score_group_index =
            Enum.find_index(score_pools, fn s -> s == current.score end) -
              Enum.find_index(score_pools, fn s -> s == opponent.score end)

          score_group_diff = abs(score_group_index)

          group_diff_factor =
            if score_group_diff < 2,
              do: 8 / :math.log10(score_group_diff + 2),
              else: 1 / :math.log10(score_group_diff + 2)

          weight = weight + group_diff_factor

          weight =
            if score_group_diff == 1 and current.paired_up_down == false and
                 opponent.paired_up_down == false do
              weight + 1.2
            else
              weight
            end

          weight =
            if rated do
              weight +
                (:math.log(length(sorted)) -
                   :math.log(Enum.find_index(sorted, &(&1.id == opponent.id)) + 1)) / 3
            else
              weight
            end

          weight =
            if colors do
              color_score =
                Enum.reduce(current.colors, 0, fn color, acc ->
                  if color == "w" do
                    acc + 1
                  else
                    acc - 1
                  end
                end)

              opponent_score =
                Enum.reduce(opponent.colors, 0, fn color, acc ->
                  if color == "w" do
                    acc + 1
                  else
                    acc - 1
                  end
                end)

              cond do
                length(current.colors) > 1 and Enum.take(current.colors, -2) == ["w", "w"] ->
                  cond do
                    Enum.join(Enum.take(opponent.colors, -2)) == "ww" -> weight
                    Enum.join(Enum.take(opponent.colors, -2)) == "bb" -> weight + 7
                    true -> weight + 2 / :math.log(4 - abs(opponent_score))
                  end

                length(current.colors) > 1 and Enum.take(current.colors, -2) == ["b", "b"] ->
                  cond do
                    Enum.join(Enum.take(opponent.colors, -2)) == "bb" -> weight
                    Enum.join(Enum.take(opponent.colors, -2)) == "ww" -> weight + 8
                    true -> weight + 2 / :math.log(4 - abs(opponent_score))
                  end

                true ->
                  5 / (4 * :math.log10(6 - abs(color_score - opponent_score)))
              end
            else
              weight
            end

          weight =
            if current.received_bye || opponent.received_bye do
              weight * 1.5
            else
              weight
            end

          {:cont, acc ++ [{current.index, opponent.index, Float.round(weight / 100, 2)}]}
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

  defp assign_bye(players) when rem(length(players), 2) !== 0 do
    bye =
      players
      |> Enum.reject(fn player ->
        player.received_bye
      end)
      |> Enum.random()

    Enum.reject(players, &(&1.id == bye.id))
  end

  defp assign_bye(players), do: players

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
