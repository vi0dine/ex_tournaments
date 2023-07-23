# ExTournaments

Simple package for tournaments management systems which aims to help organizers with:

- Participants pairing:
  - Single Elimination
  - Double Elimination
  - Swiss

## Description

TODO

## Getting Started

### Installing

Add to `mix.exs`

```elixir
defp deps do
  [
    ...
    {:ex_tournaments, "~> 0.2.1"}
  ]
end
```

## Example

### Single Elimination

```elixir
defmodule Example.Single do
  def call do
    participants_list = [1, 2, 3, 4, 5, 6, 7, 8] # Participants IDs list
    starting_round = 1 # Index of the first round
    consolation = true # Is third place match required?
    ordered = true # Is participants_list ordered?

    matches = ExTournaments.SingleElimination.call(participants_list, starting_round, consolation, ordered)
  end
end
```

### Double Elimination

```elixir
defmodule Example.Double do
  def call do
    participants_list = [1, 2, 3, 4, 5, 6, 7, 8] # Participants IDs list
    starting_round = 1 # Index of the first round
    ordered = true # Is participants_list ordered?

    matches = ExTournaments.DoubleElimination.call(participants_list, starting_round, ordered)
  end
end
```

### Swiss

```elixir
defmodule Example.Swiss do
  alias ExTournaments.Pairings.Swiss

  def call do
    players = Enum.map(0..20, fn p_index ->
      %Player{
        id: "player_#{p_index}",
        index: nil,
        score: p_index * 3,
        paired_up_down: false,
        received_bye: false,
        avoid: [],
        colors: [],
        rating: p_index * 2
      }
    end)

    ExTournaments.Pairings.Swiss.generate_round(players, 1)
  end
end
```

### Results

Matches will be a list of `ExTournaments.Match` structs:

```elixir
%ExTournaments.Match{
  round: 1, # index of matches round
  match: 1, # index of the match
  player1: 1, # ID of a first player
  player2: 8, # ID of a second player,
  win: %ExTournament.Match{
    round: 2,
    match: 1
  }, # Match struct with information about next match in case of a win
  loss: %ExTournament.Match{
    round: 4,
    match: 1
  } # Match struct with information about next match in case of a loss
}
```

## Authors

Krzysztof Janiec (viodine@yahoo.com)

## Version History

- 0.2.1

  - Swiss round creation using Edmond's Blossom algorithm.

- 0.1.0
  - Initial Release with single and double elimination pairing creation.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

## Acknowledgments

- [tournament-pairings](https://github.com/slashinfty/tournament-pairings)
