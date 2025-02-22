use core::{pedersen::PedersenTrait, hash::HashStateTrait};
use core::poseidon::poseidon_hash_span;
use core::num::traits::Zero;
use starknet::{Store, SyscallResult, storage_access::StorageBaseAddress};

fn sn_storage_from_span(selectors: Span<felt252>) -> felt252 {
    assert(selectors.len().is_non_zero(), 'Selectors cannot be empty');
    pedersen_hash_non_empty_span(selectors)
}

fn pedersen_hash_span(span: Span<felt252>) -> felt252 {
    match span.len() {
        0 => 0,
        _ => pedersen_hash_non_empty_span(span),
    }
}

fn pedersen_hash_non_empty_span(mut span: Span<felt252>) -> felt252 {
    let mut state = PedersenTrait::new(*span[0]);
    loop {
        match span.pop_front() {
            Option::Some(value) => { state = state.update(*value); },
            Option::None => { break state.finalize(); },
        }
    }
}

impl SpanStorage<T, +starknet::Store<T>> of starknet::Store<Span<T>> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<Span<T>> {
        let len: u32 = Store::read(address_domain, base)?;
        let base_felt252: felt252 = base.into();
        for i in 0..len {
            let address = poseidon_hash_span([base_felt252, i.into()].span());
        }
    }
}
