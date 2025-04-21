from typing import Final
from algopy import Account, ARC4Contract, Box, BoxMap, Bytes, Global, String, Txn, UInt64, arc4, itxn, op, subroutine

# Event structs
class GameStoppedEvent(arc4.Struct):
    total_balance: arc4.UInt64
    total_players: arc4.UInt64
    refund_amount: arc4.UInt64

class PlayerAddedEvent(arc4.Struct):
    game_index: arc4.UInt64
    player: arc4.Address

class GameOverEvent(arc4.Struct):
    game_index: arc4.UInt64
    total_size: arc4.UInt64
    single_price: arc4.UInt64
    pump_rate: arc4.UInt64
    winner: arc4.Address
    timestamp: arc4.UInt64

class BREBuy(ARC4Contract):
    """
    BREBuy game implementation on Algorand
    A gambling game where players buy tickets and a random winner is selected
    """
    
    def __init__(self) -> None:
        # Initialize state
        self.owner = Global.creator_address
        self.game_index = UInt64(0)
        self.total_price = UInt64(0)
        self.is_locked = UInt64(0)  # 0 = false, 1 = true
        
        # Game configuration
        self.total_size = UInt64(0)
        self.single_price = UInt64(0)
        self.pump_rate = UInt64(5)  # 5%
        self.config_changed = UInt64(0)  # 0 = false, 1 = true
        
        # Players storage using BoxMap
        self.players = BoxMap(UInt64, Account, key_prefix=b"p_")
        self.player_count = UInt64(0)

    @arc4.abimethod(create="require")
    def init(self, total_size: arc4.UInt64, single_price: arc4.UInt64) -> None:
        """Initialize contract with initial parameters"""
        finney = UInt64(1_000_000)  # 1 ALGO = 1,000,000 microALGO
        self.total_size = total_size.native
        self.single_price = single_price.native * finney
        self.start_new_game()

    @subroutine
    def only_owner(self) -> None:
        """Verify sender is contract owner"""
        assert Txn.sender == self.owner, "only owner can call this function"

    @subroutine
    def not_locked(self) -> None:
        """Verify contract is not locked"""
        assert self.is_locked == UInt64(0), "contract current is lock status"

    @arc4.abimethod
    def update_lock(self, new_lock_state: arc4.Bool) -> None:
        """Update contract lock status"""
        self.only_owner()
        state = UInt64(1) if new_lock_state.native else UInt64(0)
        assert self.is_locked != state, "updateLock new status == old status"
        
        self.is_locked = state
        
        if state == UInt64(1):
            self.stop_game()
        else:
            self.start_new_game()

    @subroutine
    def stop_game(self) -> None:
        """Stop current game and refund players"""
        self.only_owner()
        
        if self.player_count == UInt64(0):
            return
            
        total_balance = Global.current_application_address.balance
        price_per_player = total_balance // self.player_count
        
        # Refund each player
        i = UInt64(0)
        while i < self.player_count:
            player = self.players[i]
            itxn.Payment(
                receiver=player,
                amount=price_per_player,
                fee=0
            ).submit()
            i += UInt64(1)
            
        arc4.emit(GameStoppedEvent(
            total_balance=arc4.UInt64(total_balance),
            total_players=arc4.UInt64(self.player_count),
            refund_amount=arc4.UInt64(price_per_player)
        ))
        
        # Reset players
        self.player_count = UInt64(0)

    @arc4.abimethod
    def change_config(
        self,
        total_size: arc4.UInt64,
        single_price: arc4.UInt64,
        pump_rate: arc4.UInt64
    ) -> None:
        """Change game configuration"""
        self.only_owner()
        
        finney = UInt64(1_000_000)
        
        if self.total_size != total_size.native:
            self.total_size = total_size.native
        if self.pump_rate != pump_rate.native:
            self.pump_rate = pump_rate.native
        if self.single_price != single_price.native * finney:
            self.single_price = single_price.native * finney
            
        self.config_changed = UInt64(1)

    @subroutine
    def start_new_game(self) -> None:
        """Start a new game round"""
        self.game_index += UInt64(1)
        self.player_count = UInt64(0)
        self.config_changed = UInt64(0)

    @arc4.abimethod
    def buy_ticket(self) -> None:
        """Buy a ticket for the current game"""
        self.not_locked()
        
        # Verify payment
        assert Txn.amount == self.single_price, "incorrect payment amount"
        
        # Add player
        self.players[self.player_count] = Txn.sender
        self.player_count += UInt64(1)
        self.total_price += Txn.amount
        
        arc4.emit(PlayerAddedEvent(
            game_index=arc4.UInt64(self.game_index),
            player=arc4.Address(Txn.sender.bytes)
        ))
        
        # Check if game should end
        if self.player_count >= self.total_size:
            self.execute_game_result()
            self.start_new_game()

    @subroutine
    def execute_game_result(self) -> None:
        """Execute game result and distribute prizes"""
        winner_index = self.get_random_index()
        winner = self.players[winner_index]
        
        # Calculate prizes
        total_balance = Global.current_application_address.balance
        owner_share = (total_balance * self.pump_rate) // UInt64(100)
        winner_share = total_balance - owner_share
        
        # Distribute prizes
        itxn.Payment(receiver=self.owner, amount=owner_share, fee=0).submit()
        itxn.Payment(receiver=winner, amount=winner_share, fee=0).submit()
        
        arc4.emit(GameOverEvent(
            game_index=arc4.UInt64(self.game_index),
            total_size=arc4.UInt64(self.total_size),
            single_price=arc4.UInt64(self.single_price),
            pump_rate=arc4.UInt64(self.pump_rate),
            winner=arc4.Address(winner.bytes),
            timestamp=arc4.UInt64(Global.latest_timestamp)
        ))

    @subroutine
    def get_random_index(self) -> UInt64:
        """Generate random index using block hash"""
        # Generate hash using current block's timestamp as source of randomness
        hash_input = op.concat(
            Bytes(b"SEED"),
            Global.current_application_address.bytes
        )
        random_seed = op.sha512_256(hash_input)
        
        # Convert to integer and perform modulo - no need for extra conversions
        # since op.btoi already returns UInt64
        random_int = op.btoi(random_seed)
        return random_int % self.player_count
