use beacon_schema::Schema;
use super::torii::{
    delete_entities, delete_entity, set_entities, set_entity, set_member, set_models_member,
    set_schema, set_schemas,
};

/// Trait defining methods for emitting events to Torii indexer without requiring a full Dojo
/// world.
/// This version uses a constant TABLE parameter for compile-time table specification.
///
/// This emitter allows direct interaction with Torii by emitting structured data events:
/// - TABLE: Compile-time constant identifier for the table/model
/// - entity_id: Identifier for the row
/// - Data can be: entity (full row), member (single cell), or schema (multiple cells)
trait ToriiTableTrait {
    /// Emits an event for a single entity (full row of data)
    /// * Args:
    ///     * `entity_id` - Identifier for the row
    ///     * `entity` - A complete row of data to emit
    fn set_entity<I, E, +Drop<I>, +Into<I, felt252>, +Serde<E>>(entity_id: I, entity: @E);

    /// Emits events for multiple entities (full rows of data)
    /// * Args:
    ///     * `entities` - Array of complete rows of data to emit
    fn set_entities<I, E, +Drop<I>, +Into<I, felt252>, +Serde<E>>(entities: Array<(I, @E)>);

    /// Emits an event for a single member (single cell of data)
    /// * Args:
    ///     * `member_id` - Identifier for the specific field/column
    ///     * `entity_id` - Identifier for the row
    ///     * `entity` - A single cell of data to emit
    fn set_member<const MEMBER_ID: felt252, I, T, +Drop<I>, +Into<I, felt252>, +Serde<T>>(
        entity_id: I, entity: @T,
    );

    /// Emits events for multiple members (single cells of data)
    /// * Args:
    ///     * `member_id` - Identifier for the specific field/column
    ///     * `entities` - Array of single cells of data to emit
    fn set_models_member<const MEMBER_ID: felt252, I, T, +Drop<I>, +Into<I, felt252>, +Serde<T>>(
        entities: Array<(I, @T)>,
    );

    /// Emits an event for a single schema (multiple cells of data)
    /// * Args:
    ///     * `entity_id` - Identifier for the row
    ///     * `schema` - Multiple cells of data to emit as schema
    fn set_schema<I, S, +Drop<I>, +Into<I, felt252>, +Schema<S>>(entity_id: I, schema: @S);

    /// Emits events for multiple schemas (multiple cells of data)
    /// * Args:
    ///     * `schemas` - Array of schema data with multiple cells to emit
    fn set_schemas<I, S, +Drop<I>, +Into<I, felt252>, +Schema<S>>(schemas: Array<(I, @S)>);
    /// Emits an event to delete an entity
    /// * Args:
    ///     * `entity_id` - Identifier for the row to delete
    fn delete_entity<I, +Into<I, felt252>>(entity_id: I);

    /// Emits events to delete multiple entities
    /// * Args:
    ///     * `entity_ids` - Array of identifiers for the rows to delete
    fn delete_entities<I, +Into<I, felt252>, +Drop<I>>(entity_ids: Array<I>);
}

pub impl ToriiTable<const TABLE: felt252> of ToriiTableTrait {
    fn set_entity<I, E, +Drop<I>, +Into<I, felt252>, +Serde<E>>(entity_id: I, entity: @E) {
        set_entity(TABLE, entity_id, entity);
    }

    fn set_entities<I, E, +Drop<I>, +Into<I, felt252>, +Serde<E>>(entities: Array<(I, @E)>) {
        set_entities(TABLE, entities);
    }

    fn set_member<const MEMBER_ID: felt252, I, T, +Drop<I>, +Into<I, felt252>, +Serde<T>>(
        entity_id: I, entity: @T,
    ) {
        set_member::<MEMBER_ID>(TABLE, entity_id, entity);
    }

    fn set_models_member<const MEMBER_ID: felt252, I, T, +Drop<I>, +Into<I, felt252>, +Serde<T>>(
        entities: Array<(I, @T)>,
    ) {
        set_models_member::<MEMBER_ID>(TABLE, entities);
    }

    fn set_schema<I, S, +Drop<I>, +Into<I, felt252>, +Schema<S>>(entity_id: I, schema: @S) {
        set_schema(TABLE, entity_id, schema);
    }

    fn set_schemas<I, S, +Drop<I>, +Into<I, felt252>, +Schema<S>>(schemas: Array<(I, @S)>) {
        set_schemas(TABLE, schemas);
    }

    fn delete_entity<I, +Into<I, felt252>>(entity_id: I) {
        delete_entity(TABLE, entity_id);
    }

    fn delete_entities<I, +Into<I, felt252>, +Drop<I>>(entity_ids: Array<I>) {
        delete_entities(TABLE, entity_ids);
    }
}
