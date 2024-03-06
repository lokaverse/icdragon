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

//import ICPLedger "canister:icp_ledger_canister";
import Eyes "canister:eyes";

shared ({ caller = owner }) actor class ICDragon({
  admin : Principal;
}) = this {
  //indexes

  private var siteAdmin : Principal = admin;
  private stable var dappsKey = "0xSet";
  private stable var eyesPerXDRAGON = 5000000000000;
  private stable var pause = false;
  private stable var arbCanister = "";

  private var genesisWhiteList = HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);

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
  stable var icpEthMapHash_ : [(Text, Text)] = [];
  stable var ethIcpMapHash_ : [(Text, Text)] = [];
  stable var adminHash_ : [(Text, Nat)] = [];
  stable var userGenesisCodeHash_ : [(Text, Text)] = [];
  stable var userTicketQuantityHash_ : [(Text, Text)] = [];
  stable var userInvitationCodeHash_ : [(Text, Text)] = [];
  stable var genesisCodeHash_ : [(Text, Text)] = [];
  stable var invitationCodeHash_ : [(Text, Text)] = [];
  stable var referralHash_ : [(Text, [T.Referral])] = [];
  stable var referrerHash_ : [(Text, Text)] = [];
  stable var userReferralFee_ : [(Text, Nat)] = []; //1 for paid, 0 for unpaid

  system func preupgrade() {
    genesisWhiteList_ := Iter.toArray(genesisWhiteList.entries());
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
    genesisWhiteList := HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);
    userGenesisCodeHash := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); //ETH address to genesis
    userInvitationCodeHash := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); //ETH address to invitation
    genesisCodeHash := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); //genesis to ETH address
    invitationCodeHash := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); //invitation to ETH address
    referrerHash := HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);

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

    "";
  };

  public shared (message) func addTicketFee(p : Text, q : Nat, a : Nat) : async Nat {
    1;
  };

  public shared (message) func addWhiteList(p : Text) : async Nat {
    assert (_isAdmin(message.caller));
    genesisWhiteList.put(p, true);
    genesisWhiteList.size();
  };

  func generateCode(p : Text) : Text {

    var tryagain = true;
    var code = "";
    while (tryagain) {
      var tm = Int.toText(now() / 100000000);
      let addr = Text.toArray(p);
      let t = Text.toArray(tm);

      for (n in Iter.range(0, 5)) {
        code := code #Text.fromChar(t[n]) #Text.fromChar(addr[n +2]);
      };
      switch (genesisCodeHash.get(code)) {
        case (null) { tryagain := false };
      };
      switch (invitationCodeHash.get(code)) {
        case (null) { tryagain := false };
      };
    };
    code;
  };

  public shared (message) func setARBCanister(n : Text) : async Text {
    assert (_isAdmin(message.caller));
    arbCanister := n;
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

  public shared (message) func checkGenesis(p : Text) : async Bool {
    assert (_isAdmin(message.caller));
    return _isGenesisWhiteList(p);
  };

  func _isGenesisWhiteList(p : Text) : Bool {
    switch (genesisWhiteList.get(p)) {
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
    eyesPerXDRAGON := p_;
    p_;
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
    var eth_ = Text.toLowercase(eth__);
    var p = message.caller;
    if (_isReferred(getEthAddress(message.caller))) {
      return getCodeByEth(eth_);
    };

    var ethAddress = icpEthMapHash.get(Principal.toText(message.caller));
    var e_ = "";
    switch (ethAddress) {
      case (?e) {
        //return 0;

      };
      case (null) {
        icpEthMapHash.put(Principal.toText(message.caller), eth_);
        // return 0;
      };
    };
    var icpAddress = ethIcpMapHash.get(eth_);
    switch (icpAddress) {
      case (?e) {
        if (_isReferred(getEthAddress(message.caller)) == false) {
          if (getReferrerByCode(code_) == "none" and _isGenesisWhiteList(eth_) == false) return #none(1);
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
        };

        return getCodeByEth(eth_);
      };
      case (null) {
        ethIcpMapHash.put(eth_, Principal.toText(message.caller));
        if (getReferrerByCode(code_) == "none") return #none(1);
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
    };
    return #none(1);
  };

  public shared (message) func mintXDRAGON(amount_ : Nat, address_ : Text) : async Text {
    //check caller EYES balance > amount_
    //check EYES to XDRAGON conversion
    //https outcall transfer XDRAGON to address
    //if success burn EYES
    return "";
  };

  public query (message) func getCode() : async {
    #genesis : Text;
    #invitation : Text;
    #none : Nat;
  } {
    return getCodeByEth(getEthAddress(message.caller));

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

  public query (message) func claimEyes() : async Nat {
    1;
  };

  public query (message) func claimTicketFee() : async Nat {
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
