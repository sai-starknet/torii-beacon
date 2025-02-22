use dojo_beacon::model::namespace::NamespaceBeaconTrait;
use starknet::ContractAddress;
use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

use super::contract::actions::ContractState as ActionsContractState;
use super::components::Moves;
use models::{Vec2, Direction};
use super::models;
const NAMESPACE_HASH: felt252 = bytearray_hash!("dojo_starter");

impl Beacon = dojo_beacon::model::namespace::NamespaceBeacon<NAMESPACE_HASH, ActionsContractState>;

#[generate_trait]
impl PrivateImpl of PrivateTrait {
    fn set_position(ref self: ActionsContractState, player: ContractAddress, position: Vec2) {
        self.positions.write(player, position);
        self.emit_model(@models::Position { player, vec: position });
    }

    fn set_moves(ref self: ActionsContractState, player: ContractAddress, moves: Moves) {
        self.moves.write(player, moves);
        self
            .emit_model(
                @models::Moves {
                    player,
                    remaining: moves.remaining,
                    last_direction: moves.last_direction,
                    can_move: moves.can_move,
                },
            );
    }

    fn emit_moved(ref self: ActionsContractState, player: ContractAddress, direction: Direction) {
        self.emit_model(@models::Moved { player, direction });
    }
}
