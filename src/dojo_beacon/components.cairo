#[derive(Drop, Serde)]
pub struct IdKeysValues {
    pub id: felt252,
    pub keys: Span<felt252>,
    pub values: Span<felt252>,
}

#[derive(Drop, Serde)]
pub struct IdValues {
    pub id: felt252,
    pub values: Span<felt252>,
}

#[derive(Drop, Serde)]
pub struct SelectorValues {
    pub selector: felt252,
    pub values: Span<felt252>,
}


#[derive(Drop, Serde)]
pub struct IdValuesArray {
    pub id: felt252,
    pub values: Array<Span<felt252>>,
}
