use dojo::meta::{IDeployedResourceDispatcher, IDeployedResourceDispatcherTrait};

use dojo_beacon::utils::calculate_contract_address;
use starknet::{ClassHash, ContractAddress, contract_address::contract_address_const};

pub fn calculate_model_contract_address(class_hash: ClassHash) -> ContractAddress {
    calculate_contract_address(contract_address_const::<0x0>(), 0x0, class_hash, [].span())
}

pub fn get_model_name(contract_address: ContractAddress) -> ByteArray {
    IDeployedResourceDispatcher { contract_address }.dojo_name()
}
