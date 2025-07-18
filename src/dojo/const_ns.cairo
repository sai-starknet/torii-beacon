use crate::emitter::{DojoEventEmitter, EmitterState, HasEmitterComponent};
use dojo::model::Model;
use sai_core_utils::SerdeAll;
use super::traits::BeaconEmitterTrait;

pub impl ConstNsBeaconEmitter<
    const NAMESPACE_HASH: felt252, TState, impl Emitter: HasEmitterComponent<TState>, +Drop<TState>,
> of BeaconEmitterTrait<TState> {
    fn emit_model<M, +Model<M>>(ref self: TState, model: @M) {
        let mut emitter: EmitterState = self.get_component_mut();
        emitter
            .emit_set_record(
                Model::<M>::selector(NAMESPACE_HASH),
                model.entity_id(),
                model.serialized_keys(),
                model.serialized_values(),
            );
    }

    fn emit_models<M, +Model<M>>(ref self: TState, models: Span<M>) {
        let mut emitter: EmitterState = self.get_component_mut();
        let selector = Model::<M>::selector(NAMESPACE_HASH);
        for model in models {
            emitter
                .emit_set_record(
                    selector, model.entity_id(), model.serialized_keys(), model.serialized_values(),
                );
        }
    }
    fn emit_entity<M, T, +Model<M>, +Serde<T>>(ref self: TState, entity_id: felt252, entity: @T) {
        let mut emitter: EmitterState = self.get_component_mut();
        emitter
            .emit_update_record(
                Model::<M>::selector(NAMESPACE_HASH), entity_id, entity.serialize_all(),
            );
    }
    fn emit_entities<M, T, +Model<M>, +Serde<T>>(ref self: TState, entities: Array<(felt252, @T)>) {
        let mut emitter: EmitterState = self.get_component_mut();
        let selector = Model::<M>::selector(NAMESPACE_HASH);
        for (entity_id, entity) in entities {
            emitter.emit_update_record(selector, entity_id, entity.serialize_all());
        }
    }
    fn emit_member<M, T, +Model<M>, +Serde<T>>(
        ref self: TState, entity_id: felt252, member_selector: felt252, member: @T,
    ) {
        let mut emitter: EmitterState = self.get_component_mut();
        emitter
            .emit_update_member(
                Model::<M>::selector(NAMESPACE_HASH),
                entity_id,
                member_selector,
                member.serialize_all(),
            );
    }
    fn emit_members<M, T, +Model<M>, +Serde<T>>(
        ref self: TState, member_selector: felt252, members: Array<(felt252, @T)>,
    ) {
        let mut emitter: EmitterState = self.get_component_mut();
        let selector = Model::<M>::selector(NAMESPACE_HASH);
        for (entity_id, member) in members {
            emitter
                .emit_update_member(selector, entity_id, member_selector, member.serialize_all());
        }
    }
    fn emit_model_members<M, T, +Model<M>, +Serde<T>>(
        ref self: TState, entity_id: felt252, members: Array<(felt252, @T)>,
    ) {
        let mut emitter: EmitterState = self.get_component_mut();
        let selector = Model::<M>::selector(NAMESPACE_HASH);
        for (member_selector, member) in members {
            emitter
                .emit_update_member(selector, entity_id, member_selector, member.serialize_all());
        }
    }
    fn emit_delete_model<M, +Model<M>>(ref self: TState, entity_id: felt252) {
        let mut emitter: EmitterState = self.get_component_mut();
        emitter.emit_delete_record(Model::<M>::selector(NAMESPACE_HASH), entity_id);
    }
}

