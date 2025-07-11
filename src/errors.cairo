use core::{panics::panic_with_byte_array, never};

use starknet::ContractAddress;

pub fn not_contract_owner(user: ContractAddress) -> never {
    panic_with_byte_array(@format!("`{user:?}` is not the owner of the contract"))
}

pub fn not_contract_writer(user: ContractAddress) -> never {
    panic_with_byte_array(@format!("`{user:?}` is not a writer of the contract"))
}

pub fn not_namespace_hash_or_contract_owner(user: ContractAddress, namespace: felt252) -> never {
    panic_with_byte_array(
        @format!("`{user:?}` is not the owner of the contract or namespace `{namespace}`"),
    )
}

pub fn not_namespace_or_contract_owner(user: ContractAddress, namespace: ByteArray) -> never {
    panic_with_byte_array(
        @format!("`{user:?}` is not the owner of the contract or namespace `{namespace}`"),
    )
}

pub fn not_namespace_or_contract_writer(user: ContractAddress, namespace: felt252) -> never {
    panic_with_byte_array(
        @format!("`{user:?}` is not a writer of the contract or namespace `{namespace}`"),
    )
}

pub fn not_model_namespace_or_contract_owner(
    user: ContractAddress, namespace: felt252, model: felt252,
) -> never {
    panic_with_byte_array(
        @format!(
            "`{user:?}` is not the owner of the contract, namespace `{namespace}` or model `{model}`",
        ),
    )
}

pub fn not_model_namespace_or_contract_writer(
    user: ContractAddress, namespace: felt252, model: felt252,
) -> never {
    panic_with_byte_array(
        @format!(
            "`{user:?}` is not a writer of the contract, namespace `{namespace}` or model `{model}`",
        ),
    )
}

pub fn not_model_writer(user: ContractAddress, selector: felt252) -> never {
    panic_with_byte_array(
        @format!("`{user:?}` is not a writer of the model with selector {selector:x}"),
    )
}

pub fn invalid_resource_selector(selector: felt252) -> never {
    panic_with_byte_array(@format!("Invalid resource selector `{}`", selector))
}

pub fn invalid_naming(kind: ByteArray, what: @ByteArray) -> never {
    panic_with_byte_array(
        @format!("{kind} `{what}` is invalid according to Dojo naming rules: ^[a-zA-Z0-9_]+$"),
    )
}

pub fn namespace_already_registered(namespace: @ByteArray) -> never {
    panic_with_byte_array(@format!("Namespace `{}` is already registered", namespace))
}

pub fn namespace_not_registered(namespace: @ByteArray) -> never {
    panic_with_byte_array(@format!("Namespace `{}` is not registered", namespace))
}

pub fn model_already_registered(namespace: @ByteArray, name: @ByteArray) -> never {
    panic_with_byte_array(
        @format!("Resource (Model) `{}-{}` is already registered", namespace, name),
    )
}

pub fn model_not_registered(namespace: @ByteArray) -> never {
    panic_with_byte_array(@format!("Model `{}` is not registered", namespace))
}

pub fn resource_conflict(name: @ByteArray, expected_type: @ByteArray) -> never {
    panic_with_byte_array(
        @format!("Resource `{}` is registered but not as {}", name, expected_type),
    )
}
