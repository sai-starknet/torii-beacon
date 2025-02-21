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
    use starknet::{ClassHash, ContractAddress, SyscallResultTrait};
    use starknet::syscalls::deploy_syscall;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };

    use dojo::world::{Resource, ResourceIsNoneTrait};
    use dojo::world::world::{
        NamespaceRegistered, ModelRegistered, StoreSetRecord, StoreUpdateRecord, StoreUpdateMember,
    };
    use dojo::meta::{IDeployedResourceDispatcher, IDeployedResourceDispatcherTrait};
    use dojo::utils::{bytearray_hash, selector_from_namespace_and_name};

    use dojo_beacon::{
        owners_component, owners_component::OwnersInternal, errors, writers_component,
        writers_component::WritersInternal,
    };
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
        resources: Map::<felt252, Resource>,
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
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Owners: owners_component::HasComponent<TContractState>,
    > of IBeaconResource<ComponentState<TContractState>> {
        fn resource(self: @ComponentState<TContractState>, selector: felt252) -> Resource {
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
        fn resource(self: @ComponentState<TContractState>, selector: felt252) -> Resource {
            self.get_resource(selector)
        }

        fn register_namespace(ref self: ComponentState<TContractState>, namespace: ByteArray) {
            assert_namespace(@namespace);
            let owners = get_dep_component!(@self, Owners);
            owners.assert_caller_is_contract_owner();

            let hash = bytearray_hash(@namespace);

            match self.resources.read(hash) {
                Resource::Namespace => errors::namespace_already_registered(@namespace),
                Resource::Unregistered => {
                    self.resources.write(hash, Resource::Namespace(namespace.clone()));
                    self.emit_namespace_registered(namespace, hash);
                },
                _ => errors::resource_conflict(@namespace, @"namespace"),
            };
        }

        fn register_model(
            ref self: ComponentState<TContractState>, namespace: ByteArray, class_hash: ClassHash,
        ) {
            let owners = get_dep_component!(@self, Owners);
            let namespace_hash = bytearray_hash(@namespace);
            owners.assert_caller_is_namespace_or_contract_owner(namespace_hash);

            let salt = self.models_salt.read();
            self.models_salt.write(salt + 1);

            let (contract_address, _) = deploy_syscall(class_hash, salt, [].span(), false)
                .unwrap_syscall();

            let model = IDeployedResourceDispatcher { contract_address };
            let model_name = model.dojo_name();

            assert_name(@model_name);

            let model_selector = selector_from_namespace_and_name(namespace_hash, @model_name);

            match self.resources.read(namespace_hash) {
                Resource::Namespace(name) => { name },
                _ => errors::namespace_not_registered(@namespace),
            }

            let maybe_existing_model = self.resources.read(model_selector);
            if !maybe_existing_model.is_unregistered() {
                errors::model_already_registered(@namespace, @model_name);
            }

            self
                .resources
                .write(model_selector, Resource::Model((contract_address, namespace_hash)));
            self.emit_model_registered(model_name, namespace, contract_address, class_hash);
        }
    }


    #[generate_trait]
    pub impl ResourceInternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of ResourceInternal<TContractState> {
        fn get_resource(self: @ComponentState<TContractState>, selector: felt252) -> Resource {
            self.resources.read(selector)
        }

        fn register_model(
            ref self: ComponentState<TContractState>,
            namespace: ByteArray,
            namespace_hash: felt252,
            model_name: ByteArray,
        ) {
            assert_name(@model_name);
            let model_selector = selector_from_namespace_and_name(namespace_hash, @model_name);
            match self.resources.read(namespace_hash) {
                Resource::Namespace(name) => { name },
                _ => errors::namespace_not_registered(@namespace),
            };
            let maybe_existing_model = self.resources.read(model_selector);
            if !maybe_existing_model.is_unregistered() {
                errors::model_already_registered(@namespace, @model_name);
            }
            // self
        //     .resources
        //     .write(model_selector, Resource::Model((contract_address, namespace_hash)));
        // self.emit_model_registered(model_name, namespace, contract_address, class_hash);
        }

        fn assert_namespace_registered(
            ref self: ComponentState<TContractState>, namespace: ByteArray,
        ) {
            let hash = bytearray_hash(@namespace);
            match self.resources.read(hash) {
                Resource::Namespace => {},
                _ => errors::namespace_not_registered(@namespace),
            }
        }

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
    impl ResourceWriterImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Writers: writers_component::HasComponent<TContractState>,
    > of ResourceWriter<TContractState> {
        fn is_model_writer(
            self: @ComponentState<TContractState>, selector: felt252, user: ContractAddress,
        ) -> bool {
            let namespace_hash = self.get_model_namespace_hash(selector);

            let writers = get_dep_component!(self, Writers);
            writers.model_writer_from_selector(selector, user)
                || writers.is_namespace_or_contract_writer(namespace_hash, user)
        }

        fn assert_is_model_writer(
            self: @ComponentState<TContractState>, selector: felt252, user: ContractAddress,
        ) {
            if !self.is_model_writer(selector, user) {
                errors::not_model_writer(user, selector);
            }
        }

        fn get_model_namespace_hash(
            self: @ComponentState<TContractState>, selector: felt252,
        ) -> felt252 {
            match self.get_resource(selector) {
                Resource::Model((_, namespace_hash)) => namespace_hash,
                Resource::Unregistered => errors::model_not_registered(@format!("{selector}")),
                _ => errors::resource_conflict(@format!("{selector}"), @"Model"),
            }
        }
    }
}
