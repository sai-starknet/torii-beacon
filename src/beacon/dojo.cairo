use dojo::model::Model;

use dojo_beacon::utils::serialize_inline;
use super::{IdKeysValues, IdValues, IBeaconDispatcher, IBeaconDispatcherTrait};


trait ModelBeacon<B> {
    fn set_model<M, +Model<M>>(ref self: B, model: @M);
    fn set_models<M, +Model<M>>(ref self: B, models: Array<@M>);
    fn update_entity<M, E, +Model<M>, +Serde<E>>(ref self: B, entity_id: felt252, entity: @E);
    fn update_entities<M, E, +Model<M>, +Serde<E>>(ref self: B, entities: Array<(felt252, @E)>);
    fn update_member<M, T, +Model<M>, +Serde<T>>(
        ref self: B, entity_id: felt252, member_selector: felt252, member: @T,
    );
    fn update_models_member<M, T, +Model<M>, +Serde<T>>(
        ref self: B, member_selector: felt252, models: Array<(felt252, @T)>,
    );
}

#[derive(Drop)]
struct BeaconNamespace {
    dispatcher: IBeaconDispatcher,
    namespace_hash: felt252,
}


impl BeaconWithNamespaceImpl of ModelBeacon<BeaconNamespace> {
    fn set_model<M, +Model<M>>(ref self: BeaconNamespace, model: @M) {
        IBeaconDispatcherTrait::set_model(
            self.dispatcher,
            Model::<M>::selector(self.namespace_hash),
            model.entity_id(),
            model.serialized_keys(),
            model.serialized_values(),
        );
    }

    fn set_models<M, +Model<M>>(ref self: BeaconNamespace, models: Array<@M>) {
        let mut id_keys_values = ArrayTrait::<IdKeysValues>::new();
        for model in models {
            id_keys_values
                .append(
                    IdKeysValues {
                        id: model.entity_id(),
                        keys: model.serialized_keys(),
                        values: model.serialized_values(),
                    },
                );
        };
        IBeaconDispatcherTrait::set_models(
            self.dispatcher, Model::<M>::selector(self.namespace_hash), id_keys_values,
        );
    }

    fn update_entity<M, T, +Model<M>, +Serde<T>>(
        ref self: BeaconNamespace, entity_id: felt252, entity: @T,
    ) {
        IBeaconDispatcherTrait::update_model(
            self.dispatcher,
            Model::<M>::selector(self.namespace_hash),
            entity_id,
            serialize_inline(entity).span(),
        );
    }

    fn update_entities<M, E, +Model<M>, +Serde<E>>(
        ref self: BeaconNamespace, entities: Array<(felt252, @E)>,
    ) {
        let mut id_values = ArrayTrait::<IdValues>::new();
        for (entity_id, entity) in entities {
            id_values.append(IdValues { id: entity_id, values: serialize_inline(entity).span() });
        };
        IBeaconDispatcherTrait::update_models(
            self.dispatcher, Model::<M>::selector(self.namespace_hash), id_values,
        );
    }

    fn update_member<M, T, +Model<M>, +Serde<T>>(
        ref self: BeaconNamespace, entity_id: felt252, member_selector: felt252, member: @T,
    ) {
        IBeaconDispatcherTrait::update_member(
            self.dispatcher,
            Model::<M>::selector(self.namespace_hash),
            entity_id,
            member_selector,
            serialize_inline(member).span(),
        );
    }

    fn update_models_member<M, T, +Model<M>, +Serde<T>>(
        ref self: BeaconNamespace, member_selector: felt252, models: Array<(felt252, @T)>,
    ) {
        let mut id_values_array = ArrayTrait::<IdValues>::new();
        for (entity_id, member) in models {
            id_values_array
                .append(IdValues { id: entity_id, values: serialize_inline(member).span() });
        };
        IBeaconDispatcherTrait::update_models_member(
            self.dispatcher,
            Model::<M>::selector(self.namespace_hash),
            member_selector,
            id_values_array,
        );
    }
}


impl BeaconWithConstNamespace<const NAMESPACE_HASH: felt252> of ModelBeacon<IBeaconDispatcher> {
    fn set_model<M, +Model<M>>(ref self: IBeaconDispatcher, model: @M) {
        IBeaconDispatcherTrait::set_model(
            self,
            Model::<M>::selector(NAMESPACE_HASH),
            model.entity_id(),
            model.serialized_keys(),
            model.serialized_values(),
        );
    }

