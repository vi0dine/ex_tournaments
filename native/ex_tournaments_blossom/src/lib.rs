use blossom::graph::AnnotatedGraph;

#[derive(Clone, rustler::NifStruct)]
#[module = "ExTournaments.Utils.EdmondsBlossom.Vertex"]
pub struct Vertex {
    index: usize,
    edges: Vec<usize>,
    weights: Vec<f64>
}

#[derive(rustler::NifStruct)]
#[module = "ExTournaments.Utils.EdmondsBlossom.Matching"]
pub struct Matching {
   player_1: usize,
   player_2: usize
}

#[rustler::nif]
fn call(data: Vec<Vertex>) -> Vec<Matching> {
    let graph_data = data.iter().cloned().map(|n| (n.index, (n.edges, n.weights))).collect();

    let graph = AnnotatedGraph::new(graph_data);
    let matching = graph.maximum_matching();
    let matched_edges = matching.edges();

    return matched_edges.iter().cloned().map(|n| Matching {player_1: n.0, player_2: n.1}).collect()
}

rustler::init!("Elixir.ExTournaments.Utils.EdmondsBlossom", [call]);
