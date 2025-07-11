#[starknet::component]
pub mod registry_component {
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

    #[storage]
    pub struct Storage {
        name_hashes: Map::<felt252, felt252>,
        namespace_hashes: Map::<felt252, felt252>,
    }

    pub trait RegistryTrait<TState> {
        fn register_model(
            ref self: TState, selector: felt252, name_hash: felt252, namespace_hash: felt252,
        );
        fn read_model_name_hash(self: @TState, selector: felt252) -> felt252;
        fn read_model_namespace_hash(self: @TState, selector: felt252) -> felt252;
        fn read_model_hashes(self: @TState, selector: felt252) -> (felt252, felt252);
    }

    impl RegistryComponentImpl<
        ContractState, +HasComponent<ContractState>,
    > of RegistryTrait<ComponentState<ContractState>> {
        fn register_model(
            ref self: ComponentState<ContractState>,
            selector: felt252,
            name_hash: felt252,
            namespace_hash: felt252,
        ) {
            self.name_hashes.write(selector, name_hash);
            self.namespace_hashes.write(selector, namespace_hash);
        }

        fn read_model_name_hash(
            self: @ComponentState<ContractState>, selector: felt252,
        ) -> felt252 {
            self.name_hashes.read(selector)
        }

        fn read_model_namespace_hash(
            self: @ComponentState<ContractState>, selector: felt252,
        ) -> felt252 {
            self.namespace_hashes.read(selector)
        }

        fn read_model_hashes(
            self: @ComponentState<ContractState>, selector: felt252,
        ) -> (felt252, felt252) {
            (self.name_hashes.read(selector), self.namespace_hashes.read(selector))
        }
    }

    impl RegistryStateImpl<
        ContractState, +HasComponent<ContractState>, +Drop<ContractState>,
    > of RegistryTrait<ContractState> {
        fn register_model(
            ref self: ContractState, selector: felt252, name_hash: felt252, namespace_hash: felt252,
        ) {
            let mut registry: ComponentState<ContractState> = self.get_component_mut();
            registry.register_model(selector, name_hash, namespace_hash);
        }

        fn read_model_name_hash(self: @ContractState, selector: felt252) -> felt252 {
            self.get_component().read_model_name_hash(selector)
        }

        fn read_model_namespace_hash(self: @ContractState, selector: felt252) -> felt252 {
            self.get_component().read_model_namespace_hash(selector)
        }

        fn read_model_hashes(self: @ContractState, selector: felt252) -> (felt252, felt252) {
            self.get_component().read_model_hashes(selector)
        }
    }
}
