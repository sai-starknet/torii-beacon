use core::pedersen::pedersen;
use core::num::traits::Zero;
use starknet::{ContractAddress, ClassHash};

const CONTRACT_ADDRESS_PREFIX: felt252 = 0x535441524b4e45545f434f4e54524143545f41444452455353;

pub fn _calculate_contract_address(
    deployer_address: ContractAddress,
    mut salt: felt252,
    class_hash: ClassHash,
    calldata: Span<felt252>,
) -> ContractAddress {
    if deployer_address.is_non_zero() {
        salt = pedersen(deployer_address.into(), salt);
    }
    pedersen_hash_span(
        [
            CONTRACT_ADDRESS_PREFIX, deployer_address.into(), salt, class_hash.into(),
            pedersen_hash_span(calldata),
        ]
            .span(),
    )
        .try_into()
        .unwrap()
}

pub fn calculate_contract_address(
    deployer_address: ContractAddress,
    mut salt: felt252,
    class_hash: ClassHash,
    calldata: Span<felt252>,
) -> ContractAddress {
    pedersen_hash_span(
        [
            CONTRACT_ADDRESS_PREFIX, deployer_address.into(), salt, class_hash.into(),
            pedersen_hash_span(calldata),
        ]
            .span(),
    )
        .try_into()
        .unwrap()
}

fn pedersen_hash_span(mut span: Span<felt252>) -> felt252 {
    let mut state = 0;
    let len = span.len().into();
    loop {
        match span.pop_front() {
            Option::Some(value) => { state = pedersen(state, *value); },
            Option::None => { break pedersen(state, len); },
        }
    }
}
