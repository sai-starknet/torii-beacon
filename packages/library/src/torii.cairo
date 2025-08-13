use beacon_schema::Schema;
use dojo::meta::{Introspect, Ty};
use sai_address::calculate_utc_zero_address;
use sai_core_utils::SerdeAll;
use starknet::ClassHash;
use super::syscalls::{
    emit_delete_record, emit_model_registered, emit_model_with_schema_registered,
    emit_update_member, emit_update_record,
};

pub fn register_table(namespace: ByteArray, name: ByteArray, class_hash: ClassHash) {
    let address = calculate_utc_zero_address(class_hash, [].span());
    emit_model_registered(namespace, name, address, class_hash);
}

pub fn register_table_with_schema<E, +Introspect<E>>(namespace: ByteArray, name: ByteArray) {
    let schema = if let Ty::Struct(s) = Introspect::<E>::ty() {
        s
    } else {
        panic!("Expected a struct type for schema")
    };
    emit_model_with_schema_registered(namespace, name, schema);
}

pub fn set_entity<I, E, +Into<I, felt252>, +Serde<E>>(table: felt252, entity_id: I, entity: @E) {
    emit_update_record(table, entity_id.into(), entity.serialize_all());
}

pub fn set_entities<I, E, +Drop<I>, +Into<I, felt252>, +Serde<E>>(
    table: felt252, entities: Array<(I, @E)>,
) {
    for (entity_id, entity) in entities {
        emit_update_record(table, entity_id.into(), entity.serialize_all());
    }
}

pub fn set_member<I, T, +Into<I, felt252>, +Serde<T>>(
    member_id: felt252, table: felt252, entity_id: I, entity: @T,
) {
    emit_update_member(table, member_id, entity_id.into(), entity.serialize_all());
}

pub fn set_models_member<I, T, +Drop<I>, +Into<I, felt252>, +Serde<T>>(
    member_id: felt252, table: felt252, entities: Array<(I, @T)>,
) {
    for (entity_id, entity) in entities {
        emit_update_member(table, member_id, entity_id.into(), entity.serialize_all());
    }
}

pub fn set_schema<I, S, +Drop<I>, +Into<I, felt252>, +Schema<S>>(
    table: felt252, entity_id: I, schema: @S,
) {
    let id = entity_id.into();
    for (member, value) in schema.serialize_values_and_members() {
        emit_update_member(table, member, id, value);
    }
}

pub fn set_schemas<I, S, +Drop<I>, +Into<I, felt252>, +Schema<S>>(
    table: felt252, schemas: Array<(I, @S)>,
) {
    for (entity_id, schema) in schemas {
        set_schema(table, entity_id, schema)
    }
}

pub fn delete_entity<I, +Into<I, felt252>>(table: felt252, entity_id: I) {
    emit_delete_record(table, entity_id.into());
}

pub fn delete_entities<I, +Drop<I>, +Into<I, felt252>>(table: felt252, entity_ids: Array<I>) {
    for entity_id in entity_ids {
        emit_delete_record(table, entity_id.into());
    }
}
