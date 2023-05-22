defmodule ExTournaments.Pairings.SingleElimination do
  @moduledoc """
  Module for creation of a single elimination ladder
  """

  require Integer

  alias ExTournaments.Match
  alias ExTournaments.Utils.PairingHelpers

  @doc """
  Takes list with players IDs, index of the first round, flag indicating is third place match should be created
  and flag indicating is players array is ordered.

  Returns list of `%ExTournaments.Match{}` structs for the single elimination format tournament.
  """
  @spec call(list(integer()), integer(), boolean(), boolean()) :: list(Match.t())
  def call(players, starting_round \\ 1, consolation \\ false, ordered \\ false) do
    players_list = PairingHelpers.prepare_players_list(players, ordered)
    {exponent, remainder} = PairingHelpers.calculate_factors(players_list)
    bracket = PairingHelpers.prefill_bracket(exponent)

    round = starting_round
    matches = PairingHelpers.generate_preliminary_matches(remainder, round)

    round = if remainder != 0, do: round + 1, else: round

    {matches, _round} =
      PairingHelpers.generate_regular_matches(
        matches,
        round,
        starting_round,
        exponent,
        :math.floor(exponent) - 1,
        false
      )

    matches
    |> PairingHelpers.set_players_for_first_round(
      bracket,
      starting_round,
      players_list,
      remainder
    )
    |> PairingHelpers.set_byes_for_first_round(players_list, starting_round, exponent, remainder)
    |> add_consolation_match(consolation)
  end

  @spec add_consolation_match(list(Match.t()), boolean()) :: list(Match.t())
  defp add_consolation_match(matches, false), do: matches

  defp add_consolation_match(matches, true) do
    last_round = get_last_round(matches)
    last_match = get_last_match(matches, last_round)

    matches = [
      %Match{
        round: last_round,
        match: last_match + 1,
        player1: nil,
        player2: nil
      }
      | matches
    ]

    matches
    |> Enum.filter(&(&1.round == last_round - 1))
    |> Enum.reduce(matches, fn prev_round_match, acc ->
      acc = Enum.filter(acc, &(&1 != prev_round_match))

      prev_round_match =
        Map.merge(prev_round_match, %{
          loss: %Match{
            round: last_round,
            match: last_match + 1
          }
        })

      Enum.concat(acc, [prev_round_match])
    end)
  end

  @spec get_last_round(list(Match.t())) :: non_neg_integer()
  defp get_last_round(matches) do
    matches
    |> Enum.reduce(0, &Enum.max([&2, &1.round]))
  end

  @spec get_last_match(list(Match.t()), non_neg_integer()) :: non_neg_integer()
  defp get_last_match(matches, last_round) do
    matches
    |> Enum.filter(&(&1.round == last_round))
    |> Enum.reduce(0, &Enum.max([&2, &1.match]))
  end
end
