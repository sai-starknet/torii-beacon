use starknet::{
    ContractAddress, ClassHash, SyscallResultTrait,
    syscalls::{deploy_syscall, get_class_hash_at_syscall, call_contract_syscall},
    class_hash::class_hash_const, contract_address::contract_address_const,
};

use dojo::meta::{IDeployedResourceDispatcher, IDeployedResourceDispatcherTrait};

use dojo_beacon::starknet::calculate_contract_address;

// pub fn deploy_model_contract(class_hash: ClassHash) -> ContractAddress {
//     let contract_address = calculate_contract_address(
//         contract_address_const::<0x0>(), 0x0, class_hash, [].span(),
//     )
//     match call_contract_syscall(calculate_contract_address(
//         contract_address_const::<0x0>(), 0x0, class_hash, [].span(),
//     ), 0x03987a97c4a7d9afb94acf340235e360d24b99d8705f92c954ca28706406d6ed, [].span()){
//         Result::Ok(_) => contract_address,
//         Result::Err(_) => deploy_syscall(class_hash, 0x0, [].span(), true).unwrap_syscall(),
//     }
//     match deploy_syscall(class_hash, 0x0, [].span(), true) {
//         Result::Ok((contract_address, _)) => contract_address,
//         Result::Err(_) => calculate_contract_address(
//             contract_address_const::<0x0>(), 0x0, class_hash, [].span(),
//         ),
//     }
// }

pub fn calculate_model_contract_address(class_hash: ClassHash) -> ContractAddress {
    calculate_contract_address(contract_address_const::<0x0>(), 0x0, class_hash, [].span())
}

pub fn get_model_name(contract_address: ContractAddress) -> ByteArray {
    IDeployedResourceDispatcher { contract_address }.dojo_name()
}
