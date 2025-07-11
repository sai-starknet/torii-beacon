use dojo::model::Model;


pub trait BeaconEmitterTrait<S> {
    fn emit_model<M, +Model<M>>(ref self: S, model: @M);
    fn emit_models<M, +Model<M>>(ref self: S, models: Span<M>);
    fn emit_entity<M, T, +Model<M>, +Serde<T>>(ref self: S, entity_id: felt252, entity: @T);
    fn emit_entities<M, T, +Model<M>, +Serde<T>>(ref self: S, entities: Array<(felt252, @T)>);
    fn emit_member<M, T, +Model<M>, +Serde<T>>(
        ref self: S, entity_id: felt252, member_selector: felt252, member: @T,
    );
    fn emit_members<M, T, +Model<M>, +Serde<T>>(
        ref self: S, member_selector: felt252, members: Array<(felt252, @T)>,
    );
    fn emit_model_members<M, T, +Model<M>, +Serde<T>>(
        ref self: S, entity_id: felt252, members: Array<(felt252, @T)>,
    );
    fn emit_delete_model<M, +Model<M>>(ref self: S, entity_id: felt252);
}

pub trait BeaconModelEmitterTrait<S, M, +Model<M>> {
    fn emit_model(ref self: S, model: @M);
    fn emit_models(ref self: S, models: Span<M>);
    fn emit_entity<T, +Serde<T>>(ref self: S, entity_id: felt252, entity: @T);
    fn emit_entities<T, +Serde<T>>(ref self: S, entities: Array<(felt252, @T)>);
    fn emit_member<T, +Serde<T>>(
        ref self: S, entity_id: felt252, member_selector: felt252, member: @T,
    );
    fn emit_members<T, +Serde<T>>(
        ref self: S, member_selector: felt252, members: Array<(felt252, @T)>,
    );
    fn emit_model_members<T, +Serde<T>>(
        ref self: S, entity_id: felt252, members: Array<(felt252, @T)>,
    );
    fn emit_delete_model(ref self: S, entity_id: felt252);
}


pub trait BeaconNsEmitterTrait<S> {
    fn emit_model<M, +Model<M>>(ref self: S, namespace_hash: felt252, model: @M);
    fn emit_models<M, +Model<M>>(ref self: S, namespace_hash: felt252, models: Span<M>);
    fn emit_entity<M, T, +Model<M>, +Serde<T>>(
        ref self: S, namespace_hash: felt252, entity_id: felt252, entity: @T,
    );
    fn emit_entities<M, T, +Model<M>, +Serde<T>>(
        ref self: S, namespace_hash: felt252, entities: Array<(felt252, @T)>,
    );
    fn emit_member<M, T, +Model<M>, +Serde<T>>(
        ref self: S,
        namespace_hash: felt252,
        entity_id: felt252,
        member_selector: felt252,
        member: @T,
    );
    fn emit_members<M, T, +Model<M>, +Serde<T>>(
        ref self: S,
        namespace_hash: felt252,
        member_selector: felt252,
        members: Array<(felt252, @T)>,
    );
    fn emit_model_members<M, T, +Model<M>, +Serde<T>>(
        ref self: S, namespace_hash: felt252, entity_id: felt252, members: Array<(felt252, @T)>,
    );
    fn emit_delete_model<M, +Model<M>>(ref self: S, namespace_hash: felt252, entity_id: felt252);
}

