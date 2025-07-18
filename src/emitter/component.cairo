#[starknet::component]
pub mod emitter_component {
    use dojo::world::world::{
        ModelRegistered, NamespaceRegistered, StoreDelRecord, StoreSetRecord, StoreUpdateMember,
        StoreUpdateRecord,
    };
    use starknet::{ClassHash, ContractAddress};

    #[storage]
    pub struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        NamespaceRegistered: NamespaceRegistered,
        ModelRegistered: ModelRegistered,
        StoreSetRecord: StoreSetRecord,
        StoreUpdateRecord: StoreUpdateRecord,
        StoreUpdateMember: StoreUpdateMember,
        StoreDelRecord: StoreDelRecord,
    }


    #[generate_trait]
    pub impl DojoEventEmitterImpl<
        TContractState, +HasComponent<TContractState>,
    > of DojoEventEmitter<TContractState> {
        fn emit_namespace_registered(
            ref self: ComponentState<TContractState>, namespace: ByteArray, hash: felt252,
        ) {
            self.emit(NamespaceRegistered { namespace, hash });
        }

        fn emit_model_registered(
            ref self: ComponentState<TContractState>,
            name: ByteArray,
            namespace: ByteArray,
            address: ContractAddress,
            class_hash: ClassHash,
        ) {
            self.emit(ModelRegistered { name, namespace, address, class_hash });
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
}
