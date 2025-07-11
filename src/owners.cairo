use starknet::ContractAddress;
pub use owners_component::{
    BeaconOwners, HasComponent as HasOwnersComponent, OwnersInternal, ComponentState as OwnersState,
};

#[starknet::interface]
pub trait IBeaconOwners<T> {
    fn is_contract_owner(self: @T, user: ContractAddress) -> bool;

    fn grant_contract_owner(ref self: T, user: ContractAddress);

    fn revoke_contract_owner(ref self: T, user: ContractAddress);

    fn is_namespace_owner(self: @T, namespace: felt252, user: ContractAddress) -> bool;

    fn grant_namespace_owner(ref self: T, namespace: felt252, user: ContractAddress);

    fn revoke_namespace_owner(ref self: T, namespace: felt252, user: ContractAddress);

    fn is_model_owner(self: @T, namespace: felt252, model: felt252, user: ContractAddress) -> bool;

    fn grant_model_owner(ref self: T, namespace: felt252, model: felt252, user: ContractAddress);

    fn revoke_model_owner(ref self: T, namespace: felt252, model: felt252, user: ContractAddress);
}


#[starknet::component]
pub mod owners_component {
    use core::poseidon::poseidon_hash_span;
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

    use dojo_beacon::errors;

    use super::IBeaconOwners;

    #[storage]
    pub struct Storage {
        contract_owners: Map::<ContractAddress, bool>,
        namespace_owners: Map::<(felt252, ContractAddress), bool>,
        model_owners: Map::<(felt252, ContractAddress), bool>,
    }

    #[embeddable_as(BeaconOwners)]
    impl IBeaconOwnersImpl<
        TContractState, +HasComponent<TContractState>,
    > of IBeaconOwners<ComponentState<TContractState>> {
        fn is_contract_owner(self: @ComponentState<TContractState>, user: ContractAddress) -> bool {
            self.contract_owner(user)
        }

        fn grant_contract_owner(ref self: ComponentState<TContractState>, user: ContractAddress) {
            self.assert_caller_is_contract_owner();
            self.set_contract_owner(user, true);
        }

        fn revoke_contract_owner(ref self: ComponentState<TContractState>, user: ContractAddress) {
            self.assert_caller_is_contract_owner();
            self.set_contract_owner(user, false);
        }

        fn is_namespace_owner(
            self: @ComponentState<TContractState>, namespace: felt252, user: ContractAddress,
        ) -> bool {
            self.namespace_owner(namespace, user)
        }

        fn grant_namespace_owner(
            ref self: ComponentState<TContractState>, namespace: felt252, user: ContractAddress,
        ) {
            self.assert_caller_is_namespace_or_contract_owner(namespace);
            self.set_namespace_owner(namespace, user, true);
        }

        fn revoke_namespace_owner(
            ref self: ComponentState<TContractState>, namespace: felt252, user: ContractAddress,
        ) {
            self.assert_caller_is_namespace_or_contract_owner(namespace);
            self.set_namespace_owner(namespace, user, false);
        }

        fn is_model_owner(
            self: @ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
        ) -> bool {
            self.namespace_owner(namespace, user)
        }

        fn grant_model_owner(
            ref self: ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
        ) {
            self.assert_caller_is_model_namespace_or_contract_owner(namespace, model);
            self.set_namespace_owner(namespace, user, true);
        }

        fn revoke_model_owner(
            ref self: ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
        ) {
            self.assert_caller_is_model_namespace_or_contract_owner(namespace, model);
            self.set_namespace_owner(namespace, user, false);
        }
    }

    pub trait OwnersInternal<TState> {
        fn set_contract_owner(ref self: TState, user: ContractAddress, value: bool);

        fn contract_owner(self: @TState, user: ContractAddress) -> bool;

        fn assert_is_contract_owner(
            self: @TState, user: ContractAddress,
        ) {
            if !Self::contract_owner(self, user) {
                errors::not_contract_owner(user);
            }
        }

        fn assert_caller_is_contract_owner(
            self: @TState,
        ) {
            Self::assert_is_contract_owner(self, get_caller_address());
        }

        fn set_namespace_owner(
            ref self: TState, namespace: felt252, user: ContractAddress, value: bool,
        );

        fn namespace_owner(self: @TState, namespace: felt252, user: ContractAddress) -> bool;

        fn is_namespace_or_contract_owner(
            self: @TState, namespace: felt252, user: ContractAddress,
        ) -> bool {
            Self::namespace_owner(self, namespace, user) || Self::contract_owner(self, user)
        }

        fn is_caller_namespace_or_contract_owner(
            self: @TState, namespace: felt252,
        ) -> bool {
            Self::is_namespace_or_contract_owner(self, namespace, get_caller_address())
        }

        fn assert_is_namespace_or_contract_owner(
            self: @TState, namespace: felt252, user: ContractAddress,
        ) {
            if !Self::is_namespace_or_contract_owner(self, namespace, user) {
                errors::not_namespace_hash_or_contract_owner(user, namespace);
            }
        }

