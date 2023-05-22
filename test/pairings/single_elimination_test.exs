defmodule ExTournaments.Pairings.SingleEliminationTest do
  use ExUnit.Case
  doctest ExTournaments.Pairings.SingleElimination

  describe "call/3 without 3rd place match" do
    for num_of_participants <- [4, 6, 8, 11, 17, 25, 32, 40, 47, 60, 88, 110, 129, 256, 312] do
      test "should returns correct pairing for #{num_of_participants} participants" do
        fixture =
          File.read!(
            "test/fixtures/pairings/single_elimination/single_elimination_#{unquote(num_of_participants)}_participants.json"
          )
          |> Jason.decode!(keys: :atoms)
          |> Enum.map(&ExTournaments.Match.from_map(&1))
          |> Enum.sort_by(&{&1.round, &1.match})

        pairing =
          ExTournaments.Pairings.SingleElimination.call(
            unquote(num_of_participants),
            1,
            false,
            false
          )
          |> Enum.sort_by(&{&1.round, &1.match})

        assert pairing == fixture
      end
    end
  end

  describe "call/3 with 3rd place match" do
    for num_of_participants <- [4, 6, 8, 11, 17, 25, 32, 40, 47, 60, 88, 110, 129, 256, 312] do
      test "should returns correct pairing for #{num_of_participants} participants" do
        fixture =
          File.read!(
            "test/fixtures/pairings/single_elimination/consolation/single_elimination_consolation_#{unquote(num_of_participants)}_participants.json"
          )
          |> Jason.decode!(keys: :atoms)
          |> Enum.map(&ExTournaments.Match.from_map(&1))
          |> Enum.sort_by(&{&1.round, &1.match})

        pairing =
          ExTournaments.Pairings.SingleElimination.call(
            unquote(num_of_participants),
            1,
            true,
            true
          )
          |> Enum.sort_by(&{&1.round, &1.match})

        assert pairing == fixture
      end
    end
  end
end
