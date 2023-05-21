defmodule ExTournaments.Pairings.DoubleElimination.BuildMatchesFlow do
  alias ExTournaments.Pairings.DoubleElimination.FlowTypes.{
    BuildTypeOneFlow,
    BuildTypeTwoFlow,
    BuildTypeThreeFlow
  }

  def call(
        matches,
        win_round,
        lose_round,
        fill_count,
        round_diff,
        exponent,
        remainder
      ) do
    cond do
      remainder == 0 ->
        BuildTypeOneFlow.call(
          matches,
          win_round,
          lose_round,
          fill_count,
          round_diff,
          exponent,
          remainder
        )

      remainder <= :math.pow(2, :math.floor(exponent)) / 2 ->
        BuildTypeTwoFlow.call(
          matches,
          win_round,
          lose_round,
          fill_count,
          round_diff,
          exponent,
          remainder
        )

      true ->
        BuildTypeThreeFlow.call(
          matches,
          win_round,
          lose_round,
          fill_count,
          round_diff,
          exponent,
          remainder
        )
    end
  end
end
