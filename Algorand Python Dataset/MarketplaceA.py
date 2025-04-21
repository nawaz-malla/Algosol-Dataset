

from algopy import (
    # On Algorand, assets are native objects rather than smart contracts
    Asset,
    # Global is used to access global variables from the network
    Global,
    # Txn is used access information about the current transcation
    Txn,
    # By default, all numbers in the AVM are 64-bit unsigned integers
    UInt64,
    # ARC4 defines the Algorand ABI for method calling and type encoding
    arc4,
    # gtxn is used to read transaction within the same atomic group
    gtxn,
    itxn,
)


# We want the methods in our contract to follow the ARC4 standard
class DigitalMarketplace(arc4.ARC4Contract):
    # Every asset has a unique ID
    # We want to store the ID for the asset we are selling
    asset_id: UInt64

    # We want to store the price for the asset we are selling
    unitary_price: UInt64

    # We want create_application to be a plublic ABI method
    @arc4.abimethod(
        # There are certain actions that a contract call can do
        # Some examples are UpdateApplication, DeleteApplication, and NoOp
        # NoOp is a call that does nothing special after it is exected
        allow_actions=["NoOp"],
        # Require that this method is only callable when creating the app
        create="require",
    )
    def create_application(
        self,
        # The ID of the asset we're selling
        asset_id: Asset,
        # The initial sale price
        unitary_price: UInt64,
    ) -> None:
        # Save the values we passed in to our method in the contract's state
        self.asset_id = asset_id.id
        self.unitary_price = unitary_price

    @arc4.abimethod
    def set_price(self, unitary_price: UInt64) -> None:
        # We don't want anyone to be able to come in and modify the price
        # You could implement some sort of RBAC,
        # but in this case just making sure the caller is the app creator works
        assert Txn.sender == Global.creator_address

        # Save the new price
        self.unitary_price = unitary_price

    # Before any account can receive an asset, it must opt-in to it
    # This method enables the application to opt-in to the asset
    @arc4.abimethod
    def opt_in_to_asset(
        self,
        # Whenever someone calls this method, they also need to send a payment
        # A payment transaction is a transfer of ALGO
        mbr_pay: gtxn.PaymentTransaction,
    ) -> None:
        # We want to make sure that the application address is not already opted in
        assert not Global.current_application_address.is_opted_in(Asset(self.asset_id))

        assert mbr_pay.receiver == Global.current_application_address

        assert mbr_pay.amount == Global.min_balance + Global.asset_opt_in_min_balance
        itxn.AssetTransfer(
            xfer_asset=self.asset_id,
            asset_receiver=Global.current_application_address,
            asset_amount=0,
        ).submit()

    @arc4.abimethod
    def buy(
        self,
        # To buy assets, a payment must be sent
        buyer_txn: gtxn.PaymentTransaction,
        # The quantity of assets to buy
        quantity: UInt64,
    ) -> None:
        assert buyer_txn.sender == Txn.sender
        assert buyer_txn.receiver == Global.current_application_address
        assert buyer_txn.amount == self.unitary_price * quantity

        # Once we've verified the payment, we can transfer the asset
        itxn.AssetTransfer(
            xfer_asset=self.asset_id,
            asset_receiver=Txn.sender,
            asset_amount=quantity,
        ).submit()

    @arc4.abimethod(
        # This method is called when the application is deleted
        allow_actions=["DeleteApplication"]
    )
    def delete_application(self) -> None:
        # Only allow the creator to delete the application
        assert Txn.sender == Global.creator_address

        # Send all the unsold assets to the creator
        itxn.AssetTransfer(
            xfer_asset=self.asset_id,
            asset_receiver=Global.creator_address,
            asset_amount=0,
            asset_close_to=Global.creator_address,
        ).submit()

        # Send the remaining balance to the creator
        itxn.Payment(
            receiver=Global.creator_address,
            amount=0,
            # Close the account to get back ALL the ALGO in the account
            close_remainder_to=Global.creator_address,
        ).submit()
