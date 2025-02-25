use starknet::{ContractAddress, ClassHash};
use dojo_beacon::resource_component::{BeaconEventsImpl, HasComponent};

#[generate_trait]
pub impl BeaconEmitterImpl<
    TState, impl Resource: HasComponent<TState>, +Drop<TState>,
> of BeaconEmitter<TState> {
    fn emit_namespace_registered(ref self: TState, namespace: ByteArray, hash: felt252) {
        let mut resource = self.get_component_mut();
        BeaconEventsImpl::emit_namespace_registered(ref resource, namespace, hash);
    }

    fn emit_model_registered(
        ref self: TState,
        name: ByteArray,
        namespace: ByteArray,
        address: ContractAddress,
        class_hash: ClassHash,
    ) {
        let mut resource = self.get_component_mut();
        BeaconEventsImpl::emit_model_registered(ref resource, name, namespace, address, class_hash);
    }
    fn emit_set_record(
        ref self: TState,
        selector: felt252,
        entity_id: felt252,
        keys: Span<felt252>,
        values: Span<felt252>,
    ) {
        let mut resource = self.get_component_mut();
        BeaconEventsImpl::emit_set_record(ref resource, selector, entity_id, keys, values);
    }

    fn emit_update_record(
        ref self: TState, selector: felt252, entity_id: felt252, values: Span<felt252>,
    ) {
        let mut resource = self.get_component_mut();
        BeaconEventsImpl::emit_update_record(ref resource, selector, entity_id, values);
    }

    fn emit_update_member(
        ref self: TState,
        selector: felt252,
        entity_id: felt252,
        member_selector: felt252,
        values: Span<felt252>,
    ) {
        let mut resource = self.get_component_mut();
        BeaconEventsImpl::emit_update_member(
            ref resource, selector, entity_id, member_selector, values,
        );
    }
}
