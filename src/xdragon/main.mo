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
import Prim "mo:prim";
import Account = "./account";
import { setTimer; cancelTimer; recurringTimer } = "mo:base/Timer";
import T "types";

//import ICPLedger "canister:icp_ledger_canister";
import Eyes "canister:eyes";

shared ({ caller = owner }) actor class ICDragon({
  admin : Principal;
}) = this {
  //indexes

  private var siteAdmin : Principal = admin;
  private stable var dappsKey = "0xSet";
  private stable var eyesPerXDragon = 6000000000000;
  private stable var pause = false;
  private stable var arbCanister = "";
  private stable var userIndex = 1;
  private stable var eyesMintingAccount = "";
  private stable var houseETHVault = "";
  private stable var whiteListEyesAmount = 6000000000000;
  private stable var mintEnabled = false;
  private stable var minimumMintForReferral = 300000000000;
  private stable var isGenesisOnly = true;
  //private stable var pause = false;

  private var genesisWhiteList = HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);
  private var mintingTxHash = HashMap.HashMap<Text, T.MintingHash>(0, Text.equal, Text.hash);
  private var userMintingTxHash = HashMap.HashMap<Text, [Text]>(0, Text.equal, Text.hash);
  private var txCheckHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userClaimHistoryHash = HashMap.HashMap<Text, [T.ClaimHistory]>(0, Text.equal, Text.hash);
  private var genesisEyesDistribution = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash); //1 for distributed, 0 for not distributed
  private var pandoraEyesDistribution = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash); //1 for distributed, 0 for not distributed
  private var ethTransactionHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var icpEthMapHash = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
  private var ethIcpMapHash = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
  private var adminHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userGenesisCodeHash = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); //ETH address to genesis
  private var userInvitationCodeHash = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); //ETH address to invitation
  private var genesisCodeHash = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); //genesis to ETH address
  private var invitationCodeHash = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); //invitation to ETH address
  private var referralHash = HashMap.HashMap<Text, [T.Referral]>(0, Text.equal, Text.hash);
  private var referrerHash = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
  private var userReferralFee = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash); //1 for  paid, 0 for not paid
  private var userMintAmount = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userTicketQuantityHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userBetHistoryHash = HashMap.HashMap<Text, [T.Bet]>(0, Text.equal, Text.hash);
  private var userClaimableHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userClaimableReferralEyes = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userTicketCommissionHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash); // total claimable amount of ETH, mapped to ICP address of a referrer
  private var userTicketCommissionHistoryHash = HashMap.HashMap<Text, [T.CommissionHistory]>(0, Text.equal, Text.hash);

  //stable var transactionHash

  stable var genesisWhiteList_ : [(Text, Bool)] = [];
  stable var genesisEyesDistribution_ : [(Text, Nat)] = [];
  stable var txCheckHash_ : [(Text, Nat)] = [];
  stable var mintingTxHash_ : [(Text, T.MintingHash)] = [];
  stable var userMintingTxHash_ : [(Text, [Text])] = [];
  stable var pandoraEyesDistribution_ : [(Text, Nat)] = [];
  stable var ethTransactionHash_ : [(Text, Nat)] = [];
  stable var icpEthMapHash_ : [(Text, Text)] = [];
  stable var ethIcpMapHash_ : [(Text, Text)] = [];
  stable var adminHash_ : [(Text, Nat)] = [];
  stable var userGenesisCodeHash_ : [(Text, Text)] = [];
  stable var userInvitationCodeHash_ : [(Text, Text)] = [];
  stable var genesisCodeHash_ : [(Text, Text)] = [];
  stable var invitationCodeHash_ : [(Text, Text)] = [];
  stable var referralHash_ : [(Text, [T.Referral])] = [];
  stable var referrerHash_ : [(Text, Text)] = [];
  stable var userTicketQuantityHash_ : [(Text, Nat)] = [];
  stable var userReferralFee_ : [(Text, Nat)] = []; //1 for paid, 0 for unpaid
  private var userMintAmount_ : [(Text, Nat)] = []; //1 for paid, 0 for unpaid
  stable var userClaimableReferralEyes_ : [(Text, Nat)] = []; //1 for paid, 0 for unpaid
  stable var userBetHistoryHash_ : [(Text, [T.Bet])] = [];
  stable var userClaimableHash_ : [(Text, Nat)] = [];
  stable var userClaimHistoryHash_ : [(Text, [T.ClaimHistory])] = [];

  public query (message) func getEYED() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    Iter.toArray(genesisEyesDistribution.entries());
  };

  public query (message) func getEYED2() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    Iter.toArray(pandoraEyesDistribution.entries());
  };
  system func preupgrade() {
    genesisWhiteList_ := Iter.toArray(genesisWhiteList.entries());
    txCheckHash_ := Iter.toArray(txCheckHash.entries());
    mintingTxHash_ := Iter.toArray(mintingTxHash.entries());
    userMintingTxHash_ := Iter.toArray(userMintingTxHash.entries());
    genesisEyesDistribution_ := Iter.toArray(genesisEyesDistribution.entries());
    pandoraEyesDistribution_ := Iter.toArray(pandoraEyesDistribution.entries());
    ethTransactionHash_ := Iter.toArray(ethTransactionHash.entries());
    userTicketQuantityHash_ := Iter.toArray(userTicketQuantityHash.entries());
    icpEthMapHash_ := Iter.toArray(icpEthMapHash.entries());
    ethIcpMapHash_ := Iter.toArray(ethIcpMapHash.entries());
    adminHash_ := Iter.toArray(adminHash.entries());
    userGenesisCodeHash_ := Iter.toArray(userGenesisCodeHash.entries());
    userInvitationCodeHash_ := Iter.toArray(userInvitationCodeHash.entries());
    genesisCodeHash_ := Iter.toArray(genesisCodeHash.entries());
    invitationCodeHash_ := Iter.toArray(invitationCodeHash.entries());
    userGenesisCodeHash_ := Iter.toArray(userGenesisCodeHash.entries());
    referralHash_ := Iter.toArray(referralHash.entries());
    referrerHash_ := Iter.toArray(referrerHash.entries());
    userReferralFee_ := Iter.toArray(userReferralFee.entries());
    userBetHistoryHash_ := Iter.toArray(userBetHistoryHash.entries());
    userClaimableHash_ := Iter.toArray(userClaimableHash.entries());
    userClaimHistoryHash_ := Iter.toArray(userClaimHistoryHash.entries());
    userMintAmount_ := Iter.toArray(userMintAmount.entries());
    userClaimableReferralEyes_ := Iter.toArray(userClaimableReferralEyes.entries());

  };
  system func postupgrade() {
    genesisWhiteList := HashMap.fromIter<Text, Bool>(genesisWhiteList_.vals(), 1, Text.equal, Text.hash);
    mintingTxHash := HashMap.fromIter<Text, T.MintingHash>(mintingTxHash_.vals(), 1, Text.equal, Text.hash);
    userMintingTxHash := HashMap.fromIter<Text, [Text]>(userMintingTxHash_.vals(), 1, Text.equal, Text.hash);
    txCheckHash := HashMap.fromIter<Text, Nat>(txCheckHash_.vals(), 1, Text.equal, Text.hash);
    genesisEyesDistribution := HashMap.fromIter<Text, Nat>(genesisEyesDistribution_.vals(), 1, Text.equal, Text.hash);
    pandoraEyesDistribution := HashMap.fromIter<Text, Nat>(pandoraEyesDistribution_.vals(), 1, Text.equal, Text.hash);
    genesisWhiteList := HashMap.fromIter<Text, Bool>(genesisWhiteList_.vals(), 1, Text.equal, Text.hash);
    ethTransactionHash := HashMap.fromIter<Text, Nat>(ethTransactionHash_.vals(), 1, Text.equal, Text.hash);
    icpEthMapHash := HashMap.fromIter<Text, Text>(icpEthMapHash_.vals(), 1, Text.equal, Text.hash);
    ethIcpMapHash := HashMap.fromIter<Text, Text>(ethIcpMapHash_.vals(), 1, Text.equal, Text.hash);
    adminHash := HashMap.fromIter<Text, Nat>(adminHash_.vals(), 1, Text.equal, Text.hash);
    userGenesisCodeHash := HashMap.fromIter<Text, Text>(userGenesisCodeHash_.vals(), 1, Text.equal, Text.hash);
    userInvitationCodeHash := HashMap.fromIter<Text, Text>(userInvitationCodeHash_.vals(), 1, Text.equal, Text.hash);
    genesisCodeHash := HashMap.fromIter<Text, Text>(genesisCodeHash_.vals(), 1, Text.equal, Text.hash);
    invitationCodeHash := HashMap.fromIter<Text, Text>(invitationCodeHash_.vals(), 1, Text.equal, Text.hash);
    referralHash := HashMap.fromIter<Text, [T.Referral]>(referralHash_.vals(), 1, Text.equal, Text.hash);
    referrerHash := HashMap.fromIter<Text, Text>(referrerHash_.vals(), 1, Text.equal, Text.hash);
    userReferralFee := HashMap.fromIter<Text, Nat>(userReferralFee_.vals(), 1, Text.equal, Text.hash);
    userMintAmount := HashMap.fromIter<Text, Nat>(userMintAmount_.vals(), 1, Text.equal, Text.hash);
    userClaimableReferralEyes := HashMap.fromIter<Text, Nat>(userClaimableReferralEyes_.vals(), 1, Text.equal, Text.hash);
    userBetHistoryHash := HashMap.fromIter<Text, [T.Bet]>(userBetHistoryHash_.vals(), 1, Text.equal, Text.hash);
    userClaimableHash := HashMap.fromIter<Text, Nat>(userClaimableHash_.vals(), 1, Text.equal, Text.hash);
    userClaimHistoryHash := HashMap.fromIter<Text, [T.ClaimHistory]>(userClaimHistoryHash_.vals(), 1, Text.equal, Text.hash);
  };

  public shared (message) func clearData() : async () {
    assert (_isAdmin(message.caller));
    icpEthMapHash := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
    ethIcpMapHash := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
    genesisWhiteList := HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);
    userGenesisCodeHash := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); //ETH address to genesis
    userInvitationCodeHash := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); //ETH address to invitation
    genesisCodeHash := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); //genesis to ETH address
    invitationCodeHash := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); //invitation to ETH address
    referrerHash := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
    userReferralFee := HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);

  };

  public shared (message) func setEthVault(d : Text) : async Text {
    assert (_isAdmin(message.caller));
    houseETHVault := d;
    return d;
  };

  public shared (message) func setOnlyGenesis(b : Bool) : async () {
    assert (_isAdmin(message.caller));
    isGenesisOnly := b;

  };

  public query (message) func isGenesisOnlyMint() : async Bool {
    return isGenesisOnly;
  };

  //public shared

  func _isAdmin(p : Principal) : Bool {
    switch (adminHash.get(Principal.toText(p))) {
      case (?a) {
        return true;
      };
      case (null) {
        return false;
      };
    };

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

  public query (message) func getRemainingRollTicket() : async Nat {
    assert (_isReferred(getEthAddress(message.caller)));
    assert (_isNotPaused());
    switch (userTicketQuantityHash.get(Principal.toText(message.caller))) {
      case (?x) {
        return x;
      };
      case (null) {
        return 0;
      };
    };
    1;
  };

  public shared (message) func setMint(mint : Bool) : async Bool {
    assert (_isAdmin(message.caller));
    mintEnabled := mint;
    mint;
  };

  func toUpper(t : Text) : Text {
    let r = Text.map(t, Prim.charToUpper);
    return r;
  };

  func toLower(t : Text) : Text {
    let r = Text.map(t, Prim.charToLower);
    return r;
  };

  func getReferrerByCode(p : Text) : Text {
    switch (genesisCodeHash.get(p)) {
      case (?i) {
        return i;
      };
      case (null) {
        //return "none";
      };
    };
    switch (invitationCodeHash.get(p)) {
      case (?i) {
        return i;
      };
      case (null) {
        return "none";
      };
    };
    "";
  };

  func getReferrer(ethAddress : Text) : Text {
    // input in ETH wallet
    switch (referrerHash.get(ethAddress)) {
      case (?i) {
        return i;
      };
      case (null) {
        return "none";
      };
    };

    "none";
  };

  public shared (message) func pauseCanister(pause_ : Bool) : async Bool {
    assert (_isAdmin(message.caller));
    pause := pause_;
    pause_;
  };

  public shared (message) func addTicketCommission(ethAddress : Text, quantity : Nat, amount : Nat) : async Nat {
    if (_isAdmin(message.caller) == false) assert (_isARB(message.caller));
    var ethAddress__ = toLower(ethAddress);
    //assert (_isReferred(getEthAddress(message.caller)));
    if (getReferrer(ethAddress__) == "none") return 0;
    //THIS IS FOR DETECTING EYES REFERRAL, NOT THE 5% TICKET COMMISSION
    if (quantity >= 2) {
      switch (userReferralFee.get(ethAddress__)) {
        case (?x) {
          if (x == 0) {
            var rw = await getEyesCommission();
            var referrerEth_ = getReferrer(ethAddress__); // GET THE REFERRER OF THE ADDRESS WHO PURCHASES TICKET, AND PAY EM
            switch (userClaimableReferralEyes.get(referrerEth_)) {
              case (?r) {
                userClaimableReferralEyes.put(referrerEth_, r +rw);
                userReferralFee.put(ethAddress__, 1);
              };
              case (null) {
                userClaimableReferralEyes.put(referrerEth_, rw);
                userReferralFee.put(ethAddress__, 1);
              };
            };
          };
        };
        case (null) {

        };
      };
    };

    //NOWWW THIS PART IS ACTUALLY FOR THE 5% COMMISSION CALCULATION, ONLY FOR GENESIS HOLDER
    var referrerEth_ = getReferrer(ethAddress__);
    var referrerICP_ = getICPAddress(referrerEth_);
    if (_isGenesisWhiteList(referrerEth_)) {
      let commissionHistory_ : T.CommissionHistory = {
        buyer = ethAddress__;
        amount = amount;
        time = now();
      };
      switch (userTicketCommissionHistoryHash.get(referrerICP_)) {
        case (?x) {
          userTicketCommissionHistoryHash.put(referrerICP_, Array.append<T.CommissionHistory>(x, [commissionHistory_]));
        };
        case (null) {
          userTicketCommissionHistoryHash.put(referrerICP_, [commissionHistory_]);
        };
      };
      switch (userTicketCommissionHash.get(referrerICP_)) {
        case (?n) {
          userTicketCommissionHash.put(referrerICP_, n +amount);
        };
        case (null) {
          userTicketCommissionHash.put(referrerICP_, amount);
        };
      };
    } else return 0;
    //switch(referrer)
    amount;
  };

  public shared (message) func addWhiteList(p : Text) : async Nat {
    assert (_isAdmin(message.caller));
    genesisWhiteList.put(toLower(p), true);
    genesisWhiteList.size();
  };

  public shared (message) func addGenesisDistribution(p : Text) : async Nat {
    assert (_isAdmin(message.caller));
    genesisEyesDistribution.put(toLower(p), 0);
    genesisEyesDistribution.size();
  };

  public shared (message) func addPandoraDistribution(ethAddress : Text, q : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    pandoraEyesDistribution.put(toLower(ethAddress), q);
    pandoraEyesDistribution.size();
  };

  func _isGenesisDistributed(p : Text) : {
    #notGenesis : Nat;
    #notDistributed : Nat;
    #distributed : Nat;
  } {
    switch (genesisEyesDistribution.get(toLower(p))) {
      case (?n) {
        if (n == 1) { return #distributed(1) } else return #notDistributed(1);

      };
      case (null) {
        return #notGenesis(1);
      };
    };
  };

  func _isPandoraDistributed(p : Text) : {
    #notPandora : Nat;
    #notDistributed : Nat;
    #distributed : Nat;
  } {
    switch (pandoraEyesDistribution.get(toLower(p))) {
      case (?n) {
        if (n == 1) { return #distributed(1) } else return #notDistributed(n);

      };
      case (null) {
        return #notPandora(1);
      };
    };
  };

  public shared (message) func getAllWhite() : async [(Text, Bool)] {
    return Iter.toArray(genesisWhiteList.entries());
  };

  func generateCode(p : Text) : Text {

    var tryagain = true;
    var code = "XD" #Nat.toText(userIndex);
    userIndex += 1;
    var tm = Int.toText(now() / 100000000);
    let addr = Text.toArray(p);
    let t = Text.toArray(tm);

    for (n in Iter.range(0, 3)) {
      code := code #Text.fromChar(t[n]) #Text.fromChar(addr[n +2]);
    };

    code;
  };

  public shared (message) func setARBCanister(n : Text) : async Text {
    assert (_isAdmin(message.caller));
    arbCanister := n;
    n;
  };

  public shared (message) func setMintingAccount(n : Text) : async Text {
    assert (_isAdmin(message.caller));
    eyesMintingAccount := n;
    n;
  };

  func _isARB(n : Principal) : Bool {
    if (Principal.toText(n) == arbCanister) {
      return true;
    };
    return false;
  };

  public shared (message) func addAdmin(p : Text) : async Nat {
    if (message.caller != siteAdmin) return 0;
    switch (adminHash.get(p)) {
      case (?a) {
        return 0;
      };
      case (null) {
        adminHash.put(p, 1);
        return 1;
      };
    };
  };

  func getEthAddress(p : Principal) : Text {
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

  func getICPAddress(e : Text) : Text {
    var icpAddress = ethIcpMapHash.get(toLower(e));
    switch (icpAddress) {
      case (?e) {
        return e;
      };
      case (null) {
        return "none";
      };
    };
  };

  public query (message) func icpOf(p : Text) : async Text {
    assert (_isAdmin(message.caller));
    return getICPAddress(p);

  };

  public shared (message) func checkGenesis(ethAddress : Text) : async Bool {
    assert (_isAdmin(message.caller));
    return _isGenesisWhiteList(toLower(ethAddress));
  };

  func _isGenesisWhiteList(ethAddress : Text) : Bool {
    switch (genesisWhiteList.get(toLower(ethAddress))) {
      case (?g) {
        return true;
      };
      case (null) {
        return false;
      };
    };
  };

  public shared (message) func setDappsKey(p_ : Text) : async Text {
    assert (_isAdmin(message.caller));
    dappsKey := p_;
    p_;
  };

  public shared (message) func setEyesXDRAGON(p_ : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    eyesPerXDragon := p_;
    p_;
  };

  public query (message) func getEyesXDRAGON() : async Nat {
    return eyesPerXDragon;
  };

  func _isApp(key : Text) : Bool {
    return (key == dappsKey);
  };

  func _isNotPaused() : Bool {
    if (pause) return false;
    true;
  };

  func _isReferred(ethAddress_ : Text) : Bool {
    switch (referrerHash.get(ethAddress_)) {
      case (?r) {
        return true;
      };
      case (null) {
        return false;
      };
    };
  };

  func _isMintEnabled() : Bool {
    return mintEnabled;
  };

  public query (message) func isMintEnabled() : async Bool {
    return mintEnabled;
  };

  //assert (_isNotPaused());
  public shared (message) func initialMap(eth__ : Text, code_ : Text) : async {
    #genesis : Text;
    #invitation : Text;
    #none : Nat;
  } {
    assert (_isNotPaused());
    var eth_ = toLower(eth__);
    var p = message.caller;
    if (_isReferred(getEthAddress(message.caller))) {
      //return #none(33);
      return getCodeByEth(eth_);
    };
    if (getReferrerByCode(code_) == "none" and _isGenesisWhiteList(eth_) == false) return #none(1);

    var ethAddress = icpEthMapHash.get(Principal.toText(message.caller));
    var e_ = "";
    switch (ethAddress) {
      case (?e) {};
      case (null) {
        icpEthMapHash.put(Principal.toText(message.caller), eth_);
      };
    };
    var icpAddress = ethIcpMapHash.get(eth_);
    var icp_ = "";
    switch (icpAddress) {
      case (?e) {
        icp_ := e;
      };
      case (null) {
        ethIcpMapHash.put(eth_, Principal.toText(message.caller));
        icp_ := Principal.toText(message.caller);
      };
    };

    var ncode_ = generateCode(eth_);
    if (_isGenesisWhiteList(eth_)) {
      genesisCodeHash.put(ncode_, eth_);
      userGenesisCodeHash.put(eth_, ncode_);
      referrerHash.put(eth_, eth_);
      userReferralFee.put(eth_, 0);
      let ref_ = [{ ethWallet = eth_; icpWallet = icp_; time = now() }];
      switch (referralHash.get(getReferrerByCode(code_))) {
        case (?x) {
          referralHash.put(getReferrerByCode(code_), Array.append<T.Referral>(x, ref_));
        };
        case (null) {
          referralHash.put(getReferrerByCode(code_), ref_);
        };
      };
      return #genesis(ncode_);
    } else {
      invitationCodeHash.put(ncode_, eth_);
      userInvitationCodeHash.put(eth_, ncode_);
      referrerHash.put(eth_, getReferrerByCode(code_));
      userReferralFee.put(eth_, 0);
      let ref_ = [{ ethWallet = eth_; icpWallet = icp_; time = now() }];
      switch (referralHash.get(getReferrerByCode(code_))) {
        case (?x) {
          referralHash.put(getReferrerByCode(code_), Array.append<T.Referral>(x, ref_));
        };
        case (null) {
          referralHash.put(getReferrerByCode(code_), ref_);
        };
      };
      return #invitation(ncode_);
    };

    return #none(1);
  };

  private func natToFloat(nat_ : Nat) : Float {
    let toNat64_ = Nat64.fromNat(nat_);
    let toInt64_ = Int64.fromNat64(toNat64_);
    let amountFloat_ = Float.fromInt64(toInt64_);
    return amountFloat_;
  };

  func checkTransaction(url_ : Text) : async Text {
    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      checkXDRTransaction : (a : Text) -> async Text;
    };
    try {
      let result = await ICDragon.checkXDRTransaction(url_); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return "reject";
    };
  };

  func transferXPotETH(amount_ : Nat, to_ : Text) : async T.TransferResult {

    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      transferXPotETH : (a : Nat, t : Text) -> async T.TransferResult;
    };
    try {
      let result = await ICDragon.transferXPotETH(amount_, to_); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return #reject("reject");
    };

  };

  public shared (message) func mintXDRAGON(amount_ : Nat) : async {
    #success : Text;
    #error : Text;
    #timeout : Text;
  } {
    assert (_isReferred(getEthAddress(message.caller)));
    if (_isAdmin(message.caller) == false) {
      assert (_isMintEnabled());
      if (isGenesisOnly) assert (_isGenesisWhiteList(getEthAddress(message.caller)));
    };
    assert (_isNotPaused());
    var icpAddr = Principal.toText(message.caller);
    //assert (_isHashNotUsed(hash_));
    var xAmount = (amount_ * 1000000000000000000) / eyesPerXDragon;
    var ethAddr_ = getEthAddress(message.caller);
    var decoded_text = "";
    //https outcall check hash parameter hash, from, to, amount
    /*var attmpt = 0;
    label chk while (decoded_text == "" or decoded_text == "reject") {
      let id_ = Int.toText(now()) #hash_;
      let url = "https://api.dragoneyes.xyz/checktransactionhash?id=" #id_ # "&hash=" #hash_ # "&sender=" #ethAddr_ # "&receiver=" #houseETHVault # "&q=" #Nat.toText(mintFee_);
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
      return #error("mint fee failed to confirm");
    };
    var isValid = Text.contains(decoded_text, #text "success");
    if (isValid == false) return #error("mint Fee transfer failed"); */

    var burnRes_ = await burnEyes(message.caller, amount_);
    var mintingResult = "";
    //var transIndex_ = 0;
    switch burnRes_ {
      case (#success(burnResult)) {

        var res_ = await transferXDRAGON(xAmount, ethAddr_);
        switch (res_) {
          case (#success(hashResult)) {
            // ethTransactionHash.put(hash_, mintFee_);
            mintingResult := hashResult;
            let mintRequest : T.MintingHash = {
              eyes = amount_;
              hash = hashResult;
              xdragon = xAmount;
              var validated = false;
              time = now();
              icpAddress = icpAddr;
              var receipt = "";

            };
            mintingTxHash.put(hashResult, mintRequest);

            switch (userMintingTxHash.get(icpAddr)) {
              case (?userMintsArray) {
                userMintingTxHash.put(icpAddr, Array.append<Text>(userMintsArray, [hashResult]));
              };
              case (null) {
                userMintingTxHash.put(icpAddr, ([hashResult]));
              };
            };

            return #success(mintingResult);
          };
          case (#error(x)) {
            var a = await reMint(message.caller, amount_);
            return #error(x);
          };
          case (#reject(x)) {
            //var a = await reMint(message.caller, amount_);
            return #timeout(mintingResult);
          };
        };
      };
      case (#error(txt)) {
        return #error(txt);
      };
      case (#reject(txt)) {
        return #error("burn rejected");
      };
    };
    return #error("no process executed");
  };

  public query (message) func getUserMint(ethAddress : Text) : async Nat {
    assert (_isAdmin(message.caller));
    var icpAddress_ = getICPAddress(toLower(ethAddress));
    switch (userMintAmount.get(icpAddress_)) {
      case (?n) {
        return n;
      };
      case (null) {
        return 0;
      };
    };
  };

  public query (message) func getAllMint(hash_ : Text) : async {
    #yes : Bool;
    #no : Bool;
  } {
    switch (mintingTxHash.get(hash_)) {
      case (?x) {
        return #yes(x.validated);

      };
      case (null) {
        return #no(false);
      };
    };
  };

  public shared (message) func updateMintResult(hash_ : Text, result_ : Text) : async Nat {
    assert (_isAdmin(message.caller));
    var amount_ = 0;
    var ethAddress_ = "";
    var icpAddress_ = "";
    switch (mintingTxHash.get(hash_)) {
      case (?x) {
        x.validated := true;
        //amount_ := x.eyes;
        // icpAddress_ := x.icpAddress;
        x.receipt := result_;
        amount_ := x.eyes;
        icpAddress_ := x.icpAddress;
        ethAddress_ := toLower(getEthAddress(Principal.fromText(x.icpAddress)));
      };
      case (null) {
        return 0;
      };
    };

    var isReferralClaimable = false;
    switch (userMintAmount.get(icpAddress_)) {
      case (?n) {
        userMintAmount.put(icpAddress_, n +amount_);
        if (n +amount_ > 300000000000) {
          isReferralClaimable := true;
        };
      };
      case (null) {
        userMintAmount.put(icpAddress_, amount_);
        if (amount_ > 300000000000) {
          isReferralClaimable := true;
        };
      };
    };
    if (isReferralClaimable) {
      switch (userReferralFee.get(ethAddress_)) {
        case (?x) {
          if (x == 0) {
            var rw = await getEyesCommission();
            var referrerEth_ = getReferrer(ethAddress_);
            switch (userClaimableReferralEyes.get(referrerEth_)) {
              case (?r) {
                userClaimableReferralEyes.put(referrerEth_, r +rw);
                userReferralFee.put(ethAddress_, 1);
              };
              case (null) {
                userClaimableReferralEyes.put(referrerEth_, rw);
                userReferralFee.put(ethAddress_, 1);
              };
            };
          };
        };
        case (null) {

        };
      };
    };
    amount_;
  };

  public query (message) func getClaimableReferralEyes(eth : Text) : async Nat {
    assert (_isAdmin(message.caller));
    switch (userClaimableReferralEyes.get(toLower(eth))) {
      case (?x) {
        return x;
      };
      case (null) {
        return 0;
      };
    };
  };

  func getEyesCommission() : async Nat {
    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      xdrCommission : () -> async Nat;
    };
    try {
      let result = await ICDragon.xdrCommission(); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return 0;
    };
  };

  //public shared(message) func

  public query (message) func getAllReferrals() : async [(Text, [T.Referral])] {
    assert (_isAdmin(message.caller));
    return Iter.toArray(referralHash.entries());
  };

  public query (message) func getReferralsOf(ethAddress : Text) : async {
    #none;
    #ok : [T.Referral];
  } {
    assert (_isAdmin(message.caller));

    switch (referralHash.get(toLower(ethAddress))) {
      case (?n) {
        return #ok(n);
      };
      case (null) {
        return #none;
      };

    };

  };

  public query (message) func getTicketCommissions() : async [(Text, [T.Referral])] {
    assert (_isAdmin(message.caller));
    return Iter.toArray(referralHash.entries());
  };

  func burnEyes(owner_ : Principal, amount_ : Nat) : async T.TransferResult {
    Debug.print("transferring from " #Principal.toText(owner_) # " by " #Principal.toText(Principal.fromActor(this)) # " " #Nat.toText(amount_));
    let transferResult = await Eyes.icrc2_transfer_from({
      from = { owner = owner_; subaccount = null };
      amount = amount_;
      fee = null;
      created_at_time = null;
      from_subaccount = null;
      to = { owner = Principal.fromText(eyesMintingAccount); subaccount = null };
      spender_subaccount = null;
      memo = null;
    });
    var res = 0;
    switch (transferResult) {
      case (#Ok(number)) {
        return #success(Nat.toText(number));
      };
      case (#Err(msg)) {

        Debug.print("transfer error  ");
        switch (msg) {
          case (#BadFee(number)) {
            return #error("Bad Fee");
          };
          case (#GenericError(number)) {
            return #error("Generic");
          };
          case (#BadBurn(number)) {
            return #error("BadBurn");
          };
          case (#InsufficientFunds(number)) {
            return #error("Insufficient Funds");
          };
          case (#InsufficientAllowance(number)) {
            return #error("Insufficient Allowance ");
          };
          case _ {
            Debug.print("ICP err");
          };
        };
        return #error("ICP transfer other error");
      };
    };
  };

  func transferXDRAGON(amount_ : Nat, to_ : Text) : async T.TransferResult {

    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      transferXDRAGON : (a : Nat, t : Text) -> async T.TransferResult;
    };
    try {
      let result = await ICDragon.transferXDRAGON(amount_, to_); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return #reject("reject");
    };

  };

  public shared (message) func faucet(ethAddress_ : Text, q_ : Nat) : async Bool {
    assert (_isAdmin(message.caller));
    var ethAddress = toLower(ethAddress_);
    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      eyesFaucet : (a : Principal, t : Nat) -> async Bool;
    };
    try {
      let result = await ICDragon.eyesFaucet(Principal.fromText(getICPAddress(ethAddress)), q_); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return false;
    };

  };

  func textSplit(word_ : Text, delimiter_ : Char) : [Text] {
    let hasil = Text.split(word_, #char delimiter_);
    let wordsArray = Iter.toArray(hasil);
    return wordsArray;
    //Debug.print(wordsArray[0]);
  };

  public shared (message) func batchAddPandora(batchEthAddr : Text) : async Nat {

    var rowList = textSplit(batchEthAddr, '.');
    for (row_ in rowList.vals()) {

      var addr_ = textSplit(row_, '|');
      pandoraEyesDistribution.put(toLower(addr_[0]), 12000);
    };
    pandoraEyesDistribution.size();
  };

  public shared (message) func checkEyesReward() : async {
    #distribute : Nat;
    #none : Nat;
  } {
    switch (_isPandoraDistributed(getEthAddress(message.caller))) {
      case (#notDistributed(amountToDistribute)) {
        var a = await executeEyesDistribution(Principal.toText(message.caller), amountToDistribute);
        pandoraEyesDistribution.put(getEthAddress(message.caller), 1);
      };
      case (#distributed(x)) {
        return #none(4);
      };
      case (#notPandora(x)) {

      };
    };
    switch (_isGenesisDistributed(getEthAddress(message.caller))) {

      case (#notDistributed(x)) {
        var a = await executeEyesDistribution(Principal.toText(message.caller), whiteListEyesAmount);
        genesisEyesDistribution.put(getEthAddress(message.caller), 1);
        return #distribute(whiteListEyesAmount);
      };
      case (#distributed(x)) {
        //var a = await executeEyesDistribution(Principal.toText(message.caller), whiteListEyesAmount);
        //genesisEyesDistribution.put(getEthAddress(message.caller), 1);
        return #none(1);
        //return #none(1);

      };
      case (#notGenesis(x)) {
        return #none(2);
      };
    };
    #none(3);
  };

  func executeEyesDistribution(icpAddress_ : Text, q_ : Nat) : async T.TransferEyesResult {
    //assert (_isAdmin(message.caller));
    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      transferEyesX : (a : Principal, t : Nat) -> async T.TransferEyesResult;
    };
    try {
      let result = await ICDragon.transferEyesX(Principal.fromText(icpAddress_), q_); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return #error("Panic");
    };

  };

  func reMint(to : Principal, am : Nat) : async {
    #success : Nat;
    #error : Text;
  } {

    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      reMintEyesToken : (a : Principal, t : Nat) -> async {
        #success : Nat;
        #error : Text;
      };
    };
    try {
      let result = await ICDragon.reMintEyesToken(to, am); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return #error("reject");
    };

  };

  public query (message) func getCode() : async {
    #genesis : Text;
    #invitation : Text;
    #none : Nat;
  } {
    return getCodeByEth(getEthAddress(message.caller));

  };

  public shared (message) func getce(p : Text) : async {
    #genesis : Text;
    #invitation : Text;
    #none : Nat;
  } {
    return getCodeByEth(toLower(p));
  };

  func getCodeByEth(p : Text) : {
    #genesis : Text;
    #invitation : Text;
    #none : Nat;
  } {
    switch (userGenesisCodeHash.get(toLower(p))) {
      case (?u) {
        return #genesis(u);
      };
      case (null) {

      };
    };
    switch (userInvitationCodeHash.get(toLower(p))) {
      case (?u) {
        return #invitation(u);
      };
      case (null) {
        return #none(1);
      };
    };

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

  public query (message) func claimEyes() : async Nat {
    1;
  };

  public query (message) func claimTicketFee() : async Nat {
    1;
  };

  public shared (message) func claimXDragonPot() : async Bool {
    assert (_isNotPaused());
    assert (_isReferred(getEthAddress(message.caller)));
    var p = message.caller;
    //assert (_isNotBlacklisted(p));
    let reward_ = userClaimableHash.get(Principal.toText(p));

    switch (reward_) {
      case (?r) {
        //if (r < 10000) return false;
        //https outcall transfer
        // let transferResult_ = await transfer(r -10000, message.caller);
        let transferResult_ = await transferXPotETH(r, getEthAddress(message.caller));
        switch transferResult_ {
          case (#success(x)) {
            userClaimableHash.put(Principal.toText(p), 0);
            var n = _calculateUnclaimed();
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
            var n = _calculateUnclaimed();
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

  func calculatePotReward() : async Nat {
    let id_ = Int.toText(now()) # "potbalance";

    let url = "https://api.dragoneyes.xyz/getPotETHBalance";

    let decoded_text = await send_http(url);
    switch (Nat.fromText(decoded_text)) {
      case (?n) {
        //return decoded_text;
        var r_ = (n * 99) / 100;
        var c_ = _calculateUnclaimed();
        if (r_ > c_) {
          r_ := r_ -c_;
        } else {
          return 0;
        };
        if (r_ < 1000000000000000) {
          return 0;
        } else {
          return r_;
        };
      };
      case (null) {
        return 0;
      };
    };
  };

  public query func isNotPaused() : async Bool {
    if (pause) return false;
    true;
  };

  public shared (message) func roll_dice() : async {
    #noticket : Nat;
    #win : Nat;
    #lose : [Nat8];
    #noroll : Nat;
  } {
    assert (_isReferred(getEthAddress(message.caller)));
    assert (_isNotPaused());
    var remaining_ = 0;
    switch (userTicketQuantityHash.get(Principal.toText(message.caller))) {
      case (?x) {
        if (x < 1) return #noticket(1);
        remaining_ := x;
      };
      case (null) {
        remaining_ := 0;
        userTicketQuantityHash.put(Principal.toText(message.caller), 0);
        return #noticket(1);
      };
    };
    var dice_1 = await roll();
    var dice_2 = await roll();
    if (dice_1 == dice_2 and dice_1 == 1) {
      let userReward_ = userClaimableHash.get(Principal.toText(message.caller));
      var r_ = await calculatePotReward();
      if (r_ <= 0) return #noroll(2);
      switch (userReward_) {
        case (?r) {

          userClaimableHash.put(Principal.toText(message.caller), r + r_);
          userTicketQuantityHash.put(Principal.toText(message.caller), 0);
        };
        case (null) {
          userClaimableHash.put(Principal.toText(message.caller), r_);
        };
      };
      return #win(1);

    };
    if (dice_1 == 0 or dice_2 == 0) {
      return #noroll(1);
    };

    #lose([dice_1, dice_2]);

  };

  func _calculateUnclaimed() : Nat {
    //assert (_isAdmin(message.caller));
    assert (_isNotPaused());
    var re_ = Iter.toArray(userClaimableHash.entries());

    var total_ = 0;
    for (n in re_.vals()) {

      total_ := total_ + n.1;

    };

    //totalClaimable := total_;
    return total_;

  };

  public shared (message) func ticketBint(hash__ : Text) : async Nat {
    assert (_isAdmin(message.caller));
    assert (_isReferred(getEthAddress(message.caller)));
    assert (_isHashNotUsed(hash__));
    var ethAddr_ = getEthAddress(message.caller);
    assert (_isReferred(ethAddr_));
    //https outcall and string rule to check if hash is legit
    ethTransactionHash.put(hash__, 1);
    switch (userTicketQuantityHash.get(getICPAddress(ethAddr_))) {
      case (?x) {
        userTicketQuantityHash.put(ethAddr_, x +1);
        return x +1;
      };
      case (null) {

        userTicketQuantityHash.put(ethAddr_, 1);
        return 1;
      };
    };
    1;
  };

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
