defmodule ExTournaments.Pairings.SwissTest do
  use ExUnit.Case
  doctest ExTournaments.Pairings.Swiss

  alias ExTournaments.Pairings.Swiss.Player

  describe "call/3" do
    for num_of_participants <- 6..6 do
      test "should returns correct pairing for #{num_of_participants} participants" do
        fixture =
          File.read!("test/fixtures/pairings/swiss/swiss_#{unquote(num_of_participants)}.json")
          |> Jason.decode!(keys: :atoms)
          |> Enum.map(&ExTournaments.Match.from_map(&1))
          |> Enum.map(fn match ->
            "player_" <> player_1_id = match.player1 || "player_nil"
            "player_" <> player_2_id = match.player2 || "player_nil"

            player_1_id = if player_1_id == "nil", do: nil, else: String.to_integer(player_1_id)
            player_2_id = if player_2_id == "nil", do: nil, else: String.to_integer(player_2_id)

            first_player_id = if player_1_id < player_2_id, do: player_1_id, else: player_2_id

            %{
              first_player_id: first_player_id,
              player1: match.player1 || "player_nil",
              player2: match.player2 || "player_nil"
            }
          end)
          |> Enum.sort_by(& &1.first_player_id)

        players_count = unquote(num_of_participants)

        IO.inspect("Test for #{players_count}")

        players =
          Enum.map(0..(players_count - 1), fn index ->
            score = if rem(index + 1, 2) == 0, do: index * 25, else: index

            %Player{
              id: "player_#{index + 1}",
              score: score,
              paired_up_down: false,
              received_bye: false,
              avoid: [],
              colors: [],
              rating: 0
            }
          end)

        pairing =
          ExTournaments.Pairings.Swiss.generate_round(
            players,
            1,
            ordered: true,
            rated: false,
            colors: false,
            byes_by_seed: true
          )
          |> Enum.map(fn match ->
            player_1_id = if is_nil(match.player1), do: "player_nil", else: match.player1.id
            player_2_id = if is_nil(match.player2), do: "player_nil", else: match.player2.id

            "player_" <> player_1_num_id = player_1_id
            "player_" <> player_2_num_id = player_2_id

            player_1_num_id =
              if player_1_num_id == "nil", do: nil, else: String.to_integer(player_1_num_id)

            player_2_num_id =
              if player_2_num_id == "nil", do: nil, else: String.to_integer(player_2_num_id)

            first_player_id =
              if player_1_num_id < player_2_num_id, do: player_1_num_id, else: player_2_num_id

            %{first_player_id: first_player_id, player1: player_1_id, player2: player_2_id}
          end)
          |> Enum.sort_by(& &1.first_player_id)

        assert pairing == fixture
      end
    end
  end
end
