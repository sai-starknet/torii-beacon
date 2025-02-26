use starknet::ClassHash;
use dojo::world::Resource;


#[starknet::interface]
pub trait IBeaconRegister<T> {
    /// Returns the resource from its selector.
    ///
    /// # Arguments
    ///   * `selector` - the resource selector
    ///
    /// # Returns
    ///   * `Resource` - the resource data associated with the selector.
    fn resource(self: @T, selector: felt252) -> Resource;

    /// Registers a namespace in the world.
    ///
    /// # Arguments
    ///
    /// * `namespace` - The name of the namespace to be registered.
    fn register_namespace(ref self: T, namespace: ByteArray);

    /// Registers a model in the world.
    ///
    /// # Arguments
    ///
    /// * `namespace` - The namespace of the model to be registered.
    /// * `class_hash` - The class hash of the model to be registered.
    fn register_model(ref self: T, namespace: ByteArray, class_hash: ClassHash);
}

#[starknet::interface]
pub trait IBeaconResource<T> {
    /// Returns the resource from its selector.
    ///
    /// # Arguments
    ///   * `selector` - the resource selector
    ///
    /// # Returns
    ///   * `Resource` - the resource data associated with the selector.
    fn resource(self: @T, selector: felt252) -> Resource;
}


#[starknet::component]
pub mod resource_component {
    use core::poseidon::poseidon_hash_span;
    use core::num::traits::Zero;

    use starknet::{get_caller_address, ClassHash, ContractAddress};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

    use dojo::world::world::{
        NamespaceRegistered, ModelRegistered, StoreSetRecord, StoreUpdateRecord, StoreUpdateMember,
    };
    use dojo::utils::bytearray_hash;

