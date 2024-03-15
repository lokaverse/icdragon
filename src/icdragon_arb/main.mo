import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Random "mo:base/Random";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Bool "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Int64 "mo:base/Int64";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat64 "mo:base/Nat64";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Time "mo:base/Time";
//import Tokens "mo:base/Tokens";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Char "mo:base/Char";
import { now } = "mo:base/Time";
import { abs } = "mo:base/Int";
import Account = "./account";
import { setTimer; cancelTimer; recurringTimer } = "mo:base/Timer";
import T "types";

import ICPLedger "canister:icp_ledger_canister";
//import ICPLedger "canister:icp_test";
import Eyes "canister:eyes";
//import CKBTC "canister:ckbtc_ledger";
//import LBTC "canister:lbtc";

shared ({ caller = owner }) actor class ICDragon({
  admin : Principal;
}) = this {
  //indexes

  private var siteAdmin : Principal = admin;
  private var dappsKey = "0xSet";

  stable var devPool : Text = "0x72c05D8a43082cD6b17b3Af2Fe09CcaF9D390408";
  stable var rewardPool : Principal = admin;
  private var ethtogwei : Float = 1000000000000000000;
  //@dev--users
  private stable var gameIndex = 0;
  private stable var firstGameStarted = false;
  private stable var transactionIndex = 0;
  private stable var betIndex = 0;
  private stable var ticketIndex = 0;
  private stable var pause = false : Bool;
  private stable var ticketPrice = 5000000000000000;
  private stable var eyesToken = false;
  private stable var eyesTokenDistribution = 10000000;
  private stable var eyesDays = 0;
  private stable var initialReward = 50000000000000000;
  private stable var initialBonus = 7500000000000000;
  private stable var timerId = 0;
  stable var nextTicketPrice = 5000000000000000;
  private stable var startHalvingTimeStamp : Int = 0;
  private stable var nextHalvingTimeStamp : Int = 0;
  private stable var developerFee = 0;
  private stable var pendingFee = 0;
  private stable var currentGameRolls = 0;
  private stable var houseETHVault = "";

  private var aliasHash = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);

  private var userTicketQuantityHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var ethTransactionHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var icpEthMapHash = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
  private var ethIcpMapHash = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
  private var userListBackup = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userFirstHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userDoubleRollQuantityHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userTicketPurchaseHash = HashMap.HashMap<Text, [T.PaidTicketPurchase]>(0, Text.equal, Text.hash);
  private var userTicketBookHash = HashMap.HashMap<Text, [T.TicketPurchase]>(0, Text.equal, Text.hash);
  private var userClaimableHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userClaimableBonusHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userClaimHistoryHash = HashMap.HashMap<Text, [T.ClaimHistory]>(0, Text.equal, Text.hash);
  private var userBetHistoryHash = HashMap.HashMap<Text, [T.Bet]>(0, Text.equal, Text.hash);
  var bonusPoolbyWallet = HashMap.HashMap<Text, [Nat]>(0, Text.equal, Text.hash);
  private var blistHash = HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);

  //@dev--variables and history
  var games = Buffer.Buffer<T.Game>(0);
  var ticketPurchaseHistory = Buffer.Buffer<T.TicketPurchase>(0);
  var betHistory = Buffer.Buffer<T.Bet>(0);

  //upgrade temp params
  stable var games_ : [T.Game] = []; // for upgrade
  stable var ticketPurchaseHistory_ : [T.TicketPurchase] = []; // for upgrade
  stable var betHistory_ : [T.Bet] = [];
  stable var currentHighestDice = 0;
  stable var currentHighestRoller = admin;
  stable var counter = 0;
  stable var rewardMilestone = 1000000000000000;
  stable var currentMilestone = 0;
  stable var currentTotalWins = 0;
  stable var currentHighestReward = 0;
  stable var currentReward = 0;
  stable var devThreshold = 100000000000000000;
  stable var totalClaimable = 0;

  stable var userTicketQuantityHash_ : [(Text, Nat)] = [];
  stable var ethTransactionHash_ : [(Text, Nat)] = [];
  stable var icpEthMapHash_ : [(Text, Text)] = [];
  stable var ethIcpMapHash_ : [(Text, Text)] = [];
  stable var blistHash_ : [(Text, Bool)] = [];
  stable var userFirstHash_ : [(Text, Nat)] = [];
  stable var userDoubleRollQuantityHash_ : [(Text, Nat)] = [];
  stable var userTicketPurchaseHash_ : [(Text, [T.PaidTicketPurchase])] = [];
  stable var userTicketBookHash_ : [(Text, [T.TicketPurchase])] = [];
  stable var userClaimableHash_ : [(Text, Nat)] = [];
  stable var userClaimableBonusHash_ : [(Text, Nat)] = [];
  stable var userClaimHistoryHash_ : [(Text, [T.ClaimHistory])] = [];
  stable var userBetHistoryHash_ : [(Text, [T.Bet])] = [];
  stable var timerStarted = false;
  stable var bonusPoolbyWallet_ : [(Text, [Nat])] = [];
  stable var aliasHash_ : [(Text, Text)] = [];
  stable var userListBackup_ : [(Text, Nat)] = [];

  //stable var transactionHash

  system func preupgrade() {
    games_ := Buffer.toArray<T.Game>(games);
    ticketPurchaseHistory_ := Buffer.toArray<T.TicketPurchase>(ticketPurchaseHistory);
    betHistory_ := Buffer.toArray<T.Bet>(betHistory);
    timerStarted := false;

    userTicketQuantityHash_ := Iter.toArray(userTicketQuantityHash.entries());
    ethTransactionHash_ := Iter.toArray(ethTransactionHash.entries());
    icpEthMapHash_ := Iter.toArray(icpEthMapHash.entries());
    ethIcpMapHash_ := Iter.toArray(ethIcpMapHash.entries());
    userFirstHash_ := Iter.toArray(userFirstHash.entries());
    userFirstHash_ := Iter.toArray(userFirstHash.entries());
    userDoubleRollQuantityHash_ := Iter.toArray(userDoubleRollQuantityHash.entries());
    userTicketPurchaseHash_ := Iter.toArray(userTicketPurchaseHash.entries());
    userTicketBookHash_ := Iter.toArray(userTicketBookHash.entries());
    userClaimableHash_ := Iter.toArray(userClaimableHash.entries());
    userClaimableBonusHash_ := Iter.toArray(userClaimableBonusHash.entries());
    userClaimHistoryHash_ := Iter.toArray(userClaimHistoryHash.entries());
    userBetHistoryHash_ := Iter.toArray(userBetHistoryHash.entries());
    bonusPoolbyWallet_ := Iter.toArray(bonusPoolbyWallet.entries());
    blistHash_ := Iter.toArray(blistHash.entries());
    aliasHash_ := Iter.toArray(aliasHash.entries());
    userListBackup_ := Iter.toArray(userListBackup.entries());

  };
  system func postupgrade() {
    games := Buffer.fromArray<T.Game>(games_);
    ticketPurchaseHistory := Buffer.fromArray<T.TicketPurchase>(ticketPurchaseHistory_);
    betHistory := Buffer.fromArray<T.Bet>(betHistory_);

    userTicketQuantityHash := HashMap.fromIter<Text, Nat>(userTicketQuantityHash_.vals(), 1, Text.equal, Text.hash);
    ethTransactionHash := HashMap.fromIter<Text, Nat>(ethTransactionHash_.vals(), 1, Text.equal, Text.hash);
    icpEthMapHash := HashMap.fromIter<Text, Text>(icpEthMapHash_.vals(), 1, Text.equal, Text.hash);
    ethIcpMapHash := HashMap.fromIter<Text, Text>(ethIcpMapHash_.vals(), 1, Text.equal, Text.hash);
    userFirstHash := HashMap.fromIter<Text, Nat>(userFirstHash_.vals(), 1, Text.equal, Text.hash);
    userDoubleRollQuantityHash := HashMap.fromIter<Text, Nat>(userDoubleRollQuantityHash_.vals(), 1, Text.equal, Text.hash);
    userTicketPurchaseHash := HashMap.fromIter<Text, [T.PaidTicketPurchase]>(userTicketPurchaseHash_.vals(), 1, Text.equal, Text.hash);
    userTicketBookHash := HashMap.fromIter<Text, [T.TicketPurchase]>(userTicketBookHash_.vals(), 1, Text.equal, Text.hash);
    userClaimableHash := HashMap.fromIter<Text, Nat>(userClaimableHash_.vals(), 1, Text.equal, Text.hash);
    userClaimableBonusHash := HashMap.fromIter<Text, Nat>(userClaimableBonusHash_.vals(), 1, Text.equal, Text.hash);
    userClaimHistoryHash := HashMap.fromIter<Text, [T.ClaimHistory]>(userClaimHistoryHash_.vals(), 1, Text.equal, Text.hash);
    userBetHistoryHash := HashMap.fromIter<Text, [T.Bet]>(userBetHistoryHash_.vals(), 1, Text.equal, Text.hash);
    bonusPoolbyWallet := HashMap.fromIter<Text, [Nat]>(bonusPoolbyWallet_.vals(), 1, Text.equal, Text.hash);
    blistHash := HashMap.fromIter<Text, Bool>(blistHash_.vals(), 1, Text.equal, Text.hash);
    aliasHash := HashMap.fromIter<Text, Text>(aliasHash_.vals(), 1, Text.equal, Text.hash);
    userListBackup := HashMap.fromIter<Text, Nat>(userListBackup_.vals(), 1, Text.equal, Text.hash);
  };

  public query (message) func getTimeNow() : async Int {
    assert (_isAdmin(message.caller));
    let tm = now() / 1000000;
    return tm;
  };

  public shared (message) func getEyesWalletDist() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    assert (_isNotPaused());
    var it_ = Iter.toArray(userFirstHash.entries());
    var al_ = Iter.toArray(aliasHash.entries());
    var ct_ = 0;
    var eyesDist_ : [(Text, Nat)] = [];
    for (n in it_.vals()) {

      var t_ = n.0;
      var f = Array.find<(Text, Text)>(al_, func x = x.1 == t_);
      switch (f) {
        case (?dd) {
          //t_ := dd.0;
        };
        case (null) {

        };
      };

      let balance_ = await Eyes.icrc1_balance_of({
        owner = Principal.fromText(t_);
        subaccount = null;
      });
      if (balance_ > 0) {
        ct_ += 1;
        eyesDist_ := Array.append(eyesDist_, [(t_, balance_)]);
        //var f = Array.find<(Text, Text)>(al_, func x = x.1 == t_);
        //if (f != null) ct_ += 1;
        //var t = await transferEyesToken(Principal.fromText(t_), 2);
      };

    };
    return eyesDist_;
  };

  public query (message) func getETHVault() : async Text {
    return houseETHVault;
  };

  public query (message) func getTicketPurchaseHash() : async [(Text, [T.PaidTicketPurchase])] {
    //assert (_isAdmin(message.caller));
    let a_ = Iter.toArray(userTicketPurchaseHash.entries());
    return a_;
  };

  public query (message) func getTicketPurchaseHashByWallet(p : Text) : async ?[T.PaidTicketPurchase] {
    assert (_isAdmin(message.caller));
    //let a_ = Iter.toArray(userTicketPurchaseHash.entries());
    let hash_ = userTicketPurchaseHash.get(p);

    return hash_;
  };

  /* MIGRATION FUNCTIONS */ ////////////////////////////////////////////
  public shared (message) func createBaseAddress() : async () {
    assert (_isAdmin(message.caller));
    var temp = Iter.toArray(userFirstHash.entries());
    userListBackup := HashMap.fromIter<Text, Nat>(temp.vals(), 1, Text.equal, Text.hash);
  };

  public shared (message) func isMigrateable(p : Text) : async T.Migrateable {
    if (Principal.toText(message.caller) == p) return #none(1);
    switch (userListBackup.get(p)) {
      case (?n) {
        return #ok(await getUserDataByWallet(p));
      };
      case (null) {
        return #none(1);
      };
    };
  };

  public shared (message) func getUserBets(p_ : Text) : async {
    #none : Nat;
    #ok : [T.Bet];
  } {
    assert (_isAdmin(message.caller));
    switch (userBetHistoryHash.get(p_)) {
      case (?x) {
        return #ok(x);
      };
      case (null) {
        return #none(1);
      };
    };
  };

  func _isMigrateable(p : Text) : async T.Migrateable {
    switch (userListBackup.get(p)) {
      case (?n) {
        return #ok(await getUserDataByWallet(p));
      };
      case (null) {
        return #none(1);
      };
    };
  };

  public shared (message) func getList() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    return Iter.toArray(userListBackup.entries());
  };

  public shared (message) func deleteAlias(p : Text) : async Bool {
    assert (_isAdmin(message.caller));
    aliasHash.delete(p);
    true;
  };
  public shared (message) func migrate(p : Text) : async Bool {
    if (Principal.toText(message.caller) == p) return false;
    switch (userListBackup.get(p)) {
      case (?n) {
        var a = await addAlias(p, Principal.toText(message.caller));
        var b = userListBackup.delete(p);
        return a;
      };
      case (null) {
        return false;
      };
    };

  };

  func addAlias(old_ : Text, new_ : Text) : async Bool {
    switch (userListBackup.get(old_)) {
      case (?n) {
        var newAddr = new_;
        switch (aliasHash.get(newAddr)) {
          case (?a) {
            return false;
          };
          case (null) {
            aliasHash.put(newAddr, old_);
            return true;
          };
        };

      };
      case (null) {
        return false;
      };
    };

  };

  public shared (message) func getAliasP(t : Text) : async Principal {
    var p = Principal.fromText(t);
    switch (aliasHash.get(Principal.toText(p))) {
      case (?a) {
        return Principal.fromText(a);
      };
      case (null) {
        //aliasHash.put(newAddr,old_);
        return p;
      };
    };

  };

  func getAlias(p : Principal) : Principal {
    switch (aliasHash.get(Principal.toText(p))) {
      case (?a) {
        return Principal.fromText(a);
      };
      case (null) {
        //aliasHash.put(newAddr,old_);
        return p;
      };
    };

  };
  //END OF MIGRATION FUNCTIONS ///////////////////////////////////

  public query (message) func getCounter() : async Nat {
    assert (_isAdmin(message.caller));
    return counter;
  };

  public query (message) func getNextHalving() : async Int {
    return nextHalvingTimeStamp;
  };

  public shared (message) func alterHalving(a : Int) : async Int {
    assert (_isAdmin(message.caller));
    nextHalvingTimeStamp := a;
    return nextHalvingTimeStamp;
  };

  //public shared (message) func migrate(old_ : Text, new_ : Text) : async () {
  //change value in
  /*

    if user exist in userList Backup

private var userTicketQuantityHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userListBackup = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userFirstHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userDoubleRollQuantityHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userTicketPurchaseHash = HashMap.HashMap<Text, [T.PaidTicketPurchase]>(0, Text.equal, Text.hash);
  private var userClaimableHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userClaimableBonusHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userClaimHistoryHash = HashMap.HashMap<Text, [T.ClaimHistory]>(0, Text.equal, Text.hash);
  private var userBetHistoryHash = HashMap.HashMap<Text, [T.Bet]>(0, Text.equal, Text.hash);
  var bonusPoolbyWallet = HashMap.HashMap<Text, [Nat]>(0, Text.equal, Text.hash);
  private var blistHash = HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);
      */

  //@dev timers initialization, must be called every canister upgrades
  public shared (message) func startHalving(n : Int) : async Nat {

    assert (_isAdmin(message.caller));
    cancelTimer(timerId);
    startHalvingTimeStamp := n;
    nextHalvingTimeStamp := startHalvingTimeStamp;
    // Debug.print("stamp " #Int.toText(nextTimeStamp));
    if (startHalvingTimeStamp == 0) return 0;
    timerId := recurringTimer(
      #seconds(1),
      func() : async () {
        if (counter < 100) { counter += 10 } else { counter := 0 };
        let time_ = now() / 1000000;
        if (time_ >= nextHalvingTimeStamp) {
          //var n_ = now() / 1000000;
          nextHalvingTimeStamp := nextHalvingTimeStamp + (24 * 60 * 60 * 60 * 1000);
          eyesTokenDistribution := eyesTokenDistribution / 2;
          //counter := 200;
          //let res = halving();

          //schedulerSecondsInterval := 24 * 60 * 60;
          //cancelTimer(timerId);
          //halvingExecution();
          //timerId := halving();

        };
      },
    );

    timerId;
  };

  public shared (message) func resumeHalving() : async Nat {
    assert (_isAdmin(message.caller));
    cancelTimer(timerId);
    nextHalvingTimeStamp := startHalvingTimeStamp;
    if (startHalvingTimeStamp == 0) return 0;
    timerId := recurringTimer(
      #seconds(1),
      func() : async () {
        if (counter < 100) { counter += 10 } else { counter := 0 };
        let time_ = now() / 1000000;
        if (time_ >= nextHalvingTimeStamp) {
          nextHalvingTimeStamp := nextHalvingTimeStamp + (24 * 60 * 60 * 60 * 1000);
          eyesTokenDistribution := eyesTokenDistribution / 2;
        };
      },
    );
    timerId;
  };

  //timer : halving every 10 days
  func halving() : Nat {
    //cancelTimer(timerId);
    var n = recurringTimer(
      #seconds(24 * 60 * 60),
      func() : async () {
        if (counter < 300) { counter += 1 } else { counter := 0 };
        halvingExecution();
      },
    );
    timerStarted := true;
    timerId := n;
    return n;
  };

  func halvingExecution() {
    eyesDays += 1;
    if (eyesToken and eyesDays == 10) {
      eyesTokenDistribution := eyesTokenDistribution / 2;
      eyesDays := 0;
      var n_ = now() / 1000000;
      nextHalvingTimeStamp := n_ + (24 * 60 * 60 * 10 * 1000);
      //if(EyesDays==30)EyesToken:=false;
    };
  };

  public shared (message) func blacklist(p : Text) : async Bool {
    assert (_isAdmin(message.caller));
    blistHash.put(p, true);
    true;
  };

  public query (message) func getUserTicketList() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    return Iter.toArray(userTicketQuantityHash.entries());
  };

  public query (message) func getHalving() : async Nat {
    return eyesDays;
  };

  public query (message) func whoCall() : async Principal {
    return message.caller;
  };

  public shared (message) func setHalving(d : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    eyesDays := d;
    return eyesDays;
  };

  public shared (message) func setEthVault(d : Text) : async Text {
    assert (_isAdmin(message.caller));
    houseETHVault := d;
    return d;
  };

  public query (message) func getTimerStatus() : async Bool {
    return timerStarted;
  };

  private func natToFloat(nat_ : Nat) : Float {
    let toNat64_ = Nat64.fromNat(nat_);
    let toInt64_ = Int64.fromNat64(toNat64_);
    let amountFloat_ = Float.fromInt64(toInt64_);
    return amountFloat_;
  };

  func _isAdmin(p : Principal) : Bool {
    return (p == siteAdmin);
  };

  func _isApp(key : Text) : Bool {
    return (key == dappsKey);
  };

  func _isNotPaused() : Bool {
    if (pause) return false;
    true;
  };

  public query func isNotPaused() : async Bool {
    if (pause) return false;
    true;
  };

  public shared (message) func setDevPool(vault_ : Text) : async Text {
    assert (_isAdmin(message.caller));
    devPool := vault_;
    vault_;
  };

  public shared (message) func setRewardPool(vault_ : Principal) : async Principal {
    assert (_isAdmin(message.caller));
    rewardPool := vault_;
    vault_;
  };

  public shared (message) func setEyesToken(active_ : Bool) : async Bool {
    assert (_isAdmin(message.caller));
    eyesToken := active_;
    eyesToken;
  };

  public query (message) func getDevPool() : async Text {
    devPool;
  };

  public query (message) func getRewardPool() : async Principal {
    rewardPool;
  };

  public query (message) func getTicketPrice() : async Nat {
    ticketPrice;
  };

  public query (message) func getNextTicketPrice() : async Nat {
    nextTicketPrice;
  };

  public shared (message) func setTicketPrice(price_ : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    ticketPrice := price_;
    nextTicketPrice := price_;
    ticketPrice;
  };

  public query (message) func getCurrentReward() : async Nat {
    //assert (_isAdmin(message.caller));
    let game_ = games.get(gameIndex);
    game_.reward;
  };

  public query (message) func getCurrentBonus() : async Nat {
    //assert (_isAdmin(message.caller));
    let game_ = games.get(gameIndex);
    game_.bonus;
  };

  public query (message) func getEyesDistribution() : async Nat {
    eyesTokenDistribution;
  };

  public shared (message) func setNextTicketPrice(price_ : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    nextTicketPrice := price_;
    price_;
  };

  public shared (message) func setAdmin(admin_ : Principal) : async Principal {
    assert (_isAdmin(message.caller));
    siteAdmin := admin_;
    siteAdmin;
  };

  public query (message) func getCurrentIndex() : async Nat {
    gameIndex;
  };

  public shared (message) func getUserByWallet(p_ : Text) : async T.UserV2 {
    assert (_isAdmin(message.caller));
    return await getUserDataByWallet(p_);
  };

  func getUserDataByWallet(p__ : Text) : async T.UserV2 {
    var p_ = Principal.toText(getAlias(Principal.fromText(p__)));
    var claimHistory_ = userClaimHistoryHash.get(p_);
    var claimHistory : [T.ClaimHistory] = [];
    switch (claimHistory_) {
      case (?c) {
        claimHistory := c;
      };
      case (null) {
        claimHistory := [];
      };
    };
    var claimable_ = userClaimableHash.get(p_);
    var claimable : Nat = 0;
    switch (claimable_) {
      case (?c) {
        claimable := c;
      };
      case (null) {
        claimable := 0;
      };
    };
    var purchase_ = userTicketPurchaseHash.get(p_);
    var purchase : [T.PaidTicketPurchase] = [];
    switch (purchase_) {
      case (?p) {
        purchase := p;
      };
      case (null) {
        //Debug.print("no purchase yet");
      };
    };
    var bets_ = userBetHistoryHash.get(p_);
    var bets : [T.Bet] = [];
    switch (bets_) {
      case (?b) {
        bets := b;
      };
      case (null) {
        //Debug.print("no bet yet");
      };
    };
    var remaining : Nat = 0;
    switch (userTicketQuantityHash.get(p_)) {
      case (?x) {
        remaining := x;
      };
      case (null) {
        remaining := 0;
        userTicketQuantityHash.put(p_, 0);
      };
    };
    var doubleRollRemaining : Nat = 0;
    switch (userDoubleRollQuantityHash.get(p_)) {
      case (?x) {
        doubleRollRemaining := x;
      };
      case (null) {
        doubleRollRemaining := 0;
        userDoubleRollQuantityHash.put(p_, 0);
      };
    };

    var bonusReward_ = 0;
    let userReward_ = userClaimableBonusHash.get(p_);
    switch (userReward_) {
      case (?r) {
        bonusReward_ := r;
      };
      case (null) {
        userClaimableBonusHash.put(p_, 0);
      };
    };

    let userData_ : T.UserV2 = {
      walletAddress = Principal.fromText(p_);
      claimableReward = claimable;
      claimHistory = claimHistory;
      ethWalletAddress = getCallerEth(Principal.fromText(p_));
      purchaseHistory = purchase;
      gameHistory = bets;
      availableDiceRoll = remaining + doubleRollRemaining;
      claimableBonus = bonusReward_;
      alias = getAlias(Principal.fromText(p_));
    };
    //return user data
    userData_;
  };

  public shared (message) func getUserData() : async T.UserV2 {
    var p = getAlias(message.caller);
    var claimHistory_ = userClaimHistoryHash.get(Principal.toText(p));
    var claimHistory : [T.ClaimHistory] = [];
    switch (claimHistory_) {
      case (?c) {
        claimHistory := c;
      };
      case (null) {
        claimHistory := [];
      };
    };
    var claimable_ = userClaimableHash.get(Principal.toText(p));
    var claimable : Nat = 0;
    switch (claimable_) {
      case (?c) {
        claimable := c;
      };
      case (null) {
        claimable := 0;
      };
    };
    var purchase_ = userTicketPurchaseHash.get(Principal.toText(p));
    var purchase : [T.PaidTicketPurchase] = [];
    switch (purchase_) {
      case (?p) {
        purchase := p;
      };
      case (null) {
        //Debug.print("no purchase yet");
      };
    };
    var bets_ = userBetHistoryHash.get(Principal.toText(p));
    var bets : [T.Bet] = [];
    switch (bets_) {
      case (?b) {
        bets := b;
      };
      case (null) {
        //Debug.print("no bet yet");
      };
    };
    var remaining : Nat = 0;
    switch (userTicketQuantityHash.get(Principal.toText(p))) {
      case (?x) {
        remaining := x;
      };
      case (null) {
        remaining := 0;
        userTicketQuantityHash.put(Principal.toText(p), 0);
      };
    };
    var doubleRollRemaining : Nat = 0;
    switch (userDoubleRollQuantityHash.get(Principal.toText(p))) {
      case (?x) {
        doubleRollRemaining := x;
      };
      case (null) {
        doubleRollRemaining := 0;
        userDoubleRollQuantityHash.put(Principal.toText(p), 0);
      };
    };

    var bonusReward_ = 0;
    let userReward_ = userClaimableBonusHash.get(Principal.toText(p));
    switch (userReward_) {
      case (?r) {
        bonusReward_ := r;
      };
      case (null) {
        userClaimableBonusHash.put(Principal.toText(p), 0);
      };
    };

    let userData_ : T.UserV2 = {
      walletAddress = message.caller;
      ethWalletAddress = getCallerEth(message.caller);
      claimableReward = claimable;
      claimHistory = claimHistory;
      purchaseHistory = purchase;
      gameHistory = bets;
      availableDiceRoll = remaining + doubleRollRemaining;
      claimableBonus = bonusReward_;
      alias = getAlias(message.caller);
    };
    //return user data
    userData_;
  };

  public query (message) func getCurrentGame() : async T.GameCheck {
    //return game data
    if (firstGameStarted == false) return #none;
    let currentGame_ = games.get(gameIndex);
    Debug.print("current game reward " #Nat.toText(currentGame_.reward));

    let game_ : T.CurrentGame = {
      bets = currentGame_.bets;
      id = currentGame_.id;
      reward = currentGame_.reward;
      reward_text = Nat.toText(currentGame_.reward);
      time_created = currentGame_.time_created;
      time_ended = currentGame_.time_ended;
      winner = getCallerEth(currentGame_.winner);
      bonus = currentGame_.bonus;
      highestRoller = getCallerEth(currentHighestRoller);
      highestDice = currentHighestDice;
      highestReward = currentHighestReward;
      totalReward = currentReward;
      users = userFirstHash.size();
      houseVault = houseETHVault;
    };
    #ok(game_);
  };
  public shared (message) func calculateRewards() : async Nat {
    assert (_isAdmin(message.caller));
    var reward_ = 0;
    currentReward := 0;
    currentHighestReward := 0;
    Buffer.iterate<T.Game>(
      games,
      func(game) {
        if (game.id < gameIndex) {
          if (game.reward > currentHighestReward) currentHighestReward := game.reward;
          reward_ += game.reward + game.bonus;
        };

      },
    );
    currentReward := reward_;
    reward_;
  };

  public query (message) func getGameByIndex(id_ : Nat) : async T.GameCheck {
    //return game data
    if (firstGameStarted == false) return #none;
    let currentGame_ = games.get(id_);
    Debug.print("current game reward " #Nat.toText(currentGame_.reward));

    let game_ : T.CurrentGame = {
      bets = currentGame_.bets;
      id = currentGame_.id;
      reward = currentGame_.reward;
      reward_text = Nat.toText(currentGame_.reward);
      time_created = currentGame_.time_created;
      time_ended = currentGame_.time_ended;
      winner = getCallerEth(currentGame_.winner);
      bonus = currentGame_.bonus;
      highestRoller = getCallerEth(currentHighestRoller);
      highestDice = currentHighestDice;
      highestReward = currentHighestReward;
      totalReward = currentReward;
      users = userFirstHash.size();
      houseVault = houseETHVault;
    };
    #ok(game_);
  };

  public shared (message) func pauseCanister(pause_ : Bool) : async Bool {
    assert (_isAdmin(message.caller));
    pause := pause_;
    pause_;
  };

  func _isHashNotUsed(h : Text) : Bool {
    var hash_ = ethTransactionHash.get(h);
    switch (hash_) {
      case (?n) {
        return false;
      };
      case (null) {
        return true;
      };
    };
    true;
  };

  func getCallerEth(p : Principal) : Text {
    var ethAddress = icpEthMapHash.get(Principal.toText(p));
    switch (ethAddress) {
      case (?e) {
        return e;
      };
      case (null) {
        return "none";
      };
    };
  };

  func getCallerICP(e : Text) : Text {
    var icpAddress = ethIcpMapHash.get(e);
    switch (icpAddress) {
      case (?e) {
        return e;
      };
      case (null) {
        return "none";
      };
    };
  };

  //@dev--to buy ticket, user should call approve function on icrc2
  public shared (message) func book_ticket(quantity_ : Nat) : async Nat {

    assert (_isNotBlacklisted(message.caller));
    assert (_isNotPaused());
    let ticketIndex_ = ticketIndex;
    let ticketBook_ : T.TicketPurchase = {
      id = ticketIndex;
      walletAddress = ?message.caller;
      time = now();
      quantity = quantity_;
      totalPrice = quantity_ * ticketPrice;
      var icp_index = "none";
    };
    ticketPurchaseHistory.add(ticketBook_);
    let userBooks_ = userTicketBookHash.get(Principal.toText(message.caller));
    switch (userBooks_) {
      case (?x) {
        userTicketBookHash.put(Principal.toText(message.caller), Array.append<T.TicketPurchase>(x, [ticketBook_]));
      };
      case (null) {
        userTicketBookHash.put(Principal.toText(message.caller), [ticketBook_]);
      };
    };
    // let ticketBookNow_ = ticketPurchaseHistory.get(ticketIndex);
    ticketIndex += 1;
    ticketIndex_;
  };

  func sendCommission(ethAddress : Text, q : Nat, amt : Nat) : async Nat {
    let XDragon = actor ("a7gxj-tiaaa-aaaam-acdwa-cai") : actor {
      addTicketCommission : (ethAddress : Text, q : Nat, amt : Nat) -> async Nat;
    };
    let result = await XDragon.addTicketCommission(ethAddress, q, amt); //"(record {subaccount=null;})"
    result;
  };

  public shared (message) func buy_ticket(quantity_ : Nat, hash_ : Text, index_ : Nat) : async T.BookTicketResult {
    //set teh variable
    var p = getAlias(message.caller);
    assert (_isNotBlacklisted(p));
    assert (_isNotBlacklisted(message.caller));
    assert (_isNotPaused());
    assert (_isHashNotUsed(hash_));
    var ethAddr_ = getCallerEth(message.caller);
    assert (ethAddr_ != "none");
    var ethAddr = getCallerEth(message.caller);
    var totalAmount = Nat.toText(quantity_ * ticketPrice);
    // var totalAmount = Nat.toText(100000000000000);
    var decoded_text = "";
    //https outcall check hash parameter hash, from, to, amount
    var attmpt = 0;
    label chk while (decoded_text == "" or decoded_text == "reject") {
      let id_ = Int.toText(now()) #hash_;
      let url = "https://api.dragoneyes.xyz/checktransactionhash?id=" #id_ # "&hash=" #hash_ # "&sender=" #ethAddr_ # "&receiver=" #houseETHVault # "&q=" #totalAmount;
      decoded_text := await checkTransaction(url);
      if (decoded_text != "reject" and decoded_text != "") {
        break chk;
      };
      attmpt += 1;
      if (attmpt > 3) {
        break chk;
      };
    };
    if (decoded_text == "reject") {
      return #transferFailed("transfer executed but failed to confirm");
    };
    var isValid = Text.contains(decoded_text, #text "success");
    if (isValid) {

      let ticketBookNow_ = ticketPurchaseHistory.get(index_);
      ticketBookNow_.icp_index := hash_;

      let ticketBookPaid_ : T.PaidTicketPurchase = {
        id = index_;
        walletAddress = ?message.caller;
        time = now();
        quantity = quantity_;
        totalPrice = quantity_ * ticketPrice;
        icp_index = hash_;
      };

      //write to users hash, both history and remaining ticket hash
      ethTransactionHash.put(hash_, quantity_);
      let userTickets_ = userTicketPurchaseHash.get(Principal.toText(p));
      switch (userTickets_) {
        case (?x) {
          userTicketPurchaseHash.put(Principal.toText(p), Array.append<T.PaidTicketPurchase>(x, [ticketBookPaid_]));
        };
        case (null) {
          userTicketPurchaseHash.put(Principal.toText(p), [ticketBookPaid_]);
        };
      };
      let userRemainingTicket_ = userTicketQuantityHash.get(Principal.toText(p));
      switch (userRemainingTicket_) {
        case (?x) {
          userTicketQuantityHash.put(Principal.toText(p), x +quantity_);
        };
        case (null) {
          userTicketQuantityHash.put(Principal.toText(p), quantity_);
        };
      };

      if (quantity_ >= 5) {
        var n = await notifyDiscord("Here comes " #ethAddr # " with " #Nat.toText(quantity_) # " ticket(s)!%0AGo get that Dragon Eyes, warrior!!");

      };
      var commission = ((quantity_ * ticketPrice) * 5) / 100;
      try {
        var a = await sendCommission(ethAddr, quantity_, commission);
      } catch (e) {

      };
      return #success(quantity_);
    } else {
      var failed = Text.contains(decoded_text, #text "failed");
      if (failed) {
        return #transferFailed("transaction invalid");
      } else {
        return #transferFailed("hash not found " #hash_ # " " #totalAmount # " " #ethAddr_ # " " #houseETHVault);
      };
    };

    //assert(transIndex_!=0);
    //write to ticket book history

  };

  //@dev-- called to start game for the first time by admin
  public shared (message) func firstGame() : async Bool {
    assert (_isAdmin(message.caller));
    ticketPrice := 5000000000000000;
    initialReward := ticketPrice * 10;
    initialBonus := 7500000000000000;
    developerFee += 0;

    assert (gameIndex == 0);
    assert (firstGameStarted == false);
    Debug.print("Starting new game ");
    let newGame : T.Game = {
      id = gameIndex;
      var totalBet = 0;
      var winner = siteAdmin;
      time_created = now();
      var time_ended = 0;
      var reward = initialReward;
      var bets = [];
      var bonus = initialBonus;
      var bonus_winner = siteAdmin;
      var bonus_claimed = false;
    };
    games.add(newGame);
    firstGameStarted := true;
    let allgame = games.size();
    true;
  };

  public shared (message) func sg() : async Nat {
    assert (_isAdmin(message.caller));
    startNewGame();
    return gameIndex;
  };

  public query (message) func getTotalClaimable() : async Nat {
    return totalClaimable;
  };

  func getHouseETHBalance() : async Nat {
    let id_ = Int.toText(now()) # "housebalance";

    let url = "https://api.dragoneyes.xyz/getHouseETHBalance?id=" #id_;

    let decoded_text = await send_http(url);
    switch (Nat.fromText(decoded_text)) {
      case (?n) {
        //return decoded_text;
        return n;
      };
      case (null) {
        return 0;
      };
    };
  };

  func getHouseETHBalanceText() : async Text {
    let id_ = Int.toText(now()) # "housebalance";

    let url = "https://api.dragoneyes.xyz/getHouseETHBalance";

    let decoded_text = await send_http(url);
    return decoded_text;
  };

  public shared (message) func getCurrentThreshold() : async Text {
    assert (_isAdmin(message.caller));
    var walletBalance_ = await getHouseETHBalance();

    totalClaimable := _calculateUnclaimed();
    var remT = remainingTickets();
    var tp = remT * ticketPrice;
    walletBalance_ := walletBalance_ - tp;
    var finalThreshold = devThreshold + totalClaimable;
    var th_ = "" #Nat.toText(finalThreshold) # " (th : " #Nat.toText(devThreshold) # ", ticket : " #Nat.toText(tp) # "(" #Nat.toText(remT) # "), cl : " #Nat.toText(totalClaimable) # ") || B : " #Nat.toText(walletBalance_) # " (" #Nat.toText(walletBalance_ + tp) # ")";
    return th_;
  };

  func startNewGame() {
    gameIndex += 1;
    ticketPrice := nextTicketPrice;
    currentHighestRoller := siteAdmin;
    initialReward := ticketPrice * 8;
    currentMilestone := rewardMilestone;
    currentHighestDice := 0;
    currentGameRolls := 0;
    pendingFee := 0;
    let newGame : T.Game = {
      id = gameIndex;
      var totalBet = 0;
      var winner = siteAdmin;
      time_created = now();
      var time_ended = 0;
      var reward = initialReward;
      var bets = [];
      var bonus = ticketPrice + ticketPrice / 2;
      var bonus_winner = siteAdmin;
      var bonus_claimed = false;
    };
    games.add(newGame);

  };

  func roll() : async Nat8 {
    var count_ = 0;
    var check : Nat8 = 0;
    while (check == 0 and count_ < 5) {
      let random = Random.Finite(await Random.blob());
      let dice_ = random.range(20);
      switch (dice_) {
        case (?x) {
          var r_ = Nat.rem(x, 6) +1;
          check := 1;
          return Nat8.fromNat(r_);
        };
        case (null) {
          count_ += 1;
          //return 0;
        };
      };
    };
    return 0;
  };

  public shared (message) func testRoll() : async Nat8 {
    assert (_isAdmin(message.caller));
    var count_ = 0;
    var check : Nat8 = 0;
    while (check == 0 and count_ < 5) {
      let random = Random.Finite(await Random.blob());
      let dice_ = random.range(20);
      switch (dice_) {
        case (?x) {
          var r_ = Nat.rem(x, 6) +1;
          check := 1;
          return Nat8.fromNat(r_);
        };
        case (null) {
          count_ += 1;
          //return 0;
        };
      };
    };
    return 0;

  };

  public query (message) func getHashDoubleRoll(t : Text) : async ?Nat {
    return let u = userDoubleRollQuantityHash.get(t);
  };

  public query (message) func getHashTicket(t : Text) : async ?Nat {
    return let u = userTicketQuantityHash.get(t);
  };

  public shared (message) func sendToDiscord(msg : Text) : async Bool {
    assert (_isAdmin(message.caller));
    let id_ = Int.toText(now());
    let message_ = Text.replace(msg, #char ' ', "%20");
    let url = "https://api.dragoneyes.xyz/sendDiscord?id=" #id_ # "&message=" #message_;

    let decoded_text = await send_http(url);
    true;
  };

  func notifyDiscord(msg : Text) : async Bool {
    //return true;
    let id_ = Int.toText(now());
    let message = Text.replace(msg, #char ' ', "%20");
    let url = "https://api.dragoneyes.xyz/sendDiscord?id=" #id_ # "&message=" #message;

    let decoded_text = await send_http(url);
    true;
  };

  /*public shared (message) func initialEyesTokenCheck() : async Nat {
    assert (_isNotPaused());
    var p = getAlias(message.caller);
    switch (userFirstHash.get(Principal.toText(p))) {
      case (?x) {

        return 0;
      };
      case (null) {

        if (eyesToken) {
          let res_ = await transferEyesToken(message.caller, 2);
          switch (res_) {
            case (#success(n)) {
              userFirstHash.put(Principal.toText(p), 0);
              return eyesTokenDistribution * 2;
            };
            case (#error(x)) {
              return 0;
            };
          };

        };
      };
    };
    0;
  };*/

  public shared (message) func initialMap(eth_ : Text) : async Nat {
    assert (_isNotPaused());
    var p = getAlias(message.caller);
    switch (userFirstHash.get(Principal.toText(message.caller))) {
      case (?x) {};
      case (null) {
        userFirstHash.put(Principal.toText(message.caller), 0);
      };
    };

    var ethAddress = icpEthMapHash.get(Principal.toText(message.caller));
    var e_ = "";
    switch (ethAddress) {
      case (?e) {
        //return 0;
      };
      case (null) {
        icpEthMapHash.put(Principal.toText(message.caller), eth_);
        return 0;
      };
    };
    var icpAddress = ethIcpMapHash.get(eth_);
    switch (icpAddress) {
      case (?e) {

        return 0;
      };
      case (null) {
        ethIcpMapHash.put(eth_, Principal.toText(message.caller));
        return 0;
      };
    };
    0;
  };

  public shared (message) func getP(p : Text) : async Text {
    assert (_isAdmin(message.caller));
    return getCallerICP(p);
  };

  public shared (message) func addTicket(p : Text, q : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    var pp = getCallerICP(p);
    userTicketQuantityHash.put(pp, q);
    return q;
  };

  public shared (message) func deleteTicket(p : Text) : async Nat {
    assert (_isAdmin(message.caller));
    var pp = getCallerICP(p);
    userTicketQuantityHash.delete(p);
    return 1;
  };

  public shared (message) func syncFirstHash() : async (Text, Nat) {
    assert (_isAdmin(message.caller));
    assert (_isNotPaused());
    var it_ = Iter.toArray(userFirstHash.entries());
    var al_ = Iter.toArray(aliasHash.entries());
    var ct_ = 0;
    for (n in it_.vals()) {

      var t_ = n.0;
      var f = Array.find<(Text, Text)>(al_, func x = x.1 == t_);
      switch (f) {
        case (?dd) {
          t_ := dd.0;
        };
        case (null) {

        };
      };

      let transferResult = await Eyes.icrc1_balance_of({
        owner = Principal.fromText(t_);
        subaccount = null;
      });
      if (transferResult <= 0) {
        ct_ += 1;
        //var f = Array.find<(Text, Text)>(al_, func x = x.1 == t_);
        //if (f != null) ct_ += 1;
        //var t = await transferEyesToken(Principal.fromText(t_), 2);
      };

    };
    return ("y", ct_);

  };

  public shared (message) func manualUpdateEyes(p_ : Text) : async Nat {

    var it_ = Iter.toArray(userFirstHash.entries());
    for (n in it_.vals()) {

    };
    assert (_isAdmin(message.caller));
    assert (_isNotPaused());
    var p = getAlias(Principal.fromText(p_));
    userFirstHash.delete(p_);
    //userFirstHash.delete(Principal.toText(message.caller));
    switch (userFirstHash.get(Principal.toText(p))) {
      case (?x) {

        return 0;
      };
      case (null) {

        if (eyesToken) {
          let res_ = await transferEyesToken(p, 2);
          switch (res_) {
            case (#success(a)) {
              userFirstHash.put(Principal.toText(p), 0);
              return a;
            };
            case (#error(x)) {
              return 0;
            };
          };
          return 0;
        };
      };
    };
    0;
  };
  func _isBlacklisted(p : Principal) : Bool {
    switch (blistHash.get(Principal.toText(p))) {
      case (?a) {
        return a;
      };
      case (null) {
        return false;
      };
    };
  };

  func _isNotBlacklisted(p : Principal) : Bool {
    if (_isBlacklisted(p)) {
      return false;
    } else {
      return true;
    };
  };

  public shared (message) func setCurrentMilestone(i_ : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    currentMilestone := i_;
    return currentMilestone;
  };

  public query (message) func currentDevFee() : async Nat {
    assert (_isAdmin(message.caller));
    return developerFee;
  };

  public shared (message) func setDevThreshold(n_ : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    devThreshold := n_;
    n_;
  };

  public shared (message) func addB(p_ : Text, quantity_ : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    var p = getCallerICP(p_);
    let bon_ = userClaimableHash.get(p);
    var tots_ = quantity_;
    switch (bon_) {
      case (?x) {
        userClaimableHash.put(p, x +quantity_);
        //userTicketQuantityHash.put(p, 0);
        tots_ := x +quantity_;
      };
      case (null) {
        userClaimableHash.put(p, quantity_);
      };
    };
    tots_;
  };

  public shared (message) func roll_dice(game_id : Nat) : async T.DiceResult {
    //get game dataassert
    assert (_isNotPaused());
    assert (_isNotBlacklisted(message.caller));
    var p = getAlias(message.caller);
    assert (_isNotBlacklisted(p));
    var game_ = games.get(game_id);
    let gameBets_ = game_.bets;
    var remaining_ : Nat = 0;
    var doubleRollRemaining_ : Nat = 0;
    var ethAddr = getCallerEth(message.caller);
    Debug.print("check remaining");
    //get remaining dice roll ticket
    switch (userTicketQuantityHash.get(Principal.toText(p))) {
      case (?x) {
        remaining_ := x;
      };
      case (null) {
        remaining_ := 0;
        userTicketQuantityHash.put(Principal.toText(p), 0);
      };
    };
    let u = userDoubleRollQuantityHash.get(Principal.toText(p));

    switch (u) {
      case (?x) {
        doubleRollRemaining_ := x;
        // return #noroll([1, x]);
      };
      case (null) {
        //return #noroll([2, doubleRollRemaining_]);
        doubleRollRemaining_ := 0;
        userDoubleRollQuantityHash.put(Principal.toText(p), 0);
      };
    };
    //return #noroll([3, doubleRollRemaining_]);

    //check if the game is already won and closed
    if (game_.time_ended != 0) return #closed(1);
    //check if there is a ticket remaining including free double roll
    let total_ = remaining_ + doubleRollRemaining_;
    if (total_ == 0) return #noroll([remaining_, doubleRollRemaining_]);
    //return #noroll([remaining_, doubleRollRemaining_]);

    var extraRoll_ = false;
    //ICP send 50% of ticket price to holder
    /*var walletBalance = await ICPLedger.icrc1_balance_of({
      owner = Principal.fromActor(this);
      subaccount = null;
    }); */
    if (doubleRollRemaining_ == 0) {
      let devFeeAmt = (ticketPrice / 2);
      pendingFee := pendingFee + devFeeAmt;
      /*Debug.print("transferring to dev" #Nat.toText(devFeeAmt));
      var finalThreshold = devThreshold + game_.reward;
      if (walletBalance > finalThreshold) {
        let transferResult_ = await transfer(devFeeAmt, devPool);
        var transferred = false;
        switch transferResult_ {
          case (#success(x)) { transferred := true };
          case (#error(txt)) {
            Debug.print("error " #txt);
            return #transferFailed(txt);
          };
        };
      }; */
      //substract ticket
      userTicketQuantityHash.put(Principal.toText(p), remaining_ -1);
      extraRoll_ := true;
      game_ := games.get(game_id);
      if (game_.time_ended != 0) {
        userDoubleRollQuantityHash.put(Principal.toText(p), doubleRollRemaining_ + 1);
        return #closed(1);
      };
    } else {
      //substract ticket
      userDoubleRollQuantityHash.put(Principal.toText(p), doubleRollRemaining_ -1);
    };
    //ROLL!==============================================================================================
    var isZero = false;
    var dice_1_ = await roll();
    if (dice_1_ == 0) isZero := true;
    var dice_2_ = await roll();
    if (dice_2_ == 0) isZero := true;
    let totalDice_ = dice_1_ + dice_2_;
    if (isZero) {
      userDoubleRollQuantityHash.put(Principal.toText(p), doubleRollRemaining_ +1);
      return #zero(1);
    };
    game_ := games.get(game_id);
    if (game_.time_ended != 0) {
      userDoubleRollQuantityHash.put(Principal.toText(p), doubleRollRemaining_ + 1);
      return #closed(1);
    };
    let isHighest_ = (Nat8.toNat(totalDice_) > currentHighestDice);
    if (isHighest_) {
      currentHighestRoller := p;
      currentHighestDice := Nat8.toNat(totalDice_);
    };

    //check if Token started, mint Eyes to address based on emission halving
    if (eyesToken) {
      let res_ = transferEyesToken(message.caller, Nat8.toNat(dice_1_ + dice_2_));
    };

    //write bet history to : history variable, user hash, and to game object (thats 3 places)
    let bet_ : T.Bet = {
      id = betIndex;
      game_id = gameIndex;
      dice_1 = dice_1_;
      dice_2 = dice_2_;
      walletAddress = message.caller;
      ethWalletAddress = getCallerEth(message.caller);
      time = now();
    };
    betIndex += 1;
    var userBets_ = userBetHistoryHash.get(Principal.toText(p));
    switch (userBets_) {
      case (?u) {
        userBetHistoryHash.put(Principal.toText(p), Array.append<T.Bet>(u, [bet_]));
      };
      case (null) {
        userBetHistoryHash.put(Principal.toText(p), [bet_]);
      };
    };
    betHistory.add(bet_);
    game_.bets := Array.append<T.Bet>(gameBets_, [bet_]);
    //check roll result
    if (dice_1_ == dice_2_ and dice_1_ == 1) {
      //game_.reward := 100000000000000;
      //game_.bonus := 100000000000000;
      Debug.print("win!");
      if (game_.reward > currentHighestReward) currentHighestReward := game_.reward;
      currentReward := currentReward + game_.reward;
      //distribute reward
      let userReward_ = userClaimableHash.get(Principal.toText(p));
      switch (userReward_) {
        case (?r) {
          userClaimableHash.put(Principal.toText(p), r +game_.reward);
        };
        case (null) {
          userClaimableHash.put(Principal.toText(p), game_.reward);
        };
      };
      let bonusReward_ = userClaimableBonusHash.get(Principal.toText(currentHighestRoller));
      switch (bonusReward_) {
        case (?b) {
          userClaimableBonusHash.put(Principal.toText(currentHighestRoller), b + game_.bonus);
        };
        case (null) {
          userClaimableBonusHash.put(Principal.toText(currentHighestRoller), game_.bonus);
        };
      };
      game_.winner := message.caller;
      game_.bonus_winner := currentHighestRoller;
      currentTotalWins += game_.reward + game_.bonus;
      totalClaimable += game_.bonus + game_.reward;

      game_.time_ended := now();
      var currentBonus_ : Float = natToFloat(game_.bonus) / ethtogwei;
      var cB_ = Float.toText(currentBonus_);
      var currentReward_ : Float = natToFloat(game_.reward) / ethtogwei;
      var cR_ = Float.toText(currentReward_);

      //Debug.print("transferring to dev" #Nat.toText(devFeeAmt));

      var walletBalance_ = await getHouseETHBalance();
      var rtick = remainingTickets();
      rtick := rtick * ticketPrice;
      if (walletBalance_ > rtick) walletBalance_ := walletBalance_ - rtick;
      if (pendingFee > (ticketPrice * 12) and (walletBalance_ > rtick)) {
        var transfer_ = (pendingFee - ticketPrice * 12);
        //transfer_ := 100000000000000;
        var finalThreshold = devThreshold + totalClaimable;
        if (walletBalance_ > finalThreshold) {
          if (transfer_ > (walletBalance_ -finalThreshold)) {
            transfer_ := (walletBalance_ -finalThreshold);
          };
          //let transferResult_ = await transfer(transfer_ -10000, devPool);

          let transferResult_ = await transferETH(transfer_, devPool);
          var transferred = false;
          switch transferResult_ {
            case (#success(x)) { transferred := true; pendingFee := 0 };
            case (#error(txt)) {
              developerFee += transfer_;
              Debug.print("error " #txt);
              //return #transferFailed(txt);
            };
          };
        } else {
          pendingFee := 0;
        };
      } else {
        pendingFee := 0;
      };

      if (isHighest_) {
        var n = await notifyDiscord("WINNER!! A legendary warrior has appeared!%0ABoth Dragon Chest AND the Dwarf's bonus have been obtained!%0A" #ethAddr # " has just won the Dragon's Chest worth " #cR_ # "ETH%0AAnd also won the Dwarf's bonus worth " #cB_ # " ICP!%0AGame is now restarting");
        startNewGame();
        return #legend(1);
      };
      var n = await notifyDiscord("WINNER!! The King has obtained the Dragon Eyes!!%0A" #ethAddr # " has just won the Dragon's Chest worth " # cR_ # "ETH%0AAnd " #getCallerEth(currentHighestRoller) # " won the Dwarf's bonus worth " #cB_ # "!%0AGame is now restarting");
      startNewGame();
      return #win(1);
    };

    //return if lost and detect if win extra roll
    if (extraRoll_) {

      game_.reward += (ticketPrice / 10) * 4;
      game_.bonus += (ticketPrice / 10) * 1;

      var currentBonus_ : Float = natToFloat(game_.bonus) / ethtogwei;
      var cB_ = Float.toText(currentBonus_);
      var currentReward_ : Float = natToFloat(game_.reward) / ethtogwei;
      var cR_ = Float.toText(currentReward_);
      var remR_ = Float.rem(natToFloat(game_.reward) / ethtogwei, 0.1);
      game_ := games.get(game_id);
      if (game_.time_ended != 0) {
        userDoubleRollQuantityHash.put(Principal.toText(p), doubleRollRemaining_ + 1);
        return #closed(1);
      };
      if (game_.reward >= currentMilestone) {
        //var n = await notifyDiscord(cR_ # " ICP reached!! Dragon's Chest is getting bigger!%0ACurrent Dragon Chest : " #cR_ # " ETH | Current Dwarf's bonus : " #cB_ # " ETH");
        currentMilestone += rewardMilestone;
      };
      game_ := games.get(game_id);
      if (game_.time_ended != 0) {
        userDoubleRollQuantityHash.put(Principal.toText(p), doubleRollRemaining_ + 1);
        return #closed(1);
      };
      /*if (game_.totalBet < 10) {
        let userBonus_ = bonusPoolbyWallet.get(Principal.toText(message.caller));
        switch (userBonus_) {
          case (?r) {
            bonusPoolbyWallet.put(Principal.toText(message.caller), Array.append<Nat>(r, [game_.id]));
          };
          case (null) {
            bonusPoolbyWallet.put(Principal.toText(message.caller), [game_.id]);
          };
        };

      }; */
      if (dice_1_ == dice_2_) {
        if (dice_1_ < 6) userDoubleRollQuantityHash.put(Principal.toText(p), doubleRollRemaining_ +1);
        if (isHighest_ and dice_1_ == 6) {
          var n = await notifyDiscord("DWARF'S BONUS WINNER!! The absolute warrior is here!%0ADwarf's bonus for this round is officially won by " #getCallerEth(message.caller) # "%0ADwarf's bonus will keep increasing until the game is won, and then it can be claimed by the winner%0ACurrent Dragon Chest : " #cR_ # " ETH | Current Dwarf's bonus : " #cB_ # " ETH");
          return #absoluteHighest(1);
        };
        if (dice_1_ == 6) {
          return #lose([dice_1_, dice_2_]);
        };
        if (isHighest_ and (dice_1_ + dice_2_ > 5)) {
          var n = await notifyDiscord("NEW HIGHEST ROLLER!! A great warrior has just rolled the highest dice so far with " #Nat8.toText(dice_1_) # " and " #Nat8.toText(dice_2_) # "!%0ADwarf's bonus for this round is currently owned by " #getCallerEth(message.caller) # "%0ADwarf's bonus will keep increasing until the game is won, and then it can be claimed by the highest roller%0ACurrent Dragon Chest : " #cR_ # " ETH | Current Dwarf's bonus : " #cB_ # " ETH");
          return #highestExtra([dice_1_, dice_2_]);
        };
        return #extra([dice_1_, dice_2_]);
      };
    };
    var currentBonus_ : Float = natToFloat(game_.bonus) / ethtogwei;
    var cB_ = Float.toText(currentBonus_);
    var currentReward_ : Float = natToFloat(game_.reward) / ethtogwei;
    var cR_ = Float.toText(currentReward_);
    if (isHighest_ and (dice_1_ + dice_2_ > 5)) {
      var n = await notifyDiscord("NEW HIGHEST ROLLER!! A great warrior has just rolled the highest dice so far with " #Nat8.toText(dice_1_) # " and " #Nat8.toText(dice_2_) # "!%0ADwarf's bonus for this round is currently owned by " #getCallerEth(message.caller) # "%0ADwarf's bonus will keep increasing until the game is won, and then it can be claimed by the highest roller%0ACurrent Dragon Chest : " #cR_ # " ETH | Current Dwarf's bonus : " #cB_ # " ETH");
      return #highest([dice_1_, dice_2_]);
    };

    #lose([dice_1_, dice_2_]);

  };

  func log_history() {

  };

  public shared (message) func claimReward() : async Bool {
    assert (_isNotPaused());
    var p = getAlias(message.caller);
    assert (_isNotBlacklisted(p));
    let reward_ = userClaimableHash.get(Principal.toText(p));

    switch (reward_) {
      case (?r) {
        if (r < 10000) return false;
        //https outcall transfer
        // let transferResult_ = await transfer(r -10000, message.caller);
        let transferResult_ = await transferETH(r, getCallerEth(message.caller));
        switch transferResult_ {
          case (#success(x)) {
            userClaimableHash.put(Principal.toText(p), 0);
            totalClaimable := _calculateUnclaimed();
            let claimHistory_ : T.ClaimHistory = {
              time = now();
              txhash = x;
              reward_claimed = r;
            };
            let claimArray_ = userClaimHistoryHash.get(Principal.toText(p));
            switch (claimArray_) {
              case (?c) {
                userClaimHistoryHash.put(Principal.toText(p), Array.append<T.ClaimHistory>(c, [claimHistory_]));
              };
              case (null) {
                userClaimHistoryHash.put(Principal.toText(p), [claimHistory_]);
              };
            };
            return true;
          };
          case (#error(txt)) {
            Debug.print("error " #txt);
            return false;
          };
          case (#reject(x)) {
            userClaimableHash.put(Principal.toText(p), 0);
            totalClaimable := _calculateUnclaimed();
            let claimHistory_ : T.ClaimHistory = {
              time = now();
              txhash = x;
              reward_claimed = r;
            };
            let claimArray_ = userClaimHistoryHash.get(Principal.toText(p));
            switch (claimArray_) {
              case (?c) {
                userClaimHistoryHash.put(Principal.toText(p), Array.append<T.ClaimHistory>(c, [claimHistory_]));
              };
              case (null) {
                userClaimHistoryHash.put(Principal.toText(p), [claimHistory_]);
              };
            };
            return false;

          };
        };
      };
      case (null) {
        return false;
      };
    };
    false;
  };

  public shared (message) func claimBonusPool() : async Bool {
    assert (_isNotPaused());
    var p = getAlias(message.caller);
    assert (_isNotBlacklisted(p));
    let reward_ = userClaimableBonusHash.get(Principal.toText(p));

    switch (reward_) {
      case (?r) {
        if (r < 10000) return false;
        let res_ = await transferETH(r, getCallerEth(message.caller));
        //let transferResult_ = await transfer(r -10000, message.caller);
        switch res_ {
          case (#success(x)) {
            userClaimableBonusHash.put(Principal.toText(p), 0);
            totalClaimable := _calculateUnclaimed();
            let claimHistory_ : T.ClaimHistory = {
              time = now();
              txhash = x;
              reward_claimed = r;
            };
            let claimArray_ = userClaimHistoryHash.get(Principal.toText(p));
            switch (claimArray_) {
              case (?c) {
                userClaimHistoryHash.put(Principal.toText(p), Array.append<T.ClaimHistory>(c, [claimHistory_]));
              };
              case (null) {
                userClaimHistoryHash.put(Principal.toText(p), [claimHistory_]);
              };
            };
            return true;
          };
          case (#error(txt)) {
            Debug.print("error " #txt);
            return false;
          };
          case (#reject(x)) {
            userClaimableHash.put(Principal.toText(p), 0);
            totalClaimable := _calculateUnclaimed();
            let claimHistory_ : T.ClaimHistory = {
              time = now();
              txhash = x;
              reward_claimed = r;
            };
            let claimArray_ = userClaimHistoryHash.get(Principal.toText(p));
            switch (claimArray_) {
              case (?c) {
                userClaimHistoryHash.put(Principal.toText(p), Array.append<T.ClaimHistory>(c, [claimHistory_]));
              };
              case (null) {
                userClaimHistoryHash.put(Principal.toText(p), [claimHistory_]);
              };
            };
            return false;

          };
        };
      };
      case (null) {
        return false;
      };
    };
    false;
  };

  public shared (message) func getRemainingTickets() : async Nat {
    assert (_isAdmin(message.caller));
    var total_ = remainingTickets();

    return total_;
  };

  func remainingTickets() : Nat {
    //assert (_isAdmin(message.caller));
    assert (_isNotPaused());
    var re_ = Iter.toArray(userTicketQuantityHash.entries());

    var total_ = 0;
    for (n in re_.vals()) {
      if (_isNotBlacklisted(Principal.fromText(n.0))) { total_ := total_ + n.1 };

    };

    return total_;
  };

  public shared (message) func listRemainingTickets() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    assert (_isNotPaused());
    var re_ = Iter.toArray(userTicketQuantityHash.entries());

    return re_;
  };

  public shared (message) func getBList() : async [(Text, Bool)] {
    assert (_isAdmin(message.caller));
    assert (_isNotPaused());
    var blist__ = Iter.toArray(blistHash.entries());

    return blist__;
  };

  public shared (message) func calculateUnclaimed() : async Nat {
    var total_ = _calculateUnclaimed();
    totalClaimable := total_;
    return total_;

  };

  func _calculateUnclaimed() : Nat {
    //assert (_isAdmin(message.caller));
    assert (_isNotPaused());
    var re_ = Iter.toArray(userClaimableHash.entries());
    var bo_ = Iter.toArray(userClaimableBonusHash.entries());
    var total_ = 0;
    for (n in re_.vals()) {

      total_ := total_ + n.1;

    };
    for (n2 in bo_.vals()) {

      total_ := total_ + n2.1;

    };
    //totalClaimable := total_;
    return total_;

  };

  /*func _getUserReward(p : Text) : Nat {

  };*/

  /*public shared (message) func emergencySendEyes(to_ : Principal, quantity_ : Nat) : async T.TransferResult {
    assert (_isAdmin(message.caller));
    var t = await transferEyesToken(to_, quantity_);
    return t;
  }; */

  func transferEyesToken(to_ : Principal, quantity_ : Nat) : async T.TransferEyesResult {

    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      transferEyesARB : (to_ : Principal, quantity_ : Nat) -> async T.TransferEyesResult;
    };
    let result = await ICDragon.transferEyesARB(to_, quantity_); //"(record {subaccount=null;})"
    result;

  };

  func transferETH(amount_ : Nat, to_ : Text) : async T.TransferResult {

    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      transferETH : (a : Nat, t : Text) -> async T.TransferResult;
    };
    try {
      let result = await ICDragon.transferETH(amount_, to_); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return #reject("reject");
    };

  };

  public shared (message) func x_(amount_ : Nat, to_ : Text) : async T.TransferResult {
    assert (_isAdmin(message.caller));
    return await transferETH(amount_, to_);
  };

  func checkTransaction(url_ : Text) : async Text {
    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      checkTransaction : (a : Text) -> async Text;
    };
    try {
      let result = await ICDragon.checkTransaction(url_); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return "reject";
    };
  };

  public shared (message) func testIdem() : async Text {
    assert (_isAdmin(message.caller));
    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      testIdem : () -> async Text;
    };
    try {
      let result = await ICDragon.testIdem(); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return "reject";
    };

  };

  public shared (message) func toText({ te : Text }) : async Blob {
    //let address_blob : Blob = Text.encodeUtf8(t_);
    //address_blob;
    let res = Text.encodeUtf8(te);
    //let res = Hex.decode(te);
    return res;
  };

  //func transfer(amount_ : Nat, to_ : Principal) : async T.TransferResult {

  func textSplit(word_ : Text, delimiter_ : Char) : [Text] {
    let hasil = Text.split(word_, #char delimiter_);
    let wordsArray = Iter.toArray(hasil);
    return wordsArray;
    //Debug.print(wordsArray[0]);
  };

  /*func transferETH(amount_ : Nat, to_ : Text) : async T.TransferResult {
    let id_ = Int.toText(now()) #to_;

    let url = "https://api.dragoneyes.xyz/transferETH?id=" #id_ # "&receiver=" #to_ # "&q=" #Nat.toText(amount_);

    let decoded_text = await send_http(url);
    let res_ = textSplit(decoded_text, '|');
    var isValid = Text.contains(decoded_text, #text "success");
    if (isValid) {
      return #success(res_[1]);
    } else {
      return #error("err");
    };

  }; */

  /*public shared (message) func emgT(amount_ : Nat, to_ : Principal) : async T.TransferResult {
    //public shared (message) func transfer(amount_ : Nat, to_ : Principal) : async T.TransferResult {
    assert (_isAdmin(message.caller));
    let transferResult = await ICPLedger.icrc1_transfer({
      amount = amount_;
      fee = null;
      created_at_time = null;
      from_subaccount = null;
      to = { owner = to_; subaccount = null };
      memo = null;
    });
    var res = 0;
    switch (transferResult) {
      case (#Ok(number)) {
        return #success(number);
      };
      case (#Err(msg)) {

        Debug.print("ICP transfer error  ");
        switch (msg) {
          case (#BadFee(number)) {
            Debug.print("Bad Fee");
            return #error("Bad Fee");
          };
          case (#GenericError(number)) {
            Debug.print("err " #number.message);
            return #error("Generic");
          };
          case (#InsufficientFunds(number)) {
            Debug.print("insufficient funds");
            return #error("insufficient funds");

          };
          case _ {
            Debug.print("ICP error err");
          };
        };
        return #error("ICP error Other");
      };
    };
  }; */

  public query func transform(raw : T.TransformArgs) : async T.CanisterHttpResponsePayload {
    let transformed : T.CanisterHttpResponsePayload = {
      status = raw.response.status;
      body = raw.response.body;
      headers = [
        {
          name = "Content-Security-Policy";
          value = "default-src 'self'";
        },
        { name = "Referrer-Policy"; value = "strict-origin" },
        { name = "Permissions-Policy"; value = "geolocation=(self)" },
        {
          name = "Strict-Transport-Security";
          value = "max-age=63072000";
        },
        { name = "X-Frame-Options"; value = "DENY" },
        { name = "X-Content-Type-Options"; value = "nosniff" },
      ];
    };
    transformed;

  };

  func send_http(url_ : Text) : async Text {
    let ic : T.IC = actor ("aaaaa-aa");

    let url = url_;

    let request_headers = [
      { name = "User-Agent"; value = "icdragon_canister" },
      { name = "Content-Type"; value = "application/json" },
      { name = "x-api-key"; value = "2021LokaInfinity" },

    ];
    Debug.print("accessing " #url);
    let transform_context : T.TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };

    let http_request : T.HttpRequestArgs = {
      url = url;
      max_response_bytes = null; //optional for request
      headers = request_headers;
      body = null; //optional for request
      method = #get;
      transform = ?transform_context;
    };

    Cycles.add(30_000_000_000);

    let http_response : T.HttpResponsePayload = await ic.http_request(http_request);
    let response_body : Blob = Blob.fromArray(http_response.body);
    let decoded_text : Text = switch (Text.decodeUtf8(response_body)) {
      case (null) { "No value returned" };
      case (?y) { y };
    };
    decoded_text;
  };

};
