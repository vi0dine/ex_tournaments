defmodule ExTournaments.Pairings.Swiss.Player do
  @moduledoc """
  Helper struct for Swiss pairing
  """
  use TypedStruct

  typedstruct do
    field(:id, binary() | non_neg_integer())
    field(:index, non_neg_integer() | nil)
    field(:score, integer())
    field(:paired_up_down, boolean())
    field(:rewarded_with_bye, boolean())
    field(:received_bye, boolean())
    field(:avoid, list(binary() | integer()) | nil)
    field(:colors, list(binary()) | nil)
    field(:rating, number() | nil)
  end
end
