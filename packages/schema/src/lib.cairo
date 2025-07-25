pub trait Schema<S> {
    fn serialize_values_to_array(self: @S) -> Array<Span<felt252>>;
    fn serialize_values_and_members(
        self: @S,
    ) -> Array<
        (felt252, Span<felt252>),
    > {
        let mut members = Self::members();
        let mut values_array = Self::serialize_values_to_array(self);
        let mut selector_values = ArrayTrait::<(felt252, Span<felt252>)>::new();
        loop {
            match (members.pop_front(), values_array.pop_front()) {
                (
                    Option::Some(selector), Option::Some(value),
                ) => { selector_values.append((*selector, value)); },
                (Option::None, Option::None) => { break; },
                _ => { panic!("Members and values array have different lengths"); },
            }
        }
        selector_values
    }
    fn members() -> Span<felt252>;
}

pub trait SchemaGenerated<S> {
    fn serialize_values_to_array(self: @S) -> Array<Span<felt252>>;
    fn members() -> Span<felt252>;
}


impl SchemaGeneratedImpl<S, +Serde<S>, +SchemaGenerated<S>> of Schema<S> {
    fn serialize_values_to_array(self: @S) -> Array<Span<felt252>> {
        SchemaGenerated::<S>::serialize_values_to_array(self)
    }

    fn members() -> Span<felt252> {
        SchemaGenerated::<S>::members()
    }
}
