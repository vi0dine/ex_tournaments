defmodule ExTournaments.Pairings.DoubleElimination.BuildUpperBracketFlow do
  @moduledoc """
  Module for building matches flow in the upper bracket depending on the remainder value
  """

  alias ExTournaments.Pairings.DoubleElimination.FlowTypes.{
    BuildTypeOneFlow,
    BuildTypeTwoFlow,
    BuildTypeThreeFlow
  }

  @doc """
  Takes existing list of `%ExTournaments.Match{}` structs, indices of the round in the upper and lower bracket, difference between this indices,
  remainder and exponent from the difference between number of participants and power of 2. It determines the flow to use to populate matches flow
  by the value of remainder.

  Returns list of `%ExTournaments.Match{}` structs with updated values for next matches after win or loss in the upper bracket.
  """
  @spec call(
          list(Match.t()),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          integer(),
          number(),
          number()
        ) :: %{
          fill_count: non_neg_integer(),
          lose_round: non_neg_integer(),
          matches: list(Match.t()),
          win_round: non_neg_integer()
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
