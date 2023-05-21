defmodule ExTournaments.Pairings.DoubleElimination.FlowTypes.BuildTypeOneFlow do
  alias ExTournaments.Match
  alias ExTournaments.Utils.PairingHelpers

  def call(
        matches,
        win_round,
        lose_round,
        fill_count,
        _round_diff,
        _exponent,
        _remainder
      ) do
    win_matches = matches |> Enum.filter(fn match -> match.round == win_round end)
    fill = PairingHelpers.fill_pattern(length(win_matches), fill_count)

    %{matches: matches} =
      matches
      |> Enum.filter(fn match -> match.round == lose_round end)
      |> Enum.reduce(%{counter: 0, matches: matches}, fn lose_round_match,
                                                         %{
                                                           counter: counter,
                                                           matches: matches
                                                         } ->
        Enum.reduce(0..1, %{matches: matches, counter: counter}, fn _,
                                                                    %{
                                                                      matches: matches,
                                                                      counter: counter
                                                                    } ->
          matches = assign_on_loss_match(matches, win_matches, lose_round_match, fill, counter)

          %{counter: counter + 1, matches: matches}
        end)
      end)

    %{
      matches: matches,
      win_round: win_round + 1,
      lose_round: lose_round + 1,
      fill_count: fill_count + 1
    }
  end

  defp assign_on_loss_match(matches, win_matches, lose_round_match, fill, counter) do
    match =
      win_matches
      |> Enum.find(fn match -> match.match == Enum.at(fill, counter) end)

    matches = matches |> Enum.filter(fn m -> m != match end)

    Enum.concat(matches, [
      Map.merge(match, %{
        loss: %Match{
          round: lose_round_match.round,
          match: lose_round_match.match
        }
      })
    ])
  end
end
