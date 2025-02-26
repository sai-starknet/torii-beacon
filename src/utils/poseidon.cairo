use core::poseidon::poseidon_hash_span;
use super::serde::serialize_inline;

pub fn poseidon_hash_value<T, +Serde<T>>(value: @T) -> felt252 {
    poseidon_hash_span(serialize_inline(value).span())
}
