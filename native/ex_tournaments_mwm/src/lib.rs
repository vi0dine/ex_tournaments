extern crate mwmatching;
use mwmatching::{Edges, Matching};

#[derive(Clone, rustler::NifStruct, Debug)]
#[module = "ExTournaments.Utils.MaximumWeightedMatching.Edge"]
pub struct Edge {
    i: usize,
    j: usize,
    weight: i32,
}

#[derive(rustler::NifStruct, Debug)]
#[module = "ExTournaments.Utils.MaximumWeightedMatching.Pair"]
pub struct Pair {
    player_1: usize,
    player_2: Option<usize>,
}

#[rustler::nif]
fn call(data: Vec<Edge>) -> Vec<Pair> {
    let edges: Edges = data
        .iter()
        .cloned()
        .map(|edge| (edge.i, edge.j, edge.weight))
        .collect();

    let results = Matching::new(edges).solve();

    let pairing = results
        .iter()
        .cloned()
        .enumerate()
        .map(|(i, n)| Pair {
            player_1: i,
            player_2: if n == usize::max_value() {
                None
            } else {
                Some(n)
            },
        })
        .collect();

    return pairing;
}

rustler::init!("Elixir.ExTournaments.Utils.MaximumWeightedMatching", [call]);
