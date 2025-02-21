use starknet::ContractAddress;

#[starknet::interface]
pub trait IBeaconWriters<T> {
    fn is_contract_writer(self: @T, user: ContractAddress) -> bool;

    fn grant_contract_writer(ref self: T, user: ContractAddress);

    fn revoke_contract_writer(ref self: T, user: ContractAddress);

    fn is_namespace_writer(self: @T, namespace: felt252, user: ContractAddress) -> bool;

    fn grant_namespace_writer(ref self: T, namespace: felt252, user: ContractAddress);

    fn revoke_namespace_writer(ref self: T, namespace: felt252, user: ContractAddress);

    fn is_model_writer(self: @T, namespace: felt252, model: felt252, user: ContractAddress) -> bool;

    fn grant_model_writer(ref self: T, namespace: felt252, model: felt252, user: ContractAddress);

    fn revoke_model_writer(ref self: T, namespace: felt252, model: felt252, user: ContractAddress);
}

#[starknet::component]
pub mod writers_component {
    use core::poseidon::poseidon_hash_span;
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

    use dojo_beacon::{owners_component, owners_component::OwnersInternal, errors};

    use super::IBeaconWriters;

    #[storage]
    pub struct Storage {
        contract_writers: Map::<ContractAddress, bool>,
        namespace_writers: Map::<(felt252, ContractAddress), bool>,
        model_writers: Map::<(felt252, ContractAddress), bool>,
    }

    #[embeddable_as(BeaconWriters)]
    impl IBeaconWritersImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl Owners: owners_component::HasComponent<TContractState>,
    > of IBeaconWriters<ComponentState<TContractState>> {
        fn is_contract_writer(
            self: @ComponentState<TContractState>, user: ContractAddress,
        ) -> bool {
            self.contract_writer(user)
        }

        fn grant_contract_writer(ref self: ComponentState<TContractState>, user: ContractAddress) {
            get_dep_component!(@self, Owners).assert_caller_is_contract_owner();
            self.set_contract_writer(user, true);
        }

        fn revoke_contract_writer(ref self: ComponentState<TContractState>, user: ContractAddress) {
            get_dep_component!(@self, Owners).assert_caller_is_contract_owner();
            self.set_contract_writer(user, false);
        }

        fn is_namespace_writer(
            self: @ComponentState<TContractState>, namespace: felt252, user: ContractAddress,
        ) -> bool {
            self.namespace_writer(namespace, user)
        }

        fn grant_namespace_writer(
            ref self: ComponentState<TContractState>, namespace: felt252, user: ContractAddress,
        ) {
            get_dep_component!(@self, Owners)
                .assert_caller_is_namespace_or_contract_owner(namespace);
            self.set_namespace_writer(namespace, user, true);
        }

        fn revoke_namespace_writer(
            ref self: ComponentState<TContractState>, namespace: felt252, user: ContractAddress,
        ) {
            get_dep_component!(@self, Owners)
                .assert_caller_is_namespace_or_contract_owner(namespace);
            self.set_namespace_writer(namespace, user, false);
        }

        fn is_model_writer(
            self: @ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
        ) -> bool {
            self.model_writer(namespace, model, user)
        }

        fn grant_model_writer(
            ref self: ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
        ) {
            get_dep_component!(@self, Owners)
                .assert_caller_is_model_namespace_or_contract_owner(namespace, model);
            self.model_writers.write((namespace, user), true);
        }

        fn revoke_model_writer(
            ref self: ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
        ) {
            get_dep_component!(@self, Owners)
                .assert_caller_is_model_namespace_or_contract_owner(namespace, model);
            self.model_writers.write((namespace, user), false);
        }
    }

    #[generate_trait]
    pub impl WritersInternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of WritersInternal<TContractState> {
        fn set_contract_writer(
            ref self: ComponentState<TContractState>, user: ContractAddress, value: bool,
        ) {
            self.contract_writers.write(user, value);
        }

        fn contract_writer(self: @ComponentState<TContractState>, user: ContractAddress) -> bool {
            self.contract_writers.read(user)
        }

        fn set_namespace_writer(
            ref self: ComponentState<TContractState>,
            namespace: felt252,
            user: ContractAddress,
            value: bool,
        ) {
            self.namespace_writers.write((namespace, user), value);
        }

        fn namespace_writer(
            self: @ComponentState<TContractState>, namespace: felt252, user: ContractAddress,
        ) -> bool {
            self.namespace_writers.read((namespace, user))
        }

        fn is_namespace_or_contract_writer(
            self: @ComponentState<TContractState>, namespace: felt252, user: ContractAddress,
        ) -> bool {
            self.namespace_writer(namespace, user) || self.contract_writer(user)
        }

        fn set_model_writer(
            ref self: ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
            value: bool,
        ) {
            self.model_writers.write((poseidon_hash_span([namespace, model].span()), user), value);
        }

        fn set_model_writer_from_selector(
            ref self: ComponentState<TContractState>,
            selector: felt252,
            user: ContractAddress,
            value: bool,
        ) {
            self.model_writers.write((selector, user), value);
        }

        fn model_writer(
            self: @ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
        ) -> bool {
            self.model_writers.read((poseidon_hash_span([namespace, model].span()), user))
        }

        fn model_writer_from_selector(
            self: @ComponentState<TContractState>, selector: felt252, user: ContractAddress,
        ) -> bool {
            self.model_writers.read((selector, user))
        }

        fn is_model_namespace_or_contract_writer(
            self: @ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
        ) -> bool {
            self.model_writer(namespace, model, user)
                || self.is_namespace_or_contract_writer(namespace, user)
        }

        fn assert_is_model_namespace_or_contract_writer(
            self: @ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
        ) {
            if !self.is_model_namespace_or_contract_writer(namespace, model, user) {
                errors::not_namespace_or_contract_writer(user, namespace);
            }
        }

        fn assert_caller_is_model_namespace_or_contract_writer(
            self: @ComponentState<TContractState>, namespace: felt252, model: felt252,
        ) {
            if !self.is_model_namespace_or_contract_writer(namespace, model, get_caller_address()) {
                errors::not_namespace_or_contract_writer(get_caller_address(), namespace);
            }
        }
    }
}
