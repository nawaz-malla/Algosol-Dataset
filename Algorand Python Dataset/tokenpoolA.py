import typing
import algopy 

class TokenPool(algopy.ARC4Contract):
    def __init__(self) -> None:
        self.manager = algopy.Account()
        self.manager_stake_share = algopy.UInt64(0)
        self.manager_gov_share = algopy.UInt64(0)
        self.gov_stake = algopy.UInt64(0)
        self.total_stake = algopy.UInt64(0)
        self.box_map = algopy.BoxMap(algopy.Bytes, algopy.UInt64)

    @algopy.arc4.abimethod(create="require")
    def init(self, manager: algopy.Account, stake_share: algopy.UInt64, gov_share: algopy.UInt64) -> None:
        assert algopy.Txn.sender == algopy.Global.creator_address, "Only creator can initialize"
        assert stake_share <= algopy.UInt64(1000), "Stake share must be <= 1000"
        assert gov_share <= algopy.UInt64(1000), "Gov share must be <= 1000"
        
        self.manager = manager
        self.manager_stake_share = stake_share
        self.manager_gov_share = gov_share

    @algopy.arc4.abimethod()
    def stake_tokens(self, token_xfer: algopy.gtxn.AssetTransferTransaction) -> None:
        """Stake tokens in the pool"""
        # Verify transfer transaction
        assert token_xfer.xfer_asset.id == algopy.UInt64(1138500612), "Invalid token ID"
        assert token_xfer.asset_receiver == algopy.Global.current_application_address, "Invalid receiver"
        assert token_xfer.asset_amount > algopy.UInt64(0), "Must stake > 0 tokens"
        
        # Get or create user stake box
        stake_box = algopy.Box(algopy.UInt64, key=algopy.Txn.sender.bytes)
        
        # Update stake amounts
        self.total_stake += token_xfer.asset_amount
        if bool(stake_box):
            stake_box.value += token_xfer.asset_amount
        else:
            stake_box.value = token_xfer.asset_amount

    @algopy.arc4.abimethod() 
    def withdraw_tokens(self, amount: algopy.UInt64) -> None:
        """Withdraw staked tokens"""
        # Get user stake amount
        stake_box = algopy.Box(algopy.UInt64, key=algopy.Txn.sender.bytes)
        stake_amount = stake_box.value if bool(stake_box) else algopy.UInt64(0)
        
        assert amount <= stake_amount, "Insufficient stake balance"
        
        # Update stake amounts
        self.total_stake -= amount
        stake_box.value -= amount
        
        # Send tokens back to user
        self._send_tokens(
            algopy.Txn.sender,
            algopy.UInt64(1138500612),
            amount
        )

    @algopy.arc4.abimethod()
    def claim_rewards(self) -> None:
        """Claim staking rewards"""
        # Get user stake info
        stake_box = algopy.Box(algopy.UInt64, key=algopy.Txn.sender.bytes)
        assert bool(stake_box), "No stake found"
        
        # Calculate rewards
        stake_amount = stake_box.value
        reward_share = (stake_amount * algopy.UInt64(1000000)) // self.total_stake
        reward_amount = (self.gov_stake * reward_share) // algopy.UInt64(1000000)
        
        assert reward_amount > algopy.UInt64(0), "No rewards to claim"
        
        # Send rewards
        self._send_tokens(
            algopy.Txn.sender,
            algopy.UInt64(1140801821),
            reward_amount
        )
        
        # Reset user's rewards
        self.gov_stake -= reward_amount

    @algopy.arc4.abimethod(readonly=True)
    def get_stake_amount(self) -> algopy.UInt64:
        """Get user's staked amount"""
        stake_box = algopy.Box(algopy.UInt64, key=algopy.Txn.sender.bytes)
        amount, exists = stake_box.maybe()
        assert exists, "No stake found"
        return amount

    @algopy.subroutine
    def _send_tokens(self, receiver: algopy.Account, asset_id: algopy.UInt64, amount: algopy.UInt64) -> None:
        """Internal helper to send tokens"""
        algopy.itxn.AssetTransfer(
            xfer_asset=asset_id,
            asset_receiver=receiver,
            asset_amount=amount
        ).submit()

    @algopy.arc4.abimethod(readonly=True)
    def get_manager(self) -> algopy.arc4.Address:
        """Get contract manager address"""
        return algopy.arc4.Address(self.manager)
