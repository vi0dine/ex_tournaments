alias ExTournaments.Pairings.Swiss.Player
alias ExTournaments.Pairings.Swiss

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