        fn assert_caller_is_namespace_or_contract_owner(
            self: @TState, namespace: felt252,
        ) {
            Self::assert_is_namespace_or_contract_owner(self, namespace, get_caller_address());
        }

        fn set_model_owner(
            ref self: TState,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
            value: bool,
        );

        fn set_model_owner_from_selector(
            ref self: TState, selector: felt252, user: ContractAddress, value: bool,
        );

        fn model_owner(
            self: @TState, namespace: felt252, model: felt252, user: ContractAddress,
        ) -> bool;

        fn model_owner_from_selector(
            self: @TState, selector: felt252, user: ContractAddress,
        ) -> bool;

        fn is_model_namespace_or_contract_owner(
            self: @TState, namespace: felt252, model: felt252, user: ContractAddress,
        ) -> bool {
            Self::model_owner(self, namespace, model, user)
                || Self::is_namespace_or_contract_owner(self, namespace, user)
        }

        fn assert_is_model_namespace_or_contract_owner(
            self: @TState, namespace: felt252, model: felt252, user: ContractAddress,
        ) {
            if !Self::is_model_namespace_or_contract_owner(self, namespace, model, user) {
                errors::not_namespace_hash_or_contract_owner(user, namespace);
            }
        }

        fn assert_caller_is_model_namespace_or_contract_owner(
            self: @TState, namespace: felt252, model: felt252,
        ) {
            Self::assert_is_model_namespace_or_contract_owner(
                self, namespace, model, get_caller_address(),
            );
        }
    }


    pub impl OwnersComponentInternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of OwnersInternal<ComponentState<TContractState>> {
        fn set_contract_owner(
            ref self: ComponentState<TContractState>, user: ContractAddress, value: bool,
        ) {
            self.contract_owners.write(user, value);
        }

        fn contract_owner(self: @ComponentState<TContractState>, user: ContractAddress) -> bool {
            self.contract_owners.read(user)
        }

        fn set_namespace_owner(
            ref self: ComponentState<TContractState>,
            namespace: felt252,
            user: ContractAddress,
            value: bool,
        ) {
            self.namespace_owners.write((namespace, user), value);
        }

        fn namespace_owner(
            self: @ComponentState<TContractState>, namespace: felt252, user: ContractAddress,
        ) -> bool {
            self.namespace_owners.read((namespace, user))
        }


        fn set_model_owner(
            ref self: ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
            value: bool,
        ) {
            self.model_owners.write((poseidon_hash_span([namespace, model].span()), user), value);
        }

        fn set_model_owner_from_selector(
            ref self: ComponentState<TContractState>,
            selector: felt252,
            user: ContractAddress,
            value: bool,
        ) {
            self.model_owners.write((selector, user), value);
        }

        fn model_owner(
            self: @ComponentState<TContractState>,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
        ) -> bool {
            self.model_owners.read((poseidon_hash_span([namespace, model].span()), user))
        }

        fn model_owner_from_selector(
            self: @ComponentState<TContractState>, selector: felt252, user: ContractAddress,
        ) -> bool {
            self.model_owners.read((selector, user))
        }
    }

    pub impl OwnersContractInternalImpl<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>,
    > of OwnersInternal<TContractState> {
        fn set_contract_owner(ref self: TContractState, user: ContractAddress, value: bool) {
            let mut owners: ComponentState<TContractState> = self.get_component_mut();
            owners.set_contract_owner(user, value);
        }

        fn contract_owner(self: @TContractState, user: ContractAddress) -> bool {
            HasComponent::get_component(self).contract_owner(user)
        }

        fn set_namespace_owner(
            ref self: TContractState, namespace: felt252, user: ContractAddress, value: bool,
        ) {
            let mut owners: ComponentState<TContractState> = self.get_component_mut();
            owners.set_namespace_owner(namespace, user, value);
        }

        fn namespace_owner(
            self: @TContractState, namespace: felt252, user: ContractAddress,
        ) -> bool {
            HasComponent::get_component(self).namespace_owner(namespace, user)
        }


        fn set_model_owner(
            ref self: TContractState,
            namespace: felt252,
            model: felt252,
            user: ContractAddress,
            value: bool,
        ) {
            let mut owners: ComponentState<TContractState> = self.get_component_mut();
            owners.set_model_owner(namespace, model, user, value);
        }

        fn set_model_owner_from_selector(
            ref self: TContractState, selector: felt252, user: ContractAddress, value: bool,
        ) {
            let mut owners: ComponentState<TContractState> = self.get_component_mut();
            owners.set_model_owner_from_selector(selector, user, value);
        }

        fn model_owner(
            self: @TContractState, namespace: felt252, model: felt252, user: ContractAddress,
        ) -> bool {
            HasComponent::get_component(self).model_owner(namespace, model, user)
        }

        fn model_owner_from_selector(
            self: @TContractState, selector: felt252, user: ContractAddress,
        ) -> bool {
            HasComponent::get_component(self).model_owner_from_selector(selector, user)
        }
    }
}
