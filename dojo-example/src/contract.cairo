use super::models::{Direction, Vec2};

// define the interface
#[starknet::interface]
trait IActions<T> {
    fn spawn(ref self: T);
    fn move(ref self: T, direction: Direction);
}

#[starknet::contract]
pub mod actions {
    use crate::components::Moves;
    use crate::models;
    use crate::models::{Direction, Vec2};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::{ClassHash, ContractAddress, get_caller_address};
    use super::{IActions, next_position};
    use torii_beacon::dojo::DojoRegistry;

    use torii_beacon::dojo::const_ns;
    use torii_beacon::{EmitterEvents, emitter_component};

    const NAMESPACE_HASH: felt252 = bytearray_hash!("dojo_starter");


    component!(path: emitter_component, storage: emitter, event: EmitterEvents);
    impl Beacon = const_ns::ConstNsBeaconEmitter<NAMESPACE_HASH, ContractState>;
    // impl Events = resource_component::BeaconEventsImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        pub emitter: emitter_component::Storage,
        pub positions: Map::<ContractAddress, Vec2>,
        pub moves: Map::<ContractAddress, Moves>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        EmitterEvents: EmitterEvents,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        moves_class_hash: ClassHash,
        positions_class_hash: ClassHash,
        moved_class_hash: ClassHash,
    ) {
        self.register_namespace_with_hash("dojo_starter", NAMESPACE_HASH);
        self.register_model("dojo_starter", positions_class_hash);
        self.register_model("dojo_starter", moves_class_hash);
        self.register_model("dojo_starter", moved_class_hash);
    }


    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn(ref self: ContractState) {
            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();

            // Retrieve the player's current position from the world.
            let mut position = self.positions.read(player);

            // Update the world state with the new data.

            // 1. Move the player's position 10 units in both the x and y direction.
            position.x += 10;
            position.y += 10;

            self.set_position(player, position);

            // 2. Set the player's remaining moves to 100.
            self
                .set_moves(
                    player,
                    Moves { remaining: 100, last_direction: Direction::None(()), can_move: true },
                );
        }

        // Implementation of the move function for the ContractState struct.
        fn move(ref self: ContractState, direction: Direction) {
            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();
            // Retrieve the player's current position and moves data from the world.
            let mut position = self.positions.read(player);
            let mut moves = self.moves.read(player);

            // Deduct one from the player's remaining moves.
            moves.remaining -= 1;

            // Update the last direction the player moved in.
            moves.last_direction = direction;

            // Calculate the player's next position based on the provided direction.
            let next = next_position(position, direction);

            // Write the new position to the world.
            self.set_position(player, next);

            // Write the new moves to the world.
            self.set_moves(player, moves);

            // Emit an event to the world to notify about the player's move.
            self.emit_moved(player, direction);
        }
    }

    #[generate_trait]
    impl PrivateImpl of PrivateTrait {
        fn set_position(ref self: ContractState, player: ContractAddress, position: Vec2) {
            self.positions.write(player, position);
            self.emit_model(@models::Position { player, vec: position });
        }

        fn set_moves(ref self: ContractState, player: ContractAddress, moves: Moves) {
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

        fn emit_moved(ref self: ContractState, player: ContractAddress, direction: Direction) {
            self.emit_model(@models::Moved { player, direction });
        }
    }
}

// Define function like this:
fn next_position(mut position: Vec2, direction: Direction) -> Vec2 {
    match direction {
        Direction::None => { return position; },
        Direction::Left => { position.x -= 1; },
        Direction::Right => { position.x += 1; },
        Direction::Up => { position.y -= 1; },
        Direction::Down => { position.y += 1; },
    };
    position
}
