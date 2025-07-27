use dojo::model::Model;


pub trait BeaconEmitterTrait<S> {
    fn set_model<M, +Model<M>>(ref self: S, model: @M);
    fn set_models<M, +Model<M>>(ref self: S, models: Span<M>);
    fn set_entity<M, T, +Model<M>, +Serde<T>>(ref self: S, entity_id: felt252, entity: @T);
    fn set_entities<M, T, +Model<M>, +Serde<T>>(ref self: S, entities: Array<(felt252, @T)>);
    fn set_member<M, T, +Model<M>, +Serde<T>>(
        ref self: S, entity_id: felt252, member_selector: felt252, member: @T,
    );
    fn set_members<M, T, +Model<M>, +Serde<T>>(
        ref self: S, member_selector: felt252, members: Array<(felt252, @T)>,
    );
    fn set_model_members<M, T, +Model<M>, +Serde<T>>(
        ref self: S, entity_id: felt252, members: Array<(felt252, @T)>,
    );
    fn set_delete_model<M, +Model<M>>(ref self: S, entity_id: felt252);
}

pub trait BeaconNsEmitterTrait<S> {
    fn set_model<M, +Model<M>>(ref self: S, namespace: felt252, model: @M);
    fn set_models<M, +Model<M>>(ref self: S, namespace: felt252, models: Span<M>);
    fn set_entity<M, T, +Model<M>, +Serde<T>>(
        ref self: S, namespace: felt252, entity_id: felt252, entity: @T,
    );
    fn set_entities<M, T, +Model<M>, +Serde<T>>(
        ref self: S, namespace: felt252, entities: Array<(felt252, @T)>,
    );
    fn set_member<M, T, +Model<M>, +Serde<T>>(
        ref self: S, namespace: felt252, entity_id: felt252, member_selector: felt252, member: @T,
    );
    fn set_members<M, T, +Model<M>, +Serde<T>>(
        ref self: S, namespace: felt252, member_selector: felt252, members: Array<(felt252, @T)>,
    );
    fn set_model_members<M, T, +Model<M>, +Serde<T>>(
        ref self: S, namespace: felt252, entity_id: felt252, members: Array<(felt252, @T)>,
    );
    fn set_delete_model<M, +Model<M>>(ref self: S, namespace: felt252, entity_id: felt252);
}

