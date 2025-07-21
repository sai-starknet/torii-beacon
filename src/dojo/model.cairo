use dojo::meta::{IDeployedResourceDispatcher, IDeployedResourceDispatcherTrait};
use starknet::ContractAddress;


pub fn get_model_name(contract_address: ContractAddress) -> ByteArray {
    IDeployedResourceDispatcher { contract_address }.dojo_name()
}
