use starknet::ClassHash;
use dojo::model::Model;
use dojo::utils::serialize_inline;
use crate::{
    resource_component::{BeaconEvents, BeaconEventsImpl, ResourceRegister, ResourceRegisterImpl},
    resource_component,
};


pub impl BeaconEmitter<
    const NAMESPACE_HASH: felt252,
    TState,
    impl Resource: resource_component::HasComponent<TState>,
    +Drop<TState>,
    +BeaconEvents<TState>,
    +ResourceRegister<TState>,
> of super::traits::BeaconEmitterTrait<TState> {
    fn register_namespace(ref self: TState, namespace: ByteArray) {
        let mut resource = self.get_component_mut();
        ResourceRegisterImpl::set_new_namespace(ref resource, namespace, NAMESPACE_HASH);
    }

    fn register_model(ref self: TState, namespace: ByteArray, class_hash: ClassHash) {
        let mut resource = self.get_component_mut();
        ResourceRegisterImpl::set_new_model(ref resource, namespace, NAMESPACE_HASH, class_hash);
    }

    fn emit_model<M, +Model<M>>(ref self: TState, model: @M) {
        let mut resource = self.get_component_mut();

        BeaconEventsImpl::emit_set_record(
            ref resource,
            Model::<M>::selector(NAMESPACE_HASH),
            model.entity_id(),
            model.serialized_keys(),
            model.serialized_values(),
        );
    }
    fn emit_models<M, +Model<M>>(ref self: TState, models: Span<M>) {
        let mut resource = self.get_component_mut();
        let selector = Model::<M>::selector(NAMESPACE_HASH);
        for model in models {
            BeaconEventsImpl::emit_set_record(
                ref resource,
                selector,
                model.entity_id(),
                model.serialized_keys(),
                model.serialized_values(),
            );
        }
    }
    fn emit_entity<M, T, +Model<M>, +Serde<T>>(ref self: TState, entity_id: felt252, entity: @T) {
        let mut resource = self.get_component_mut();
        BeaconEventsImpl::emit_update_record(
            ref resource, Model::<M>::selector(NAMESPACE_HASH), entity_id, serialize_inline(entity),
        );
    }
    fn emit_entities<M, T, +Model<M>, +Serde<T>>(ref self: TState, entities: Array<(felt252, @T)>) {
        let mut resource = self.get_component_mut();
        let selector = Model::<M>::selector(NAMESPACE_HASH);
        for (entity_id, entity) in entities {
            BeaconEventsImpl::emit_update_record(
                ref resource, selector, entity_id, serialize_inline(entity),
            );
        };
    }

    fn emit_member<M, T, +Model<M>, +Serde<T>>(
        ref self: TState, entity_id: felt252, member_selector: felt252, member: @T,
    ) {
        let mut resource = self.get_component_mut();
        BeaconEventsImpl::emit_update_member(
            ref resource,
            Model::<M>::selector(NAMESPACE_HASH),
            entity_id,
            member_selector,
            serialize_inline(member),
        );
    }

    fn emit_members<M, T, +Model<M>, +Serde<T>>(
        ref self: TState, entity_id: felt252, members: Array<(felt252, @T)>,
    ) {
        let mut resource = self.get_component_mut();
        let selector = Model::<M>::selector(NAMESPACE_HASH);
        for (member_selector, member) in members {
            BeaconEventsImpl::emit_update_member(
                ref resource, selector, entity_id, member_selector, serialize_inline(member),
            );
        }
    }
}

