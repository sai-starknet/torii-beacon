use sai_core_utils::SerdeAll;
use starknet::syscalls::emit_event_syscall;
use starknet::{ClassHash, ContractAddress, SyscallResultTrait};
use crate::schema::Schema;

fn emit_namespace_registered(namespace: ByteArray, hash: felt252) {
    emit_event_syscall(namespace.serialize_all(), [hash].span()).unwrap_syscall();
}

fn emit_model_registered(
    name: ByteArray, namespace: ByteArray, address: ContractAddress, class_hash: ClassHash,
) {
    emit_event_syscall(
        (name, namespace).serialize_all(), [class_hash.into(), address.into()].span(),
    )
        .unwrap_syscall();
}
fn emit_set_record(
    selector: felt252, entity_id: felt252, keys: Span<felt252>, values: Span<felt252>,
) {
    emit_event_syscall([selector, entity_id].span(), (keys, values).serialize_all())
        .unwrap_syscall();
}
fn emit_update_record(selector: felt252, entity_id: felt252, values: Span<felt252>) {
    emit_event_syscall([selector, entity_id].span(), values.serialize_all()).unwrap_syscall();
}
fn emit_update_member(
    selector: felt252, entity_id: felt252, member_selector: felt252, values: Span<felt252>,
) {
    emit_event_syscall([selector, entity_id, member_selector].span(), values.serialize_all())
        .unwrap_syscall();
}
fn emit_delete_record(selector: felt252, entity_id: felt252) {
    emit_event_syscall([selector, entity_id].span(), [].span()).unwrap_syscall();
}

/// Trait defining methods for emitting events to Torii indexer without requiring a full Dojo
/// world.
/// This version uses a constant TABLE parameter for compile-time table specification.
///
/// This emitter allows direct interaction with Torii by emitting structured data events:
/// - TABLE: Compile-time constant identifier for the table/model
/// - entity_id: Identifier for the row
/// - Data can be: entity (full row), member (single cell), or schema (multiple cells)
trait ConstSysEntityEmitterTrait {
    /// Emits an event for a single entity (full row of data)
    /// * Args:
    ///     * `entity_id` - Identifier for the row
    ///     * `entity` - A complete row of data to emit
    fn emit_entity<I, E, +Drop<I>, +Into<I, felt252>, +Serde<E>>(entity_id: I, entity: @E);

    /// Emits events for multiple entities (full rows of data)
    /// * Args:
    ///     * `entities` - Array of complete rows of data to emit
    fn emit_entities<I, E, +Drop<I>, +Into<I, felt252>, +Serde<E>>(entities: Array<(I, @E)>);

    /// Emits an event for a single member (single cell of data)
    /// * Args:
    ///     * `member_id` - Identifier for the specific field/column
    ///     * `entity_id` - Identifier for the row
    ///     * `entity` - A single cell of data to emit
    fn emit_member<I, T, +Drop<I>, +Into<I, felt252>, +Serde<T>>(
        member_id: felt252, entity_id: I, entity: @T,
    );

    /// Emits events for multiple members (single cells of data)
    /// * Args:
    ///     * `member_id` - Identifier for the specific field/column
    ///     * `entities` - Array of single cells of data to emit
    fn emit_models_member<I, T, +Drop<I>, +Into<I, felt252>, +Serde<T>>(
        member_id: felt252, entities: Array<(I, @T)>,
    );

    /// Emits an event for a single schema (multiple cells of data)
    /// * Args:
    ///     * `entity_id` - Identifier for the row
    ///     * `schema` - Multiple cells of data to emit as schema
    fn emit_schema<I, S, +Drop<I>, +Into<I, felt252>, +Schema<S>>(entity_id: I, schema: @S);

    /// Emits events for multiple schemas (multiple cells of data)
    /// * Args:
    ///     * `schemas` - Array of schema data with multiple cells to emit
    fn emit_schemas<I, S, +Drop<I>, +Into<I, felt252>, +Schema<S>>(schemas: Array<(I, @S)>);
}

pub impl ConstEntityEmitter<const TABLE: felt252> of ConstSysEntityEmitterTrait {
    fn emit_entity<I, E, +Drop<I>, +Into<I, felt252>, +Serde<E>>(entity_id: I, entity: @E) {
        emit_update_record(TABLE, entity_id.into(), entity.serialize_all());
    }

    fn emit_entities<I, E, +Drop<I>, +Into<I, felt252>, +Serde<E>>(entities: Array<(I, @E)>) {
        for (entity_id, entity) in entities {
            emit_update_record(TABLE, entity_id.into(), entity.serialize_all());
        }
    }

    fn emit_member<I, T, +Drop<I>, +Into<I, felt252>, +Serde<T>>(
        member_id: felt252, entity_id: I, entity: @T,
    ) {
        emit_update_member(TABLE, member_id, entity_id.into(), entity.serialize_all());
    }

    fn emit_models_member<I, T, +Drop<I>, +Into<I, felt252>, +Serde<T>>(
        member_id: felt252, entities: Array<(I, @T)>,
    ) {
        for (entity_id, entity) in entities {
            emit_update_member(TABLE, member_id, entity_id.into(), entity.serialize_all());
        }
    }

    fn emit_schema<I, S, +Drop<I>, +Into<I, felt252>, +Schema<S>>(entity_id: I, schema: @S) {
        let id = entity_id.into();
        for (member, value) in schema.serialize_values_and_members() {
            emit_update_member(TABLE, member, id, value);
        }
    }

    fn emit_schemas<I, S, +Drop<I>, +Into<I, felt252>, +Schema<S>>(schemas: Array<(I, @S)>) {
        for (entity_id, schema) in schemas {
            Self::emit_schema(entity_id, schema)
        }
    }
}
