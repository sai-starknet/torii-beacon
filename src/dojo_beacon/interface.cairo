use super::{IdKeysValues, IdValues, IdValuesArray};

#[starknet::interface]
pub trait IBeacon<TContractState> {
    fn set_model(
        ref self: TContractState,
        selector: felt252,
        entity_id: felt252,
        keys: Span<felt252>,
        values: Span<felt252>,
    );
    fn set_models(ref self: TContractState, selector: felt252, models: Array<IdKeysValues>);
    fn update_model(
        ref self: TContractState, selector: felt252, entity_id: felt252, values: Span<felt252>,
    );
    fn update_models(ref self: TContractState, selector: felt252, models: Array<IdValues>);
    fn update_member(
        ref self: TContractState,
        selector: felt252,
        entity_id: felt252,
        member_selector: felt252,
        values: Span<felt252>,
    );
    fn update_members(
        ref self: TContractState, selector: felt252, entity_id: felt252, members: Array<IdValues>,
    );
    fn update_models_member(
        ref self: TContractState,
        selector: felt252,
        member_selector: felt252,
        models: Array<IdValues>,
    );

    fn update_models_members(
        ref self: TContractState,
        selector: felt252,
        member_selectors: Span<felt252>,
        models: Array<IdValuesArray>,
    );
}
