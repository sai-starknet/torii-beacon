#[starknet::contract]
mod beacon {
    use dojo_beacon::beacon::{IBeacon, IdKeysValues, IdValues, IdValuesArray};
    use dojo_beacon::{owners_component, registry_component, writers_component};
    use owners_component::OwnersInternal;
    use writers_component::WritersInternal;

    component!(path: registry_component, storage: registry, event: RegistryEvents);
    component!(path: owners_component, storage: owners, event: OwnersEvents);
    component!(path: writers_component, storage: writers, event: WritersEvents);


    #[storage]
    struct Storage {
        #[substorage(v0)]
        owners: owners_component::Storage,
        #[substorage(v0)]
        writers: writers_component::Storage,
        #[substorage(v0)]
        registry: registry_component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnersEvents: owners_component::Event,
        #[flat]
        WritersEvents: writers_component::Event,
        #[flat]
        RegistryEvents: registry_component::Event,
    }


    #[abi(embed_v0)]
    impl IOwners = owners_component::BeaconOwners<ContractState>;

    #[abi(embed_v0)]
    impl IWriters = writers_component::BeaconWriters<ContractState>;

    #[abi(embed_v0)]
    impl IBeaconImpl of IBeacon<ContractState> {
        fn set_model(
            ref self: ContractState,
            selector: felt252,
            entity_id: felt252,
            keys: Span<felt252>,
            values: Span<felt252>,
        ) {
            self.resource.assert_caller_is_model_writer_from_selector(selector);
            self.resource.emit_set_record(selector, entity_id, keys, values);
        }

        fn set_models(ref self: ContractState, selector: felt252, models: Array<IdKeysValues>) {
            self.resource.assert_caller_is_model_writer_from_selector(selector);
            for model in models {
                self.resource.emit_set_record(selector, model.id, model.keys, model.values);
            }
        }

        fn update_model(
            ref self: ContractState, selector: felt252, entity_id: felt252, values: Span<felt252>,
        ) {
            self.resource.assert_caller_is_model_writer_from_selector(selector);
            self.resource.emit_update_record(selector, entity_id, values);
        }

        fn update_models(ref self: ContractState, selector: felt252, models: Array<IdValues>) {
            self.resource.assert_caller_is_model_writer_from_selector(selector);
            for model in models {
                self.resource.emit_update_record(selector, model.id, model.values);
            }
        }

        fn update_member(
            ref self: ContractState,
            selector: felt252,
            entity_id: felt252,
            member_selector: felt252,
            values: Span<felt252>,
        ) {
            self.resource.assert_caller_is_model_writer_from_selector(selector);
            self.resource.emit_update_member(selector, entity_id, member_selector, values);
        }

        fn update_members(
            ref self: ContractState,
            selector: felt252,
            entity_id: felt252,
            members: Array<IdValues>,
        ) {
            self.resource.assert_caller_is_model_writer_from_selector(selector);
            for member in members {
                self.resource.emit_update_member(selector, entity_id, member.id, member.values);
            }
        }

        fn update_models_member(
            ref self: ContractState,
            selector: felt252,
            member_selector: felt252,
            models: Array<IdValues>,
        ) {
            self.resource.assert_caller_is_model_writer_from_selector(selector);
            for model in models {
                self.resource.emit_update_member(selector, model.id, member_selector, model.values);
            }
        }

        fn update_models_members(
            ref self: ContractState,
            selector: felt252,
            member_selectors: Span<felt252>,
            models: Array<IdValuesArray>,
        ) {
            self.resource.assert_caller_is_model_writer_from_selector(selector);
            let len = member_selectors.len();
            for mut model in models {
                for n in 0..len {
                    self
                        .resource
                        .emit_update_member(
                            selector,
                            model.id,
                            *member_selectors.at(n),
                            model.values.pop_front().unwrap(),
                        );
                }
            }
        }
    }
}
