use dojo::meta::introspect::Struct;
use sai_core_utils::SerdeAll;
use starknet::syscalls::emit_event_syscall;
use starknet::{ClassHash, ContractAddress, SyscallResultTrait};

pub fn emit_namespace_registered(namespace: ByteArray, hash: felt252) {
    emit_event_syscall((selector!(""), namespace).serialize_all(), [hash].span()).unwrap_syscall();
}

pub fn emit_model_with_schema_registered(namespace: ByteArray, name: ByteArray, schema: Struct) {
    emit_event_syscall(
        (selector!("ModelWithSchemaRegistered"), name, namespace).serialize_all(),
        schema.serialize_all(),
    )
        .unwrap_syscall();
}

pub fn emit_model_registered(
    namespace: ByteArray, name: ByteArray, address: ContractAddress, class_hash: ClassHash,
) {
    emit_event_syscall(
        (selector!("ModelRegistered"), name, namespace).serialize_all(),
        [class_hash.into(), address.into()].span(),
    )
        .unwrap_syscall();
}
pub fn emit_set_record(
    selector: felt252, entity_id: felt252, keys: Span<felt252>, values: Span<felt252>,
) {
    emit_event_syscall(
        [selector!("StoreSetRecord"), selector, entity_id].span(), (keys, values).serialize_all(),
    )
        .unwrap_syscall();
}
pub fn emit_update_record(selector: felt252, entity_id: felt252, values: Span<felt252>) {
    emit_event_syscall(
        [selector!("StoreUpdateRecord"), selector, entity_id].span(), values.serialize_all(),
    )
        .unwrap_syscall();
}
pub fn emit_update_member(
    selector: felt252, member_selector: felt252, entity_id: felt252, values: Span<felt252>,
) {
    emit_event_syscall(
        [selector!("StoreUpdateMember"), selector, entity_id, member_selector].span(),
        values.serialize_all(),
    )
        .unwrap_syscall();
}
pub fn emit_delete_record(selector: felt252, entity_id: felt252) {
    emit_event_syscall([selector!("StoreDelRecord"), selector, entity_id].span(), [].span())
        .unwrap_syscall();
}

