use beacon_schema::Schema;
use sai_core_utils::SerdeAll;
use crate::{HasEmitterComponent, ToriiEventEmitter};


/// Trait defining methods for emitting events to Torii indexer without requiring a full Dojo world.
///
/// This emitter allows direct interaction with Torii by emitting structured data events:
/// - table_id: Identifier for the table/model
/// - entity_id: Identifier for the row
/// - Data can be: entity (full row), member (single cell), or schema (multiple cells)
///
/// The table_id must be a hash of the model name and namespace.
pub trait Torii<TState> {
    /// Emits an event for a single entity (full row of data)
    /// * Args:
    ///     * `table_id` - Identifier for the table/model
    ///     * `entity_id` - Identifier for the row
    ///     * `entity` - A complete row of data to emit
    ///
    fn set_entity<I, E, +Into<I, felt252>, +Serde<E>>(
        ref self: TState, table_id: felt252, entity_id: I, entity: @E,
    );

    /// Emits events for multiple entities (full rows of data)
    /// * Args:
    ///     * `table_id` - Identifier for the table/model
    ///     * `entities` - Array of complete rows of data to emit
    fn set_entities<I, E, +Into<I, felt252>, +Drop<I>, +Serde<E>>(
        ref self: TState, table_id: felt252, entities: Array<(I, @E)>,
    );

    /// Emits an event for a single member (single cell of data)
    /// * Args:
    ///     * `table_id` - Identifier for the table/model
    ///     * `member_id` - Identifier for the specific field/column
    ///     * `entity_id` - Identifier for the row
    ///     * `entity` - A single cell of data to emit
    fn set_member<I, T, +Into<I, felt252>, +Serde<T>>(
        ref self: TState, table_id: felt252, member_id: felt252, entity_id: I, entity: @T,
    );

    /// Emits events for multiple members (single cells of data)
    /// * Args:
    ///     * `table_id` - Identifier for the table/model
    ///     * `member_id` - Identifier for the specific field/column
    ///     * `entities` - Array of single cells of data to emit
    fn set_models_member<I, T, +Into<I, felt252>, +Drop<I>, +Serde<T>>(
        ref self: TState, table_id: felt252, member_id: felt252, entities: Array<(I, @T)>,
    );

    /// Emits an event for a single schema (multiple cells of data)
    /// * Args:
    ///     * `table_id` - Identifier for the table/model
    ///     * `entity_id` - Identifier for the row
    ///     * `schema` - Multiple cells of data to emit as schema
    fn set_schema<I, S, +Into<I, felt252>, +Schema<S>>(
        ref self: TState, table_id: felt252, entity_id: I, schema: @S,
    );

    /// Emits events for multiple schemas (multiple cells of data)
    /// * Args:
    ///     * `table_id` - Identifier for the table/model
    ///     * `schemas` - Array of schema data with multiple cells to emit
    fn set_schemas<I, S, +Into<I, felt252>, +Drop<I>, +Schema<S>>(
        ref self: TState, table_id: felt252, schemas: Array<(I, @S)>,
    );

    /// Emits an event to delete an entity
    /// * Args:
    ///     * `table_id` - Identifier for the table/model
    ///     * `entity_id` - Identifier for the row to delete
    fn delete_entity<I, +Into<I, felt252>>(ref self: TState, table_id: felt252, entity_id: I);
    /// Emits events to delete multiple entities
    /// * Args:
    ///     * `table_id` - Identifier for the table/model
    ///     * `entity_ids` - Array of identifiers for the rows to delete
    fn delete_entities<I, +Into<I, felt252>, +Drop<I>>(
        ref self: TState, table_id: felt252, entity_ids: Array<I>,
    );
}

impl DatabaseImpl<TState, +HasEmitterComponent<TState>, +Drop<TState>> of Torii<TState> {
    fn set_entity<I, E, +Into<I, felt252>, +Serde<E>>(
        ref self: TState, table_id: felt252, entity_id: I, entity: @E,
    ) {
        self.emit_update_record(table_id, entity_id.into(), entity.serialize_all());
    }

    fn set_entities<I, E, +Into<I, felt252>, +Drop<I>, +Serde<E>>(
        ref self: TState, table_id: felt252, entities: Array<(I, @E)>,
    ) {
        for (entity_id, entity) in entities {
            self.set_entity(table_id, entity_id, entity);
        }
    }

    fn set_member<I, T, +Into<I, felt252>, +Serde<T>>(
        ref self: TState, table_id: felt252, member_id: felt252, entity_id: I, entity: @T,
    ) {
        self.emit_update_member(table_id, entity_id.into(), member_id, entity.serialize_all());
    }

    fn set_models_member<I, T, +Into<I, felt252>, +Drop<I>, +Serde<T>>(
        ref self: TState, table_id: felt252, member_id: felt252, entities: Array<(I, @T)>,
    ) {
        for (entity_id, entity) in entities {
            self.set_member(table_id, member_id, entity_id, entity);
        }
    }

    fn set_schema<I, S, +Into<I, felt252>, +Schema<S>>(
        ref self: TState, table_id: felt252, entity_id: I, schema: @S,
    ) {
        let id = entity_id.into();
        for (member, value) in schema.serialize_values_and_members() {
            self.emit_update_member(table_id, member, id, value);
        }
    }

    fn set_schemas<I, S, +Into<I, felt252>, +Drop<I>, +Schema<S>>(
        ref self: TState, table_id: felt252, schemas: Array<(I, @S)>,
    ) {
        for (entity_id, schema) in schemas {
            self.set_schema(table_id, entity_id, schema);
        }
    }

    fn delete_entity<I, +Into<I, felt252>>(ref self: TState, table_id: felt252, entity_id: I) {
        self.emit_delete_record(table_id, entity_id.into());
    }

    fn delete_entities<I, +Into<I, felt252>, +Drop<I>>(
        ref self: TState, table_id: felt252, entity_ids: Array<I>,
    ) {
        for entity_id in entity_ids {
            self.delete_entity(table_id, entity_id);
        }
    }
}
