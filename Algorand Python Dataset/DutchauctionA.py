import algopy

class DutchAuction(algopy.ARC4Contract):
    """
    Dutch auction contract that handles bidding with timer extensions and fees
    """
    
    def __init__(self) -> None:
        # Initialize max values
        self.max_attendees = algopy.UInt64(30)
        self.box_map = algopy.BoxMap(algopy.Bytes, algopy.UInt64)
        
    @algopy.arc4.abimethod(create="require")
    def init(self, 
             start_price: algopy.UInt64,
             duration: algopy.UInt64,
             timer_extension: algopy.UInt64) -> None:
        """Initialize auction parameters"""
        assert algopy.Txn.sender == algopy.Global.creator_address, "Only creator can initialize"

        # Store initial values
        box = algopy.Box(algopy.UInt64, key=b"price")
        box.value = start_price

        # Store duration
        end_box = algopy.Box(algopy.UInt64, key=b"round_end")
        end_box.value = algopy.Global.latest_timestamp + duration

        # Store timer extension
        timer_box = algopy.Box(algopy.UInt64, key=b"timer")
        timer_box.value = timer_extension

        # Initialize pot
        pot_box = algopy.Box(algopy.UInt64, key=b"pot")
        pot_box.value = algopy.UInt64(0)
        
    @algopy.arc4.abimethod()
    def bid(self, payment_txn: algopy.gtxn.PaymentTransaction) -> None:
        """Place a bid in the auction"""
        price_box = algopy.Box(algopy.UInt64, key=b"price")
        current_price = price_box.value
        
        # Verify payment amount matches current price
        assert payment_txn.amount == current_price, "Invalid bid amount"

        # Update pot
        pot_box = algopy.Box(algopy.UInt64, key=b"pot")
        pot_box.value += current_price

        # Store bidder info
        bidder_box = algopy.Box(algopy.UInt64, key=payment_txn.sender.bytes)
        bidder_box.value = current_price
        
        # Update price (10% increase)
        price_box.value = current_price + (current_price * algopy.UInt64(10) // algopy.UInt64(100))

        # Extend auction time
        timer_box = algopy.Box(algopy.UInt64, key=b"timer")
        end_box = algopy.Box(algopy.UInt64, key=b"round_end")
        end_box.value = end_box.value + timer_box.value

    @algopy.arc4.abimethod()
    def claim_winnings(self) -> None:
        """Winner claims auction winnings"""
        # Verify auction ended
        end_box = algopy.Box(algopy.UInt64, key=b"round_end")
        assert algopy.Global.latest_timestamp > end_box.value, "Auction still active"
        
        # Verify caller is highest bidder
        bidder_box = algopy.Box(algopy.UInt64, key=algopy.Txn.sender.bytes)
        assert bool(bidder_box), "Not a bidder"
        
        # Verify this is highest bid
        price_box = algopy.Box(algopy.UInt64, key=b"price")
        assert bidder_box.value == price_box.value, "Not highest bidder"

        # Send winnings
        pot_box = algopy.Box(algopy.UInt64, key=b"pot")
        amount = pot_box.value
        assert amount > algopy.UInt64(0), "No funds to claim"

        # Reset pot and close auction
        pot_box.value = algopy.UInt64(0)
        
        # Send payment
        algopy.itxn.Payment(
            receiver=algopy.Txn.sender,
            amount=amount
        ).submit()

    @algopy.arc4.abimethod(readonly=True)
    def get_current_price(self) -> algopy.UInt64:
        """Get the current auction price"""
        price_box = algopy.Box(algopy.UInt64, key=b"price")
        return price_box.value

    @algopy.arc4.abimethod(readonly=True)
    def get_auction_end(self) -> algopy.UInt64:
        """Get auction end time"""
        end_box = algopy.Box(algopy.UInt64, key=b"round_end")
        return end_box.value
####################################################################################################################
    """@algopy.arc4.abimethod(readonly=True)
    def get_highest_bidder(self) -> algopy.Account:
        ""Get address of highest bidder""
        price_box = algopy.Box(algopy.UInt64, key=b"price")
        current_price = price_box.value

        for key in self.box_map:
            bid_box = self.box_map[key]
            if bid_box == current_price:
                return algopy.Account(key)

        
        
        return algopy.Global.zero_address"""
    

####################################################################################################################
    #solved problem for return types issues
    @algopy.arc4.abimethod(readonly=True)
    def get_highest_bidder(self) -> algopy.arc4.Address:
        """Get address of highest bidder"""
        # Get current price
        price_box = algopy.Box(algopy.UInt64, key=b"price")
        current_price = price_box.value

        # Get the highest bidder from storage
        bidder_box = algopy.Box(algopy.Bytes, key=b"highest_bidder")
        bid_value, exists = bidder_box.maybe()
        
        if exists:
            return algopy.arc4.Address(bid_value)
        
        return algopy.arc4.Address(algopy.Global.zero_address)
####################################################################################################################  
