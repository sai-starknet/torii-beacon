use core::num::traits::Zero;
use core::pedersen::pedersen;
use starknet::{ClassHash, ContractAddress};
use super::pedersen::{pedersen_array_hash, pedersen_fixed_array_hash};

const CONTRACT_ADDRESS_PREFIX: felt252 = 0x535441524b4e45545f434f4e54524143545f41444452455353;
const UDC_ADDRESS: ContractAddress =
    0x041a78e741e5af2fec34b695679bc6891742439f7afb8484ecd7766661ad02bf
    .try_into()
    .unwrap();
const ZERO_CONTRACT_ADDRESS: ContractAddress = 0x0.try_into().unwrap();

pub fn calculate_udc_contract_address(
    mut deployer_address: ContractAddress,
    mut salt: felt252,
    class_hash: ClassHash,
    calldata: Span<felt252>,
) -> ContractAddress {
    if deployer_address.is_non_zero() {
        salt = pedersen(deployer_address.into(), salt);
        deployer_address = UDC_ADDRESS;
    }
    calculate_contract_address(deployer_address, salt, class_hash, calldata)
}


pub fn calculate_contract_address(
    deployer_address: ContractAddress,
    salt: felt252,
    class_hash: ClassHash,
    calldata: Span<felt252>,
) -> ContractAddress {
    pedersen_fixed_array_hash(
        [
            CONTRACT_ADDRESS_PREFIX, deployer_address.into(), salt, class_hash.into(),
            pedersen_array_hash(calldata),
        ],
    )
        .try_into()
        .unwrap()
}


pub fn calculate_utc_zero_address(class_hash: ClassHash) -> ContractAddress {
    calculate_contract_address(ZERO_CONTRACT_ADDRESS, 0x0, class_hash, [].span())
}
