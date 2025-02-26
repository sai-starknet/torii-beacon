use starknet::ClassHash;
use dojo_beacon::{
    utils::serde::serialize_inline,
    resource_component::{HasComponent, ResourceRegister, BeaconEvents},
};

pub trait MicroEmitter<TState> {
    fn register_namespace(ref self: TState, namespace: ByteArray, hash: felt252);

    fn register_model(
        ref self: TState, namespace: ByteArray, namespace_hash: felt252, class_hash: ClassHash,
    );

    fn register_namespaces(ref self: TState, namespaces: Array<(ByteArray, felt252)>);

    fn register_models(ref self: TState, models: Array<(ByteArray, felt252, ClassHash)>);

    fn register_namespace_and_models(
        ref self: TState, namespace: ByteArray, namespace_hash: felt252, models: Array<ClassHash>,
    );

    fn set_record<K, T, +Serde<K>, +Serde<T>>(
        ref self: TState, selector: felt252, entity_id: felt252, keys: @K, values: @T,
    );

    fn update_record<T, +Serde<T>>(
        ref self: TState, selector: felt252, entity_id: felt252, values: @T,
    );

    fn update_member<T, +Serde<T>>(
        ref self: TState,
        selector: felt252,
        entity_id: felt252,
        member_selector: felt252,
        values: @T,
    );
}


pub impl MicroEmitterImpl<
    TState, impl Resource: HasComponent<TState>, +Drop<TState>,
> of MicroEmitter<TState> {
    fn register_namespace(ref self: TState, namespace: ByteArray, hash: felt252) {
        let mut resource = self.get_component_mut();
        resource.set_new_namespace(namespace, hash);
    }

    fn register_model(
        ref self: TState, namespace: ByteArray, namespace_hash: felt252, class_hash: ClassHash,
    ) {
        let mut resource = self.get_component_mut();
        resource.set_new_model(namespace, namespace_hash, class_hash);
    }

    fn register_namespaces(ref self: TState, namespaces: Array<(ByteArray, felt252)>) {
        let mut resource = self.get_component_mut();
        for (namespace, hash) in namespaces {
            resource.set_new_namespace(namespace, hash);
        }
    }

    fn register_models(ref self: TState, models: Array<(ByteArray, felt252, ClassHash)>) {
        let mut resource = self.get_component_mut();
        for (namespace, namespace_hash, class_hash) in models {
            resource.set_new_model(namespace, namespace_hash, class_hash);
        }
    }
    fn register_namespace_and_models(
        ref self: TState, namespace: ByteArray, namespace_hash: felt252, models: Array<ClassHash>,
    ) {
        let mut resource = self.get_component_mut();
        let s_namespace = @namespace;
        resource.set_new_namespace(namespace, namespace_hash);
        for class_hash in models {
            resource.set_new_model(s_namespace.clone(), namespace_hash, class_hash);
        }
    }

    fn set_record<K, T, +Serde<K>, +Serde<T>>(
        ref self: TState, selector: felt252, entity_id: felt252, keys: @K, values: @T,
    ) {
        let mut resource = self.get_component_mut();
        resource
            .emit_set_record(
                selector, entity_id, serialize_inline(keys).span(), serialize_inline(values).span(),
            );
    }

    fn update_record<T, +Serde<T>>(
        ref self: TState, selector: felt252, entity_id: felt252, values: @T,
    ) {
        let mut resource = self.get_component_mut();
        resource.emit_update_record(selector, entity_id, serialize_inline(values).span());
    }

    fn update_member<T, +Serde<T>>(
        ref self: TState,
        selector: felt252,
        entity_id: felt252,
        member_selector: felt252,
        values: @T,
    ) {
        let mut resource = self.get_component_mut();
        resource
            .emit_update_member(
                selector, entity_id, member_selector, serialize_inline(values).span(),
            );
    }
}