    use dojo_beacon::{
        owners_component, owners_component::OwnersInternal, errors, writers_component,
        writers_component::WritersInternal,
        resource::model::{calculate_model_contract_address, get_model_name},
    };
    use dojo_beacon::resource::{Resource, DojoResource};
    use super::{IBeaconRegister, IBeaconResource};

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        NamespaceRegistered: NamespaceRegistered,
        ModelRegistered: ModelRegistered,
        StoreSetRecord: StoreSetRecord,
        StoreUpdateRecord: StoreUpdateRecord,
        StoreUpdateMember: StoreUpdateMember,
    }

    #[storage]
    pub struct Storage {
        models_salt: felt252,
        resource_types: Map::<felt252, Resource>,
        model_hashes: Map::<felt252, felt252>,
        model_namespace_hashes: Map::<felt252, felt252>,
        model_contract_addresses: Map::<felt252, ContractAddress>,
        namespace_names: Map::<felt252, ByteArray>,
    }

    /// Asserts the name is valid according to the naming convention.
    fn assert_name(name: @ByteArray) {
        if !dojo::utils::is_name_valid(name) {
            errors::invalid_naming("Name", name);
        }
    }

    /// Asserts the namespace is valid according to the naming convention.
    fn assert_namespace(namespace: @ByteArray) {
        if !dojo::utils::is_name_valid(namespace) {
            errors::invalid_naming("Namespace", namespace);
        }
    }

    #[embeddable_as(BeaconResource)]
    impl IBeaconResourceImpl<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>,
    > of IBeaconResource<ComponentState<TContractState>> {
        fn resource(self: @ComponentState<TContractState>, selector: felt252) -> DojoResource {
            self.get_resource(selector)
        }
    }

    #[embeddable_as(BeaconRegister)]
    impl IBeaconRegisterImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Owners: owners_component::HasComponent<TContractState>,
    > of IBeaconRegister<ComponentState<TContractState>> {
        fn resource(self: @ComponentState<TContractState>, selector: felt252) -> DojoResource {
            self.get_resource(selector)
        }
        fn register_namespace(ref self: ComponentState<TContractState>, namespace: ByteArray) {
            assert_namespace(@namespace);
            get_dep_component!(@self, Owners).assert_caller_is_contract_owner();

            let selector = bytearray_hash(@namespace);
            match self.resource_type(selector) {
                Resource::Namespace => errors::namespace_already_registered(@namespace),
                Resource::Unregistered => { self.set_new_namespace(namespace, selector); },
                _ => errors::resource_conflict(@namespace, @"namespace"),
            };
        }

        fn register_model(
            ref self: ComponentState<TContractState>, namespace: ByteArray, class_hash: ClassHash,
        ) {
            let namespace_hash = bytearray_hash(@namespace);

            match self.resource_type(namespace_hash) {
                Resource::Namespace => {},
                Resource::Unregistered => errors::namespace_not_registered(@namespace),
                _ => errors::resource_conflict(@namespace, @"namespace"),
            }
            let caller = get_caller_address();
            if !get_dep_component!(@self, Owners)
                .is_namespace_or_contract_owner(namespace_hash, caller) {
                errors::not_namespace_or_contract_owner(caller, namespace);
            }

            self.set_new_model(namespace, namespace_hash, class_hash);
        }
    }


    #[generate_trait]
    pub impl BeaconEventsImpl<
        TContractState, +HasComponent<TContractState>,
    > of BeaconEvents<TContractState> {
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
    }

    #[generate_trait]
    pub impl ResourceRegisterImpl<
        TContractState, +HasComponent<TContractState>,
    > of ResourceRegister<TContractState> {
        fn set_new_namespace(
            ref self: ComponentState<TContractState>, namespace: ByteArray, hash: felt252,
        ) {
            self.namespace_names.write(hash, namespace.clone());
            self.resource_types.write(hash, Resource::Namespace);
            self.emit_namespace_registered(namespace, hash)
        }

        fn set_new_model(
            ref self: ComponentState<TContractState>,
            namespace: ByteArray,
            namespace_hash: felt252,
            class_hash: ClassHash,
        ) {
            let contract_address = calculate_model_contract_address(class_hash);

            let model_name = get_model_name(contract_address);
            let model_hash = bytearray_hash(@model_name);

            let selector = poseidon_hash_span([namespace_hash, model_hash].span());
            self.model_hashes.write(selector, model_hash);
            self.model_namespace_hashes.write(selector, namespace_hash);
            self.model_contract_addresses.write(selector, contract_address);
            self.resource_types.write(selector, Resource::Model);
            self.emit_model_registered(model_name, namespace, contract_address, class_hash);
        }
    }

    #[generate_trait]
    pub impl ResourceInternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of ResourceInternal<TContractState> {
        fn get_resource(self: @ComponentState<TContractState>, selector: felt252) -> DojoResource {
            match self.resource_type(selector) {
                Resource::Model => DojoResource::Model(
                    (self.model_contract_address(selector), self.model_namespace_hash(selector)),
                ),
                Resource::Namespace => DojoResource::Namespace(self.namespace_name(selector)),
                Resource::World => DojoResource::World,
                Resource::Unregistered => DojoResource::Unregistered,
                _ => errors::resource_conflict(@format!("{selector}"), @"Resource"),
            }
        }

        fn resource_type(self: @ComponentState<TContractState>, selector: felt252) -> Resource {
            self.resource_types.read(selector)
        }

        fn model_name(self: @ComponentState<TContractState>, selector: felt252) -> ByteArray {
            get_model_name(self.model_contract_address(selector))
        }

        fn model_namespace_hash(
            self: @ComponentState<TContractState>, selector: felt252,
        ) -> felt252 {
            self.model_namespace_hashes.read(selector)
        }

        fn model_namespace_hash_nz(
            self: @ComponentState<TContractState>, selector: felt252,
        ) -> felt252 {
            let namespace_hash = self.model_namespace_hashes.read(selector);
            if namespace_hash.is_non_zero() {
                errors::model_not_registered(@self.model_name(selector))
            } else {
                namespace_hash
            }
        }

        fn model_contract_address(
            self: @ComponentState<TContractState>, selector: felt252,
        ) -> ContractAddress {
            self.model_contract_addresses.read(selector)
        }

        fn set_model_contract_address(
            ref self: ComponentState<TContractState>, selector: felt252, address: ContractAddress,
        ) {
            self.model_contract_addresses.write(selector, address);
        }

        fn namespace_name(self: @ComponentState<TContractState>, selector: felt252) -> ByteArray {
            self.namespace_names.read(selector)
        }
    }

    #[generate_trait]
    pub impl ResourceWriterImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Writers: writers_component::HasComponent<TContractState>,
    > of ResourceWriter<TContractState> {
        fn is_model_writer_from_selector(
            self: @ComponentState<TContractState>, selector: felt252, user: ContractAddress,
        ) -> bool {
            let namespace_hash = self.model_namespace_hash_nz(selector);

            let writers = get_dep_component!(self, Writers);
            writers.model_writer_from_selector(selector, user)
                || writers.is_namespace_or_contract_writer(namespace_hash, user)
        }

        fn assert_is_model_writer_from_selector(
            self: @ComponentState<TContractState>, selector: felt252, user: ContractAddress,
        ) {
            if !self.is_model_writer_from_selector(selector, user) {
                errors::not_model_writer(user, selector);
            }
        }

        fn assert_caller_is_model_writer_from_selector(
            self: @ComponentState<TContractState>, selector: felt252,
        ) {
            self.assert_is_model_writer_from_selector(selector, get_caller_address());
        }
    }
}
