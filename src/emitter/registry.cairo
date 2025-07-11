use starknet::ClassHash;
use dojo::utils::bytearray_hash;
use crate::emitter::{DojoEventEmitter, HasEmitterComponent, EmitterState};
use crate::model::{calculate_model_contract_address, get_model_name};

pub trait Registry<TState> {
    fn register_namespace(ref self: TState, namespace: ByteArray);
    fn register_model(ref self: TState, namespace: ByteArray, class_hash: ClassHash);
}


pub impl RegistryImpl<
    TState, impl Resource: HasEmitterComponent<TState>, +Drop<TState>,
> of Registry<TState> {
    fn register_namespace(ref self: TState, namespace: ByteArray) {
        let mut emitter: EmitterState = self.get_component_mut();
        let hash = bytearray_hash(@namespace);
        emitter.emit_namespace_registered(namespace, hash);
    }

    fn register_model(ref self: TState, namespace: ByteArray, class_hash: ClassHash) {
        let mut emitter: EmitterState = self.get_component_mut();
        let contract_address = calculate_model_contract_address(class_hash);
        let name = get_model_name(contract_address);
        emitter.emit_model_registered(name, namespace, contract_address, class_hash);
    }
}
