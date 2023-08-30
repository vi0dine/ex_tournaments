defmodule ExTournaments.Pairings.Swiss.Weight do
  @moduledoc """
  Helpers for weights calculation in Swiss
  """
  def calculate_weight(
        challenger,
        opponent,
        score_sum_index,
        score_group_index,
        opts \\ [
          rated: false,
          sorted_players: [],
          colors: false,
          bye_factor: 1.5,
          up_down_factor: 1.2,
          group_diff_factor: 3
        ]
      ) do
    score_group_diff = abs(score_group_index)

    base_weight(score_sum_index)
    |> weight_by_group_diff(score_group_diff, opts)
    |> weight_by_up_down_pairing(challenger, opponent, score_group_diff, opts)
    |> weight_by_rating(opponent, opts)
    |> weight_by_colors(challenger, opponent, opts)
    |> weight_by_byes(challenger, opponent, opts)
    |> Kernel./(100)
    |> Float.round(4)
  end

  defp base_weight(score_sum_index) do
    14 * :math.log10(score_sum_index + 1)
  end

  defp weight_by_group_diff(weight, score_group_diff, opts) when score_group_diff < 2 do
    group_diff_factor = Keyword.get(opts, :group_diff_factor, 3)

    weight + group_diff_factor / :math.log10(score_group_diff + 2)
  end

  defp weight_by_group_diff(weight, score_group_diff, _opts) do
    weight + 1 / :math.log10(score_group_diff + 2)
  end

  defp weight_by_up_down_pairing(
         weight,
         %{paired_up_down: false},
         %{paired_up_down: false},
         1,
         opts
       ) do
    weight + Keyword.get(opts, :up_down_factor, 1.2)
  end

  defp weight_by_up_down_pairing(weight, _, _, _, _), do: weight

  defp weight_by_rating(weight, opponent, opts) do
    weight_by_rating = Keyword.get(opts, :rated, false)
    sorted_players = Keyword.get(opts, :sorted_players, [])

    if weight_by_rating and length(sorted_players) > 0 do
      opponents_rating = Enum.find_index(sorted_players, &(&1.id == opponent.id))

      weight + (:math.log(length(sorted_players)) - :math.log(opponents_rating + 1)) / 3
    else
      weight
    end
  end

  defp weight_by_colors(weight, challenger, opponent, opts) do
    weight_by_colors = Keyword.get(opts, :colors, false)

    if weight_by_colors do
      challenger_color_score = calculate_color_score(challenger)
      opponent_color_score = calculate_color_score(opponent)

      cond do
        length(challenger.colors) > 1 and Enum.take(challenger.colors, -2) == ["w", "w"] ->
          cond do
            Enum.join(Enum.take(opponent.colors, -2)) == "ww" -> weight
            Enum.join(Enum.take(opponent.colors, -2)) == "bb" -> weight + 7
            true -> weight + 2 / :math.log(4 - abs(opponent_color_score))
          end

        length(challenger.colors) > 1 and Enum.take(challenger.colors, -2) == ["b", "b"] ->
          cond do
            Enum.join(Enum.take(opponent.colors, -2)) == "bb" -> weight
            Enum.join(Enum.take(opponent.colors, -2)) == "ww" -> weight + 8
            true -> weight + 2 / :math.log(4 - abs(opponent_color_score))
          end

        true ->
          5 / (4 * :math.log10(6 - abs(challenger_color_score - opponent_color_score)))
      end
    else
      weight
    end
  end

  defp calculate_color_score(player) do
    Enum.reduce(player.colors, 0, fn color, acc ->
      if color == "w" do
        acc + 1
      else
        acc - 1
      end
    end)
  end

  defp weight_by_byes(
         weight,
         %{received_bye: challenger_received_bye},
         %{received_bye: opponent_received_bye},
         opts
       ) do
    if challenger_received_bye or opponent_received_bye do
      weight * Keyword.get(opts, :bye_factor, 1.5)
    else
      weight
    end
  end
end
