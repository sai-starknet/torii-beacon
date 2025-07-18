use super::models::Direction;

#[derive(Copy, Drop, Serde, Debug, starknet::Store)]
pub struct Moves {
    pub remaining: u8,
    pub last_direction: Direction,
    pub can_move: bool,
}
