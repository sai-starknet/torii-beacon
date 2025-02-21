use core::{pedersen::{PedersenTrait, pedersen}, hash::HashStateTrait};
use core::num::traits::Zero;
use starknet::{ContractAddress, ClassHash, contract_address_const};

const CONTRACT_ADDRESS_PREFIX: felt252 = 0x535441524b4e45545f434f4e54524143545f41444452455353;
const UNIVERSAL_DEPLOYER_CONTRACT: felt252 =
    0x041a78e741e5af2fec34b695679bc6891742439f7afb8484ecd7766661ad02bf;

pub fn calculate_udc_contract_address(
    mut deployer_address: ContractAddress,
    mut salt: felt252,
    class_hash: ClassHash,
    calldata: Span<felt252>,
) -> ContractAddress {
    if deployer_address.is_non_zero() {
        salt = pedersen(deployer_address.into(), salt);
        deployer_address = contract_address_const::<UNIVERSAL_DEPLOYER_CONTRACT>();
    }
    calculate_contract_address(deployer_address, salt, class_hash, calldata)
}


pub fn calculate_contract_address(
    deployer_address: ContractAddress,
    salt: felt252,
    class_hash: ClassHash,
    calldata: Span<felt252>,
) -> ContractAddress {
    pedersen_hash_fixed_array(
        [
            CONTRACT_ADDRESS_PREFIX, deployer_address.into(), salt, class_hash.into(),
            pedersen_hash_span(calldata),
        ],
    )
        .try_into()
        .unwrap()
}

fn pedersen_hash_span(mut span: Span<felt252>) -> felt252 {
    let mut state = PedersenTrait::new(0);
    let len = span.len().into();
    loop {
        match span.pop_front() {
            Option::Some(value) => { state = state.update(*value); },
            Option::None => { break state.update(len).finalize(); },
        }
    }
}

fn pedersen_hash_fixed_array<const SIZE: usize, impl ToSpan: ToSpanTrait<[felt252; SIZE], felt252>>(
    array: [felt252; SIZE],
) -> felt252 {
    pedersen_hash_span(ToSpan::span(@array))
}
