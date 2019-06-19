pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address public owner = msg.sender;
    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
      string description;
      string website;
      uint totalTickets;
      uint sales;
      mapping(address => uint) buyers;
      bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping(uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner(){
      if (msg.sender != owner){
        revert();
      }
      _;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _websiteUrl, uint _totalTickets)
      public
      onlyOwner()
      returns(uint)
    {
      uint eventID = idGenerator;
      events[eventID].description = _description;
      events[eventID].website = _websiteUrl;
      events[eventID].totalTickets = _totalTickets;
      events[eventID].isOpen = true;
      idGenerator += 1;

      emit LogEventAdded(_description, _websiteUrl, _totalTickets, eventID);
      return eventID;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */
    function readEvent(uint _id)
        view
        public
        returns(string memory description, string memory website, uint ticketsAvailable, uint sales, bool isOpen)
    {
        return (events[_id].description, events[_id].website, events[_id].totalTickets - events[_id].sales, events[_id].sales, events[_id].isOpen);
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _eventID, uint _purchasedTickets)
      public
      payable
    {
      require(events[_eventID].isOpen, "event is not open");
      uint toBePaid = PRICE_TICKET * _purchasedTickets;
      require(msg.value >= toBePaid, "not enough value sent");
      require(events[_eventID].totalTickets - events[_eventID].sales >= _purchasedTickets, "not enough tickets in stock");

      events[_eventID].buyers[msg.sender] += _purchasedTickets;
      events[_eventID].sales += _purchasedTickets;
      msg.sender.transfer(msg.value - toBePaid);
      emit LogBuyTickets(msg.sender, _eventID, _purchasedTickets);

    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _eventID)
      public
    {
      uint tickets = events[_eventID].buyers[msg.sender];
      require(tickets > 0, "no tickets to be refunded");
      events[_eventID].sales -= tickets;
      events[_eventID].buyers[msg.sender] = 0;
      msg.sender.transfer(tickets * PRICE_TICKET);
      emit LogGetRefund(msg.sender, _eventID, tickets);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _eventID)
      view
      public
      returns(uint)
    {
      return events[_eventID].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _eventID)
      public
      onlyOwner()
    {
      events[_eventID].isOpen = false;
      msg.sender.transfer(PRICE_TICKET * events[_eventID].sales);
      emit LogEndSale(msg.sender, PRICE_TICKET * events[_eventID].sales, _eventID);
    }
}
