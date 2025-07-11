use starknet::ContractAddress;
pub use writers_component::{
    BeaconWriters, HasComponent as HasWritersComponent, ComponentState as WritersState,
};

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

    use crate::owners::{OwnersInternal, HasOwnersComponent};
    use crate::errors;

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
        +HasOwnersComponent<TContractState>,
        +Drop<TContractState>,
    > of IBeaconWriters<ComponentState<TContractState>> {
        fn is_contract_writer(
            self: @ComponentState<TContractState>, user: ContractAddress,
        ) -> bool {
            self.contract_writer(user)
        }

        fn grant_contract_writer(ref self: ComponentState<TContractState>, user: ContractAddress) {
            self.get_contract().assert_caller_is_contract_owner();
            self.set_contract_writer(user, true);
        }

        fn revoke_contract_writer(ref self: ComponentState<TContractState>, user: ContractAddress) {
            self.get_contract().assert_caller_is_contract_owner();
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
            self.get_contract().assert_caller_is_namespace_or_contract_owner(namespace);
            self.set_namespace_writer(namespace, user, true);
        }

        fn revoke_namespace_writer(
            ref self: ComponentState<TContractState>, namespace: felt252, user: ContractAddress,
        ) {
            self.get_contract().assert_caller_is_namespace_or_contract_owner(namespace);
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
            self
                .get_contract()
                .assert_caller_is_model_namespace_or_contract_owner(namespace, model);
            self.model_writers.write((namespace, user), true);
        }

        fn revoke_model_writer(
            ref self: ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
        ) {
            self
                .get_contract()
                .assert_caller_is_model_namespace_or_contract_owner(namespace, model);
            self.model_writers.write((namespace, user), false);
        }
    }


    pub trait WritersInternal<TState> {
        fn set_contract_writer(ref self: TState, user: ContractAddress, value: bool);

        fn contract_writer(self: @TState, user: ContractAddress) -> bool;

        fn assert_is_contract_writer(
            self: @TState, user: ContractAddress,
        ) {
            if !Self::contract_writer(self, user) {
                errors::not_contract_writer(user);
            }
        }

        fn assert_caller_is_contract_writer(
            self: @TState,
        ) {
            Self::assert_is_contract_writer(self, get_caller_address());
        }

        fn set_namespace_writer(
            ref self: TState, namespace: felt252, user: ContractAddress, value: bool,
        );

        fn namespace_writer(self: @TState, namespace: felt252, user: ContractAddress) -> bool;

        fn is_namespace_or_contract_writer(
            self: @TState, namespace: felt252, user: ContractAddress,
        ) -> bool {
            Self::namespace_writer(self, namespace, user) || Self::contract_writer(self, user)
        }

        fn is_caller_namespace_or_contract_writer(
            self: @TState, namespace: felt252,
        ) -> bool {
            Self::is_namespace_or_contract_writer(self, namespace, get_caller_address())
        }

        fn assert_is_namespace_or_contract_writer(
            self: @TState, namespace: felt252, user: ContractAddress,
        ) {
            if !Self::is_namespace_or_contract_writer(self, namespace, user) {
                errors::not_namespace_or_contract_writer(user, namespace);
            }
        }

        fn assert_caller_is_namespace_or_contract_writer(
            self: @TState, namespace: felt252,
        ) {
            Self::assert_is_namespace_or_contract_writer(self, namespace, get_caller_address());
        }

        fn set_model_writer(
            ref self: TState,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
            value: bool,
        );

        fn set_model_writer_from_selector(
            ref self: TState, selector: felt252, user: ContractAddress, value: bool,
        );

        fn model_writer(
            self: @TState, namespace: felt252, model: felt252, user: ContractAddress,
        ) -> bool;

        fn model_writer_from_selector(
            self: @TState, selector: felt252, user: ContractAddress,
        ) -> bool;

        fn is_model_namespace_or_contract_writer(
            self: @TState, namespace: felt252, model: felt252, user: ContractAddress,
        ) -> bool {
            Self::model_writer(self, namespace, model, user)
                || Self::is_namespace_or_contract_writer(self, namespace, user)
        }

        fn assert_is_model_namespace_or_contract_writer(
            self: @TState, namespace: felt252, model: felt252, user: ContractAddress,
        ) {
            if !Self::is_model_namespace_or_contract_writer(self, namespace, model, user) {
                errors::not_model_namespace_or_contract_writer(user, namespace, model);
            }
        }

        fn assert_caller_is_model_namespace_or_contract_writer(
            self: @TState, namespace: felt252, model: felt252,
        ) {
            Self::assert_is_model_namespace_or_contract_writer(
                self, namespace, model, get_caller_address(),
            );
        }
    }


    pub impl WritersComponentInternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of WritersInternal<ComponentState<TContractState>> {
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
    }

    pub impl WritersContractInternalImpl<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>,
    > of WritersInternal<TContractState> {
        fn set_contract_writer(ref self: TContractState, user: ContractAddress, value: bool) {
            let mut writers: ComponentState<TContractState> = self.get_component_mut();
            writers.set_contract_writer(user, value);
        }

        fn contract_writer(self: @TContractState, user: ContractAddress) -> bool {
            HasComponent::get_component(self).contract_writer(user)
        }

        fn set_namespace_writer(
            ref self: TContractState, namespace: felt252, user: ContractAddress, value: bool,
        ) {
            let mut writers: ComponentState<TContractState> = self.get_component_mut();
            writers.set_namespace_writer(namespace, user, value);
        }

        fn namespace_writer(
            self: @TContractState, namespace: felt252, user: ContractAddress,
        ) -> bool {
            HasComponent::get_component(self).namespace_writer(namespace, user)
        }


        fn set_model_writer(
            ref self: TContractState,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
            value: bool,
        ) {
            let mut writers: ComponentState<TContractState> = self.get_component_mut();
            writers.set_model_writer(namespace, model, user, value);
        }

        fn set_model_writer_from_selector(
            ref self: TContractState, selector: felt252, user: ContractAddress, value: bool,
        ) {
            let mut writers: ComponentState<TContractState> = self.get_component_mut();
            writers.set_model_writer_from_selector(selector, user, value);
        }

        fn model_writer(
            self: @TContractState, namespace: felt252, model: felt252, user: ContractAddress,
        ) -> bool {
            HasComponent::get_component(self).model_writer(namespace, model, user)
        }

        fn model_writer_from_selector(
            self: @TContractState, selector: felt252, user: ContractAddress,
        ) -> bool {
            HasComponent::get_component(self).model_writer_from_selector(selector, user)
        }
    }
}
