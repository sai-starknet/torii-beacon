use dojo_beacon::beacon::IdValues;

trait Schema<S> {
    fn serialize_values_to_array(self: @S) -> Array<Span<felt252>>;
    fn serialize_values_and_members(
        self: @S,
    ) -> Array<
        IdValues,
    > {
        let mut members = Self::members();
        let mut values_array = Self::serialize_values_to_array(self);
        let mut id_values = ArrayTrait::<IdValues>::new();
        loop {
            match (members.pop_front(), values_array.pop_front()) {
                (
                    Option::Some(member), Option::Some(values),
                ) => { id_values.append(IdValues { id: *member, values: values }); },
                (Option::None, Option::None) => { break; },
                _ => { panic!("Members and values array have different lengths"); },
            }
        };
        id_values
    }
    fn members() -> Span<felt252>;
}

trait SchemaGenerated<S> {
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
