defmodule ExTournaments.Pairings.RoundRobinTest do
  use ExUnit.Case
  doctest ExTournaments.Pairings.RoundRobin

  describe "call/3" do
    for num_of_participants <- 1..255 do
      test "should returns correct pairing for #{num_of_participants} participants" do
        fixture =
          File.read!("test/fixtures/pairings/round_robin/rr_#{unquote(num_of_participants)}.json")
          |> Jason.decode!(keys: :atoms)
          |> Enum.map(&ExTournaments.Match.from_map(&1))
          |> Enum.sort_by(&{&1.round, &1.match})

        pairing =
          ExTournaments.Pairings.RoundRobin.call(
            unquote(num_of_participants),
            1,
            true
          )
          |> Enum.sort_by(&{&1.round, &1.match})

        assert pairing == fixture
      end
    end
  end
end
