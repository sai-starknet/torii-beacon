use starknet::ClassHash;
use dojo::model::Model;
use dojo_beacon::resource_component::{BeaconEventsImpl, ResourceRegisterImpl};

pub trait BeaconEmitterTrait<TState> {
    fn register_namespace(ref self: TState, namespace: ByteArray);
    fn register_model(ref self: TState, namespace: ByteArray, class_hash: ClassHash);
    fn emit_model<M, +Model<M>>(ref self: TState, model: @M);
    fn emit_models<M, +Model<M>>(ref self: TState, models: Span<M>);
    fn emit_entity<M, T, +Model<M>, +Serde<T>>(ref self: TState, entity_id: felt252, entity: @T);
    fn emit_entities<M, T, +Model<M>, +Serde<T>>(ref self: TState, entities: Array<(felt252, @T)>);
    fn emit_member<M, T, +Model<M>, +Serde<T>>(
        ref self: TState, entity_id: felt252, member_selector: felt252, member: @T,
    );
    fn emit_members<M, T, +Model<M>, +Serde<T>>(
        ref self: TState, entity_id: felt252, members: Array<(felt252, @T)>,
    );
}

