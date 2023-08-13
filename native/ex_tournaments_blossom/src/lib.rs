use blossom::weighted::WeightedGraph;

#[derive(Clone, rustler::NifStruct, Debug)]
#[module = "ExTournaments.Utils.EdmondsBlossom.Vertex"]
pub struct Vertex {
    index: usize,
    edges: Vec<usize>,
    weights: Vec<f64>,
}

#[derive(rustler::NifStruct, Debug)]
#[module = "ExTournaments.Utils.EdmondsBlossom.Matching"]
pub struct Matching {
    player_1: usize,
    player_2: usize,
}

#[rustler::nif]
fn call(data: Vec<Vertex>) -> Vec<Matching> {
    let graph_data = data
        .iter()
        .cloned()
        .map(|n| (n.index, (n.edges, n.weights)))
        .collect::<WeightedGraph>();

    let matching = graph_data.maximin_matching().unwrap();

    let matched_edges = matching.edges();

    return matched_edges
        .iter()
        .cloned()
        .map(|n| Matching {
            player_1: n.0,
            player_2: n.1,
        })
        .collect();
}

rustler::init!("Elixir.ExTournaments.Utils.EdmondsBlossom", [call]);
