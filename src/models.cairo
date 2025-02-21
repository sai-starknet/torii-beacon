use dojo::model::Model;

use dojo_beacon::interfaces::IBeaconDispatcher;

#[derive(Drop)]
struct BeaconNamespaced {
    namespace_hash: felt252,
    dispatcher: IBeaconDispatcher,
}

trait ModelBeacon<B> {
    fn set_model<M, +Model<M>>(ref self: B, model: @M);
    fn update_model<M, +Model<M>>(ref self: B, model: @M);
    fn update_member<M, +Model<M>>(ref self: B, model: @M, member: felt252);
}