    fn set_models<M, +Model<M>>(ref self: IBeaconDispatcher, models: Array<@M>) {
        let mut id_keys_values = ArrayTrait::<IdKeysValues>::new();
        for model in models {
            id_keys_values
                .append(
                    IdKeysValues {
                        id: model.entity_id(),
                        keys: model.serialized_keys(),
                        values: model.serialized_values(),
                    },
                );
        };
        IBeaconDispatcherTrait::set_models(
            self, Model::<M>::selector(NAMESPACE_HASH), id_keys_values,
        );
    }

    fn update_entity<M, T, +Model<M>, +Serde<T>>(
        ref self: IBeaconDispatcher, entity_id: felt252, entity: @T,
    ) {
        IBeaconDispatcherTrait::update_model(
            self, Model::<M>::selector(NAMESPACE_HASH), entity_id, serialize_inline(entity).span(),
        );
    }

    fn update_entities<M, E, +Model<M>, +Serde<E>>(
        ref self: IBeaconDispatcher, entities: Array<(felt252, @E)>,
    ) {
        let mut id_values = ArrayTrait::<IdValues>::new();
        for (entity_id, entity) in entities {
            id_values.append(IdValues { id: entity_id, values: serialize_inline(entity).span() });
        };
        IBeaconDispatcherTrait::update_models(
            self, Model::<M>::selector(NAMESPACE_HASH), id_values,
        );
    }

    fn update_member<M, T, +Model<M>, +Serde<T>>(
        ref self: IBeaconDispatcher, entity_id: felt252, member_selector: felt252, member: @T,
    ) {
        IBeaconDispatcherTrait::update_member(
            self,
            Model::<M>::selector(NAMESPACE_HASH),
            entity_id,
            member_selector,
            serialize_inline(member).span(),
        );
    }

    fn update_models_member<M, T, +Model<M>, +Serde<T>>(
        ref self: IBeaconDispatcher, member_selector: felt252, models: Array<(felt252, @T)>,
    ) {
        let mut id_values_array = ArrayTrait::<IdValues>::new();
        for (entity_id, member) in models {
            id_values_array
                .append(IdValues { id: entity_id, values: serialize_inline(member).span() });
        };
        IBeaconDispatcherTrait::update_models_member(
            self, Model::<M>::selector(NAMESPACE_HASH), member_selector, id_values_array,
        );
    }
}


impl BeaconWithConstSelector<const SELECTOR: felt252> of ModelBeacon<IBeaconDispatcher> {
    fn set_model<M, +Model<M>>(ref self: IBeaconDispatcher, model: @M) {
        IBeaconDispatcherTrait::set_model(
            self, SELECTOR, model.entity_id(), model.serialized_keys(), model.serialized_values(),
        );
    }

    fn set_models<M, +Model<M>>(ref self: IBeaconDispatcher, models: Array<@M>) {
        let mut id_keys_values = ArrayTrait::<IdKeysValues>::new();
        for model in models {
            id_keys_values
                .append(
                    IdKeysValues {
                        id: model.entity_id(),
                        keys: model.serialized_keys(),
                        values: model.serialized_values(),
                    },
                );
        };
        IBeaconDispatcherTrait::set_models(self, SELECTOR, id_keys_values);
    }

    fn update_entity<M, T, +Model<M>, +Serde<T>>(
        ref self: IBeaconDispatcher, entity_id: felt252, entity: @T,
    ) {
        IBeaconDispatcherTrait::update_model(
            self, SELECTOR, entity_id, serialize_inline(entity).span(),
        );
    }

    fn update_entities<M, E, +Model<M>, +Serde<E>>(
        ref self: IBeaconDispatcher, entities: Array<(felt252, @E)>,
    ) {
        let mut id_values = ArrayTrait::<IdValues>::new();
        for (entity_id, entity) in entities {
            id_values.append(IdValues { id: entity_id, values: serialize_inline(entity).span() });
        };
        IBeaconDispatcherTrait::update_models(self, SELECTOR, id_values);
    }

    fn update_member<M, T, +Model<M>, +Serde<T>>(
        ref self: IBeaconDispatcher, entity_id: felt252, member_selector: felt252, member: @T,
    ) {
        IBeaconDispatcherTrait::update_member(
            self, SELECTOR, entity_id, member_selector, serialize_inline(member).span(),
        );
    }

    fn update_models_member<M, T, +Model<M>, +Serde<T>>(
        ref self: IBeaconDispatcher, member_selector: felt252, models: Array<(felt252, @T)>,
    ) {
        let mut id_values_array = ArrayTrait::<IdValues>::new();
        for (entity_id, member) in models {
            id_values_array
                .append(IdValues { id: entity_id, values: serialize_inline(member).span() });
        };
        IBeaconDispatcherTrait::update_models_member(
            self, SELECTOR, member_selector, id_values_array,
        );
    }
}
