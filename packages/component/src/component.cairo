use dojo::meta::{Introspect, Ty};
use sai_address::calculate_utc_zero_address;
use starknet::ClassHash;

#[generate_trait]
pub impl ToriiRegistryEmitterImpl<
    TState, +emitter_component::HasComponent<TState>, +Drop<TState>,
> of ToriiRegistryEmitter<TState> {
    fn emit_register_entity(
        ref self: TState, namespace: ByteArray, name: ByteArray, class_hash: ClassHash,
    ) {
        self
            .emit_model_registered(
                namespace, name, calculate_utc_zero_address(class_hash, [].span()), class_hash,
            );
    }

    fn emit_register_entity_with_schema<E, +Introspect<E>>(
        ref self: TState, namespace: ByteArray, name: ByteArray,
    ) {
        let schema = if let Ty::Struct(s) = Introspect::<E>::ty() {
            s
        } else {
            panic!("Expected a struct type for schema")
        };
        self.emit_model_with_schema_registered(name, namespace, schema);
    }
}
use emitter_component::ToriiEventEmitter;

#[starknet::component]
pub mod emitter_component {
    use dojo::meta::introspect::Struct;
    use starknet::{ClassHash, ContractAddress};
    use crate::events::{
        ModelRegistered, ModelWithSchemaRegistered, StoreDelRecord, StoreSetRecord,
        StoreUpdateMember, StoreUpdateRecord,
    };

    #[storage]
    pub struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ModelRegistered: ModelRegistered,
        ModelWithSchemaRegistered: ModelWithSchemaRegistered,
        StoreSetRecord: StoreSetRecord,
        StoreUpdateRecord: StoreUpdateRecord,
        StoreUpdateMember: StoreUpdateMember,
        StoreDelRecord: StoreDelRecord,
    }

    pub trait ToriiEventEmitter<TState> {
        fn emit_model_registered(
            ref self: TState,
            name: ByteArray,
            namespace: ByteArray,
            address: ContractAddress,
            class_hash: ClassHash,
        );
        fn emit_model_with_schema_registered(
            ref self: TState, name: ByteArray, namespace: ByteArray, schema: Struct,
        );
        fn emit_set_record(
            ref self: TState,
            selector: felt252,
            entity_id: felt252,
            keys: Span<felt252>,
            values: Span<felt252>,
        );
        fn emit_update_record(
            ref self: TState, selector: felt252, entity_id: felt252, values: Span<felt252>,
        );
        fn emit_update_member(
            ref self: TState,
            selector: felt252,
            entity_id: felt252,
            member_selector: felt252,
            values: Span<felt252>,
        );
        fn emit_delete_record(ref self: TState, selector: felt252, entity_id: felt252);
    }

    pub impl ToriiEventEmitterComponent<
        TContractState, +HasComponent<TContractState>,
    > of ToriiEventEmitter<ComponentState<TContractState>> {
        fn emit_model_registered(
            ref self: ComponentState<TContractState>,
            name: ByteArray,
            namespace: ByteArray,
            address: ContractAddress,
            class_hash: ClassHash,
        ) {
            self.emit(ModelRegistered { name, namespace, address, class_hash });
        }

        fn emit_model_with_schema_registered(
            ref self: ComponentState<TContractState>,
            name: ByteArray,
            namespace: ByteArray,
            schema: Struct,
        ) {
            self.emit(ModelWithSchemaRegistered { name, namespace, schema });
        }

        fn emit_set_record(
            ref self: ComponentState<TContractState>,
            selector: felt252,
            entity_id: felt252,
            keys: Span<felt252>,
            values: Span<felt252>,
        ) {
            self.emit(StoreSetRecord { entity_id, selector, keys, values });
        }

        fn emit_update_record(
            ref self: ComponentState<TContractState>,
            selector: felt252,
            entity_id: felt252,
            values: Span<felt252>,
        ) {
            self.emit(StoreUpdateRecord { selector, entity_id, values });
        }

        fn emit_update_member(
            ref self: ComponentState<TContractState>,
            selector: felt252,
            entity_id: felt252,
            member_selector: felt252,
            values: Span<felt252>,
        ) {
            self.emit(StoreUpdateMember { selector, entity_id, member_selector, values });
        }

        fn emit_delete_record(
            ref self: ComponentState<TContractState>, selector: felt252, entity_id: felt252,
        ) {
            self.emit(StoreDelRecord { selector, entity_id });
        }
    }


    pub impl ToriiEventEmitterContract<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>,
    > of ToriiEventEmitter<TContractState> {
        fn emit_model_registered(
            ref self: TContractState,
            name: ByteArray,
            namespace: ByteArray,
            address: ContractAddress,
            class_hash: ClassHash,
        ) {
            let mut contract = self.get_component_mut();
            contract.emit(ModelRegistered { name, namespace, address, class_hash });
        }

        fn emit_model_with_schema_registered(
            ref self: TContractState, name: ByteArray, namespace: ByteArray, schema: Struct,
        ) {
            let mut contract = self.get_component_mut();
            contract.emit(ModelWithSchemaRegistered { name, namespace, schema });
        }
        fn emit_set_record(
            ref self: TContractState,
            selector: felt252,
            entity_id: felt252,
            keys: Span<felt252>,
            values: Span<felt252>,
        ) {
            let mut contract = self.get_component_mut();
            contract.emit(StoreSetRecord { entity_id, selector, keys, values });
        }

        fn emit_update_record(
            ref self: TContractState, selector: felt252, entity_id: felt252, values: Span<felt252>,
        ) {
            let mut contract = self.get_component_mut();
            contract.emit(StoreUpdateRecord { selector, entity_id, values });
        }

        fn emit_update_member(
            ref self: TContractState,
            selector: felt252,
            entity_id: felt252,
            member_selector: felt252,
            values: Span<felt252>,
        ) {
            let mut contract = self.get_component_mut();
            contract.emit(StoreUpdateMember { selector, entity_id, member_selector, values });
        }

        fn emit_delete_record(ref self: TContractState, selector: felt252, entity_id: felt252) {
            let mut contract = self.get_component_mut();
            contract.emit(StoreDelRecord { selector, entity_id });
        }
    }
}
