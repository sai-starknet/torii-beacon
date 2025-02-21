use super::models::{Direction, Vec2};

// define the interface
#[starknet::interface]
trait IActions<T> {
    fn spawn(ref self: T);
    fn move(ref self: T, direction: Direction);
}

// dojo decorator
#[starknet::contract]
pub mod actions {
    use starknet::{ContractAddress, ClassHash, get_caller_address};

    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

    use dojo_beacon_example::models;
    use models::{Vec2, Direction};
    use dojo_beacon_example::components::Moves;

    use dojo_beacon::resource_component;
    use dojo_beacon::model::namespace;

    use super::{IActions, next_position};

    const NAMESPACE_HASH: felt252 = bytearray_hash!("dojo_starter");

    component!(path: resource_component, storage: resource, event: ResourceEvents);

    #[abi(embed_v0)]
    impl Resource = resource_component::BeaconResource<ContractState>;

    impl Events = resource_component::BeaconEventsImpl<ContractState>;
    impl Beacon = namespace::NamespaceBeacon<NAMESPACE_HASH, ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        resource: resource_component::Storage,
        positions: Map::<ContractAddress, Vec2>,
        moves: Map::<ContractAddress, Moves>,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        moves_class_hash: ClassHash,
        positions_class_hash: ClassHash,
        moved_class_hash: ClassHash,
    ) {
        Beacon::register_namespace(ref self, "dojo_starter");
        Beacon::register_model(ref self, "dojo_starter", positions_class_hash);
        Beacon::register_model(ref self, "dojo_starter", moves_class_hash);
        Beacon::register_model(ref self, "dojo_starter", moved_class_hash);
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ResourceEvents: resource_component::Event,
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
            Beacon::emit_model(ref self, @models::Position { player, vec: position });
        }

        fn set_moves(ref self: ContractState, player: ContractAddress, moves: Moves) {
            self.moves.write(player, moves);
            Beacon::emit_model(
                ref self,
                @models::Moves {
                    player,
                    remaining: moves.remaining,
                    last_direction: moves.last_direction,
                    can_move: moves.can_move,
                },
            );
        }

        fn emit_moved(ref self: ContractState, player: ContractAddress, direction: Direction) {
            Beacon::emit_model(ref self, @models::Moved { player, direction });
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
