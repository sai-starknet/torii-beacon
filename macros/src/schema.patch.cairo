impl $struct_type$SchemaGeneratedImpl of torii_beacon::schema::SchemaGenerated<$struct_type$>{
    fn serialize_values_to_array(self: @$struct_type$) -> Array<Span<felt252>>{
        let mut serialized_array = ArrayTrait::<Span<felt252>>::new();
$serialize_members_to_array$
        serialized_array
    }
    fn members() -> Span<felt252>{
        [ 
$member_selectors$ 
        ].span()
    }
}


