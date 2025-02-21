use starknet::{
    ContractAddress, ClassHash, SyscallResultTrait,
    syscalls::{deploy_syscall, get_class_hash_at_syscall}, class_hash::class_hash_const,
    contract_address::contract_address_const,
};

use dojo::meta::{IDeployedResourceDispatcher, IDeployedResourceDispatcherTrait};

use dojo_beacon::starknet::calculate_contract_address;

pub fn deploy_model_contract(class_hash: ClassHash) -> ContractAddress {
    let contract_address = calculate_contract_address(
        contract_address_const::<0x0>(), 0x0, class_hash, [].span(),
    );
    if get_class_hash_at_syscall(contract_address).unwrap_syscall() == class_hash_const::<0x0>() {
        deploy_syscall(class_hash, 0x0, [].span(), true).unwrap_syscall();
    };
    contract_address
}

pub fn get_model_name(contract_address: ContractAddress) -> ByteArray {
    IDeployedResourceDispatcher { contract_address }.dojo_name()
}
