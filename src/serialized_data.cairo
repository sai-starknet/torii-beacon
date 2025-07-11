#[derive(Drop, Serde)]
pub struct IdKeysValues {
    pub id: felt252,
    pub keys: Span<felt252>,
    pub value: Span<felt252>,
}

#[derive(Drop, Serde)]
pub struct IdValues {
    pub id: felt252,
    pub values: Span<felt252>,
}

#[derive(Drop, Serde)]
pub struct IdValue {
    pub id: felt252,
    pub value: Span<felt252>,
}


#[derive(Drop, Serde)]
pub struct IdValuesArray {
    pub id: felt252,
    pub values: Array<Span<felt252>>,
}

#[derive(Drop, Serde)]
pub struct SelectorValuesArray {
    pub selector: felt252,
    pub values: Array<Span<felt252>>,
}

#[derive(Drop, Serde)]
pub struct SelectorValue {
    pub selector: felt252,
    pub value: Span<felt252>,
}
