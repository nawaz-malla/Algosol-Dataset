import algopy

class AssetTrading(algopy.ARC4Contract):
    def __init__(self) -> None:
        # Box storage for state variables
        self.box_map = algopy.BoxMap(algopy.Bytes, algopy.UInt64)
        self.max_quantity = algopy.UInt64(1000)
        self.min_price = algopy.UInt64(10000)
        self.min_balance = algopy.UInt64(202000)

    @algopy.arc4.abimethod(create="require")
    def init(self,
            rewards_address: algopy.Account,
            asset_id: algopy.UInt64,
            unit_price: algopy.UInt64,
            units_available: algopy.UInt64,
            max_qty: algopy.UInt64) -> None:
        """Initialize trading contract"""
        # Store creator's address
        creator_box = algopy.Box(algopy.Account, key=b"creator")
        creator_box.value = algopy.Txn.sender

        # Store rewards address
        rewards_box = algopy.Box(algopy.Account, key=b"rewards")
        rewards_box.value = rewards_address

        # Store asset details
        asset_box = algopy.Box(algopy.UInt64, key=b"asset_id")
        asset_box.value = asset_id

        price_box = algopy.Box(algopy.UInt64, key=b"price")
        price_box.value = unit_price

        units_box = algopy.Box(algopy.UInt64, key=b"units")
        units_box.value = units_available

        max_qty_box = algopy.Box(algopy.UInt64, key=b"max_qty")
        max_qty_box.value = max_qty

        # Initialize units sold
        sold_box = algopy.Box(algopy.UInt64, key=b"sold")
        sold_box.value = algopy.UInt64(0)

    @algopy.arc4.abimethod()
    def setup_escrow(self, 
                   payment_txn: algopy.gtxn.PaymentTransaction, 
                   asset_opt_in: algopy.gtxn.AssetTransferTransaction) -> None:
        """Setup escrow account for trading"""
        # Verify creator
        creator_box = algopy.Box(algopy.Account, key=b"creator")
        assert algopy.Txn.sender == creator_box.value, "Not creator"

        # Store escrow address
        escrow_box = algopy.Box(algopy.Account, key=b"escrow")
        escrow_box.value = payment_txn.receiver

        # Verify payment amount
        units_box = algopy.Box(algopy.UInt64, key=b"units")
        required_amount = self.min_balance + (algopy.UInt64(1000) * units_box.value)
        assert payment_txn.amount == required_amount, "Wrong amount"

        # Verify asset opt-in
        asset_box = algopy.Box(algopy.UInt64, key=b"asset_id")
        assert asset_opt_in.xfer_asset.id == asset_box.value, "Wrong asset"
        assert asset_opt_in.asset_receiver == payment_txn.receiver, "Wrong receiver"

    @algopy.arc4.abimethod()
    def buy_tokens(self, 
                 payment_txn: algopy.gtxn.PaymentTransaction,
                 asset_txn: algopy.gtxn.AssetTransferTransaction) -> None:
        """Buy asset tokens"""
        # Verify escrow
        escrow_box = algopy.Box(algopy.Account, key=b"escrow")
        assert asset_txn.sender == escrow_box.value, "Not escrow"

        # Verify amount
        max_qty_box = algopy.Box(algopy.UInt64, key=b"max_qty")
        assert asset_txn.asset_amount <= max_qty_box.value, "Exceeds max"
        assert asset_txn.asset_amount > algopy.UInt64(0), "Zero amount"

        # Verify payment
        price_box = algopy.Box(algopy.UInt64, key=b"price")
        expected_payment = price_box.value * asset_txn.asset_amount
        assert payment_txn.amount == expected_payment, "Wrong payment"

        # Update units sold
        sold_box = algopy.Box(algopy.UInt64, key=b"sold")
        sold_box.value += asset_txn.asset_amount

        # Record buyer's purchase
        buyer_box = algopy.Box(algopy.UInt64, key=asset_txn.asset_receiver.bytes)
        buyer_box.value = asset_txn.asset_amount

    @algopy.arc4.abimethod()
    def claim_rewards(self) -> None:
        """Claim trading rewards"""
        # Verify rewards address
        rewards_box = algopy.Box(algopy.Account, key=b"rewards")
        rewards_addr = rewards_box.value

        # Calculate reward
        sold_box = algopy.Box(algopy.UInt64, key=b"sold")
        price_box = algopy.Box(algopy.UInt64, key=b"price")
        reward_amount = (sold_box.value * price_box.value) // algopy.UInt64(10)

        # Send reward payment
        escrow_box = algopy.Box(algopy.Account, key=b"escrow")
        algopy.itxn.Payment(
            sender=escrow_box.value,
            receiver=rewards_addr,
            amount=reward_amount
        ).submit()

    @algopy.arc4.abimethod(readonly=True)
    def get_available_units(self) -> algopy.UInt64:
        """Get remaining available units"""
        units_box = algopy.Box(algopy.UInt64, key=b"units")
        sold_box = algopy.Box(algopy.UInt64, key=b"sold")
        return units_box.value - sold_box.value

    @algopy.arc4.abimethod(readonly=True)
    def get_buyer_tokens(self, buyer: algopy.Account) -> algopy.UInt64:
        """Get tokens purchased by buyer"""
        buyer_box = algopy.Box(algopy.UInt64, key=buyer.bytes)
        amount, exists = buyer_box.maybe()
        if exists:
            return amount
        return algopy.UInt64(0)
