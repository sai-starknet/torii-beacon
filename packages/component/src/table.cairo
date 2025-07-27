use beacon_schema::Schema;
use crate::{HasEmitterComponent, Torii};
pub mod traits {
    use super::Schema;
    /// Trait defining methods for emitting events to Torii indexer without requiring a full Dojo
    /// world.
    /// This version uses a constant TABLE parameter for compile-time table specification.
    ///
    /// This emitter allows direct interaction with Torii by emitting structured data events:
    /// - TABLE: Compile-time constant identifier for the table/model
    /// - entity_id: Identifier for the row
    /// - Data can be: entity (full row), member (single cell), or schema (multiple cells)
    pub trait ToriiTableTrait<TState> {
        /// Emits an event for a single entity (full row of data)
        /// * Args:
        ///     * `entity_id` - Identifier for the row
        ///     * `entity` - A complete row of data to emit
        fn set_entity<I, E, +Into<I, felt252>, +Serde<E>>(
            ref self: TState, entity_id: I, entity: @E,
        );

        /// Emits events for multiple entities (full rows of data)
        /// * Args:
        ///     * `entities` - Array of complete rows of data to emit
        fn set_entities<I, E, +Into<I, felt252>, +Drop<I>, +Serde<E>>(
            ref self: TState, entities: Array<(I, @E)>,
        );

        /// Emits an event for a single member (single cell of data)
        /// * Args:
        ///     * `member_id` - Identifier for the specific field/column
        ///     * `entity_id` - Identifier for the row
        ///     * `entity` - A single cell of data to emit
        fn set_member<I, T, +Into<I, felt252>, +Serde<T>>(
            ref self: TState, member_id: felt252, entity_id: I, entity: @T,
        );

        /// Emits events for multiple members (single cells of data)
        /// * Args:
        ///     * `member_id` - Identifier for the specific field/column
        ///     * `entities` - Array of single cells of data to emit
        fn set_models_member<I, T, +Into<I, felt252>, +Drop<I>, +Serde<T>>(
            ref self: TState, member_id: felt252, entities: Array<(I, @T)>,
        );

        /// Emits an event for a single schema (multiple cells of data)
        /// * Args:
        ///     * `entity_id` - Identifier for the row
        ///     * `schema` - Multiple cells of data to emit as schema
        fn set_schema<I, S, +Into<I, felt252>, +Schema<S>>(
            ref self: TState, entity_id: I, schema: @S,
        );

        /// Emits events for multiple schemas (multiple cells of data)
        /// * Args:
        ///     * `schemas` - Array of schema data with multiple cells to emit
        fn set_schemas<I, S, +Into<I, felt252>, +Drop<I>, +Schema<S>>(
            ref self: TState, schemas: Array<(I, @S)>,
        );

        /// Emits an event to delete an entity
        /// * Args:
        ///     * `entity_id` - Identifier for the row to delete
        fn delete_entity<I, +Into<I, felt252>>(ref self: TState, entity_id: I);

        /// Emits events to delete multiple entities
        /// * Args:
        ///     * `entity_ids` - Array of identifiers for the rows to delete
        fn delete_entities<I, +Into<I, felt252>, +Drop<I>>(ref self: TState, entity_ids: Array<I>);
    }
}


pub impl ToriiTable<
    const TABLE: felt252, TState, +HasEmitterComponent<TState>, +Drop<TState>,
> of traits::ToriiTableTrait<TState> {
    fn set_entity<I, E, +Into<I, felt252>, +Serde<E>>(ref self: TState, entity_id: I, entity: @E) {
        Torii::set_entity(ref self, TABLE, entity_id, entity);
    }

    fn set_entities<I, E, +Into<I, felt252>, +Drop<I>, +Serde<E>>(
        ref self: TState, entities: Array<(I, @E)>,
    ) {
        Torii::set_entities(ref self, TABLE, entities);
    }

    fn set_member<I, T, +Into<I, felt252>, +Serde<T>>(
        ref self: TState, member_id: felt252, entity_id: I, entity: @T,
    ) {
        Torii::set_member(ref self, TABLE, member_id, entity_id, entity);
    }

    fn set_models_member<I, T, +Into<I, felt252>, +Drop<I>, +Serde<T>>(
        ref self: TState, member_id: felt252, entities: Array<(I, @T)>,
    ) {
        Torii::set_models_member(ref self, TABLE, member_id, entities);
    }

    fn set_schema<I, S, +Into<I, felt252>, +Schema<S>>(ref self: TState, entity_id: I, schema: @S) {
        Torii::set_schema(ref self, TABLE, entity_id, schema);
    }

    fn set_schemas<I, S, +Into<I, felt252>, +Drop<I>, +Schema<S>>(
        ref self: TState, schemas: Array<(I, @S)>,
    ) {
        Torii::set_schemas(ref self, TABLE, schemas);
    }

    fn delete_entity<I, +Into<I, felt252>>(ref self: TState, entity_id: I) {
        Torii::delete_entity(ref self, TABLE, entity_id);
    }

    fn delete_entities<I, +Into<I, felt252>, +Drop<I>>(ref self: TState, entity_ids: Array<I>) {
        Torii::delete_entities(ref self, TABLE, entity_ids);
    }
}
