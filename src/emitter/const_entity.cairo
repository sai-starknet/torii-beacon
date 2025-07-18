use crate::HasEmitterComponent;
use crate::emitter::ToriiEventEmitter;
use crate::schema::Schema;
use crate::utils::calculate_utc_zero_address;
use sai_core_utils::SerdeAll;
use starknet::ClassHash;


/// Trait defining methods for emitting events to Torii indexer without requiring a full Dojo world.
/// This version uses a constant TABLE parameter for compile-time table specification.
///
/// This emitter allows direct interaction with Torii by emitting structured data events:
/// - TABLE: Compile-time constant identifier for the table/model
/// - entity_id: Identifier for the row
/// - Data can be: entity (full row), member (single cell), or schema (multiple cells)
pub trait ConstEntityEmitterTrait<const TABLE: felt252, TState> {
    /// Emits an event for registering a new model
    /// * Args:
    ///     * `namespace` - The namespace identifier for the model
    ///     * `name` - The name of the model
    ///     * `class_hash` - The hash representing the model's class
    fn emit_register_model(
        ref self: TState, namespace: ByteArray, name: ByteArray, class_hash: ClassHash,
    );
    /// Emits an event for a single entity (full row of data)
    /// * Args:
    ///     * `entity_id` - Identifier for the row
    ///     * `entity` - A complete row of data to emit
    fn emit_entity<E, +Serde<E>>(ref self: TState, entity_id: felt252, entity: @E);

    /// Emits events for multiple entities (full rows of data)
    /// * Args:
    ///     * `entities` - Array of complete rows of data to emit
    fn emit_entities<E, +Serde<E>>(ref self: TState, entities: Array<(felt252, @E)>);

    /// Emits an event for a single member (single cell of data)
    /// * Args:
    ///     * `member_id` - Identifier for the specific field/column
    ///     * `entity_id` - Identifier for the row
    ///     * `entity` - A single cell of data to emit
    fn emit_member<T, +Serde<T>>(
        ref self: TState, member_id: felt252, entity_id: felt252, entity: @T,
    );

    /// Emits events for multiple members (single cells of data)
    /// * Args:
    ///     * `member_id` - Identifier for the specific field/column
    ///     * `entities` - Array of single cells of data to emit
    fn emit_models_member<T, +Serde<T>>(
        ref self: TState, member_id: felt252, entities: Array<(felt252, @T)>,
    );

    /// Emits an event for a single schema (multiple cells of data)
    /// * Args:
    ///     * `entity_id` - Identifier for the row
    ///     * `schema` - Multiple cells of data to emit as schema
    fn emit_schema<S, +Schema<S>>(ref self: TState, entity_id: felt252, schema: @S);

    /// Emits events for multiple schemas (multiple cells of data)
    /// * Args:
    ///     * `schemas` - Array of schema data with multiple cells to emit
    fn emit_schemas<S, +Schema<S>>(ref self: TState, schemas: Array<(felt252, @S)>);
}

pub impl ConstEntityEmitter<
    const TABLE: felt252, TState, +HasEmitterComponent<TState>, +Drop<TState>,
> of ConstEntityEmitterTrait<TABLE, TState> {
    fn emit_register_model(
        ref self: TState, namespace: ByteArray, name: ByteArray, class_hash: ClassHash,
    ) {
        self
            .emit_model_registered(
                namespace, name, calculate_utc_zero_address(class_hash), class_hash,
            );
    }
    fn emit_entity<E, +Serde<E>>(ref self: TState, entity_id: felt252, entity: @E) {
        self.emit_update_record(TABLE, entity_id, entity.serialize_all());
    }

    fn emit_entities<E, +Serde<E>>(ref self: TState, entities: Array<(felt252, @E)>) {
        for (entity_id, entity) in entities {
            self.emit_update_record(TABLE, entity_id, entity.serialize_all());
        }
    }

    fn emit_member<T, +Serde<T>>(
        ref self: TState, member_id: felt252, entity_id: felt252, entity: @T,
    ) {
        self.emit_update_member(TABLE, member_id, entity_id, entity.serialize_all());
    }

    fn emit_models_member<T, +Serde<T>>(
        ref self: TState, member_id: felt252, entities: Array<(felt252, @T)>,
    ) {
        for (entity_id, entity) in entities {
            self.emit_update_member(TABLE, member_id, entity_id, entity.serialize_all());
        }
    }

    fn emit_schema<S, +Schema<S>>(ref self: TState, entity_id: felt252, schema: @S) {
        for (member, value) in schema.serialize_values_and_members() {
            self.emit_update_member(TABLE, member, entity_id, value);
        }
    }

    fn emit_schemas<S, +Schema<S>>(ref self: TState, schemas: Array<(felt252, @S)>) {
        for (entity_id, schema) in schemas {
            Self::emit_schema(ref self, entity_id, schema)
        }
    }
}
