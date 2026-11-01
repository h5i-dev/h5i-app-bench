fn main() {
    let values: std::collections::BTreeMap<_, _> = asyncapi_reference::all_values().into_iter().collect();
    println!("{}", serde_json::to_string(&values).unwrap());
}
