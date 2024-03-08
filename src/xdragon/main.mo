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
  private stable var eyesPerXDragon = 5000000000000;
  private stable var pause = false;
  private stable var arbCanister = "";
  private stable var userIndex = 1;
  private stable var eyesMintingAccount = "";
  private stable var houseETHVault = "";
  private stable var whiteListEyesAmount = 6000000000000;

  private var genesisWhiteList = HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);
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
  private var userReferralFee = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);

  //stable var transactionHash

  stable var genesisWhiteList_ : [(Text, Bool)] = [];
  stable var genesisEyesDistribution_ : [(Text, Nat)] = [];
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
  stable var userReferralFee_ : [(Text, Nat)] = []; //1 for paid, 0 for unpaid

  system func preupgrade() {
    genesisWhiteList_ := Iter.toArray(genesisWhiteList.entries());
    genesisEyesDistribution_ := Iter.toArray(genesisEyesDistribution.entries());
    pandoraEyesDistribution_ := Iter.toArray(pandoraEyesDistribution.entries());
    ethTransactionHash_ := Iter.toArray(ethTransactionHash.entries());
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

  };
  system func postupgrade() {
    genesisWhiteList := HashMap.fromIter<Text, Bool>(genesisWhiteList_.vals(), 1, Text.equal, Text.hash);
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

  func getReferrer(p : Text) : Text {
    // input in ETH wallet
    switch (referrerHash.get(p)) {
      case (?i) {
        return i;
      };
      case (null) {
        return "none";
      };
    };

    "none";
  };

  public shared (message) func addTicketFee(address : Text, quantity : Nat, amount : Nat) : async Nat {
    assert (_isARB(message.caller));
    var referrer = getReferrer(getEthAddress(Principal.fromText(address)));
    if (referrer == "none") return 0;

    //switch(referrer)
    1;
  };

  public shared (message) func addWhiteList(p : Text) : async Nat {
    assert (_isAdmin(message.caller));
    genesisWhiteList.put(toLower(p), true);
    genesisWhiteList.size();
  };

  public shared (message) func addGenesisDistribution(p : Text) : async Nat {
    assert (_isAdmin(message.caller));
    genesisEyesDistribution.put(toLower(p), 1);
    genesisEyesDistribution.size();
  };

  public shared (message) func addPandoraDistribution(p : Text) : async Nat {
    assert (_isAdmin(message.caller));
    pandoraEyesDistribution.put(toLower(p), 1);
    pandoraEyesDistribution.size();
  };

  func _isGenesisDistributed(p : Text) : Bool {
    switch (genesisEyesDistribution.get(p)) {
      case (?n) {
        if (n == 1) { return true } else return false;

      };
      case (null) {
        return true;
      };
    };
  };

  func _isPandoraDistributed(p : Text) : Bool {
    switch (genesisEyesDistribution.get(p)) {
      case (?n) {
        if (n == 1) { return true } else return false;

      };
      case (null) {
        return true;
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

  public shared (message) func checkGenesis(p : Text) : async Bool {
    assert (_isAdmin(message.caller));
    return _isGenesisWhiteList(toLower(p));
  };

  public shared (message) func lowup(p : Text) : async Text {
    assert (_isAdmin(message.caller));
    return toLower(p) # " " #toUpper(p);
  };

  func _isGenesisWhiteList(p : Text) : Bool {
    switch (genesisWhiteList.get(toLower(p))) {
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

  func _isReferred(p : Text) : Bool {
    switch (referrerHash.get(p)) {
      case (?r) {
        return true;
      };
      case (null) {
        return false;
      };
    };
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
    switch (icpAddress) {
      case (?e) {

      };
      case (null) {
        ethIcpMapHash.put(eth_, Principal.toText(message.caller));

      };
    };

    var ncode_ = generateCode(eth_);
    if (_isGenesisWhiteList(eth_)) {
      genesisCodeHash.put(ncode_, eth_);
      userGenesisCodeHash.put(eth_, ncode_);
      referrerHash.put(eth_, eth_);
      userReferralFee.put(eth_, 0);
      return #genesis(ncode_);
    } else {
      invitationCodeHash.put(ncode_, eth_);
      userInvitationCodeHash.put(eth_, ncode_);
      referrerHash.put(eth_, getReferrerByCode(code_));
      userReferralFee.put(eth_, 0);
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

  public shared (message) func mintXDRAGON(amount_ : Nat, address_ : Text, hash_ : Text, mintFee_ : Nat) : async {
    #success : Nat;
    #error : Text;
  } {
    assert (_isReferred(getEthAddress(message.caller)));
    assert (_isHashNotUsed(hash_));
    var xAmount = amount_ / eyesPerXDragon;
    var ethAddr_ = getEthAddress(message.caller);
    var decoded_text = "";
    //https outcall check hash parameter hash, from, to, amount
    var attmpt = 0;
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
    if (isValid == false) return #error("mint Fee transfer failed");

    var burnRes_ = await burnEyes(message.caller, amount_);
    //var transIndex_ = 0;
    switch burnRes_ {
      case (#success(x)) {
        var res_ = await transferXDRAGON(xAmount, address_);
        switch (res_) {
          case (#success(x)) {
            ethTransactionHash.put(hash_, mintFee_);
            return #success(xAmount);
          };
          case (#error(x)) {
            var a = await reMint(message.caller, amount_);
            return #error(x);
          };
          case (#reject(x)) {
            var a = await reMint(message.caller, amount_);
            return #error("canister call rejected");
          };
        };
      };
      case (#error(txt)) {
        return #error(txt);
      };
      case (#reject(txt)) {
        return #error(txt);
      };
    };
    return #error("no process executed");
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

  public shared (message) func faucet(p : Text, q_ : Nat) : async Bool {
    assert (_isAdmin(message.caller));
    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      eyesFaucet : (a : Principal, t : Nat) -> async Bool;
    };
    try {
      let result = await ICDragon.eyesFaucet(Principal.fromText(getICPAddress(p)), q_); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return false;
    };

  };

  public shared (message) func executeEyesDistribution(p : Text, q_ : Nat) : async Bool {
    assert (_isAdmin(message.caller));
    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      transferEyesX : (a : Principal, t : Nat) -> async Bool;
    };
    try {
      let result = await ICDragon.transferEyesX(Principal.fromText(getICPAddress(p)), q_); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return false;
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
    switch (userGenesisCodeHash.get(p)) {
      case (?u) {
        return #genesis(u);
      };
      case (null) {

      };
    };
    switch (userInvitationCodeHash.get(p)) {
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

  public query (message) func claimXDragonPot() : async Nat {
    1;
  };

  public query (message) func roll_dice() : async Nat {
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
