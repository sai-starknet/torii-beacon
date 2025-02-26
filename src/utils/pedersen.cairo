use core::pedersen::pedersen;

pub fn pedersen_array_hash(mut array: Span<felt252>) -> felt252 {
    let mut state = 0;
    let len = array.len().into();
    loop {
        match array.pop_front() {
            Option::Some(value) => { state = pedersen(state, *value); },
            Option::None => { break pedersen(state, len); },
        }
    }
}

pub fn pedersen_fixed_array_hash<
    const SIZE: usize, impl ToSpan: ToSpanTrait<[felt252; SIZE], felt252>,
>(
    array: [felt252; SIZE],
) -> felt252 {
    pedersen_array_hash(ToSpan::span(@array))
}
