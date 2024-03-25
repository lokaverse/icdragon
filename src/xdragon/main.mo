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
  private stable var latestBintBlock = 0;
  private stable var latestMetadataBintBlock = 0;
  private stable var latestMetadataMurnBlock = 0;
  private stable var betIndex = 0;
  private stable var potETHBalance = 0;
  private stable var distributionBalance = 0;
  private stable var adminPotReserve = 0;
  private stable var lastPotWinner = "";
  private stable var round = 0;
  private stable var gasFeeThreshold = 5000000000000000;
  private stable var distributionDay = 0;
  private stable var aprBase : Float = 0.0;
  private stable var initDistributionDay = 1;
  private stable var yesterdayFee = 0;
  private stable var totalWithdrawn = 0;
  private stable var isTimerStarted = false;
  //private stable var pause = false;

  private var genesisWhiteList = HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);
  private var mintingTxHash = HashMap.HashMap<Text, T.MintingHash>(0, Text.equal, Text.hash);
  private var userMintingTxHash = HashMap.HashMap<Text, [Text]>(0, Text.equal, Text.hash);
  private var txCheckHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userClaimHistoryHash = HashMap.HashMap<Text, [T.ClaimHistory]>(0, Text.equal, Text.hash);
  private var userEyesClaimHistoryHash = HashMap.HashMap<Text, [T.EyesClaimHistory]>(0, Text.equal, Text.hash);
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
  private var userClaimableDistributionHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userETHClaimableDistributionHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userClaimableReferralEyes = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userTicketCommissionHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash); // total claimable amount of ETH, mapped to ICP address of a referrer
  private var userTicketCommissionHistoryHash = HashMap.HashMap<Text, [T.CommissionHistory]>(0, Text.equal, Text.hash);
  private var dailyDistributionHistoryHash = HashMap.HashMap<Nat, T.DailyDistribution>(0, Nat.equal, Hash.hash);
  private var userDailyDistributionHistoryHash = HashMap.HashMap<Text, [T.UserDistribution]>(0, Text.equal, Text.hash);
  private var userClaimableReferralEyesHistoryHash = HashMap.HashMap<Text, [T.EyesReferral]>(0, Text.equal, Text.hash);
  private var nftHash = HashMap.HashMap<Nat, Nat>(0, Nat.equal, Hash.hash);
  private var metadataHash = HashMap.HashMap<Nat, T.NFTMetadata>(0, Nat.equal, Hash.hash);
  private var unusedMetadataHash = HashMap.HashMap<Nat, Nat>(0, Nat.equal, Hash.hash);

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
  stable var userClaimableReferralEyes_ : [(Text, Nat)] = [];
  stable var userBetHistoryHash_ : [(Text, [T.Bet])] = [];
  stable var userClaimableHash_ : [(Text, Nat)] = [];
  stable var userClaimableDistributionHash_ : [(Text, Nat)] = [];
  stable var userTicketCommissionHash_ : [(Text, Nat)] = [];
  stable var userETHClaimableDistributionHash_ : [(Text, Nat)] = [];
  stable var userClaimHistoryHash_ : [(Text, [T.ClaimHistory])] = [];
  stable var userEyesClaimHistoryHash_ : [(Text, [T.EyesClaimHistory])] = [];
  stable var dailyDistributionHistoryHash_ : [(Nat, T.DailyDistribution)] = [];
  stable var userDailyDistributionHistoryHash_ : [(Text, [T.UserDistribution])] = [];
  stable var userTicketCommissionHistoryHash_ : [(Text, [T.CommissionHistory])] = [];
  stable var userClaimableReferralEyesHistoryHash_ : [(Text, [T.EyesReferral])] = [];
  stable var nftHash_ : [(Nat, Nat)] = [];
  stable var metadataHash_ : [(Nat, T.NFTMetadata)] = [];
  stable var unusedMetadataHash_ : [(Nat, Nat)] = [];

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
    userClaimableDistributionHash_ := Iter.toArray(userClaimableDistributionHash.entries());
    userTicketCommissionHash_ := Iter.toArray(userTicketCommissionHash.entries());
    userETHClaimableDistributionHash_ := Iter.toArray(userETHClaimableDistributionHash.entries());
    userClaimHistoryHash_ := Iter.toArray(userClaimHistoryHash.entries());
    userEyesClaimHistoryHash_ := Iter.toArray(userEyesClaimHistoryHash.entries());
    userMintAmount_ := Iter.toArray(userMintAmount.entries());
    userClaimableReferralEyes_ := Iter.toArray(userClaimableReferralEyes.entries());
    dailyDistributionHistoryHash_ := Iter.toArray(dailyDistributionHistoryHash.entries());
    userDailyDistributionHistoryHash_ := Iter.toArray(userDailyDistributionHistoryHash.entries());
    userTicketCommissionHistoryHash_ := Iter.toArray(userTicketCommissionHistoryHash.entries());
    userTicketCommissionHistoryHash_ := Iter.toArray(userTicketCommissionHistoryHash.entries());
    userClaimableReferralEyesHistoryHash_ := Iter.toArray(userClaimableReferralEyesHistoryHash.entries());
    nftHash_ := Iter.toArray(nftHash.entries());
    metadataHash_ := Iter.toArray(metadataHash.entries());
    unusedMetadataHash_ := Iter.toArray(unusedMetadataHash.entries());
    isTimerStarted := false;

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
    userClaimableReferralEyesHistoryHash := HashMap.fromIter<Text, [T.EyesReferral]>(userClaimableReferralEyesHistoryHash_.vals(), 1, Text.equal, Text.hash);

    userBetHistoryHash := HashMap.fromIter<Text, [T.Bet]>(userBetHistoryHash_.vals(), 1, Text.equal, Text.hash);
    userClaimableHash := HashMap.fromIter<Text, Nat>(userClaimableHash_.vals(), 1, Text.equal, Text.hash);
    userClaimableDistributionHash := HashMap.fromIter<Text, Nat>(userClaimableDistributionHash_.vals(), 1, Text.equal, Text.hash);
    userTicketCommissionHash := HashMap.fromIter<Text, Nat>(userTicketCommissionHash_.vals(), 1, Text.equal, Text.hash);
    userETHClaimableDistributionHash := HashMap.fromIter<Text, Nat>(userETHClaimableDistributionHash_.vals(), 1, Text.equal, Text.hash);
    userTicketQuantityHash := HashMap.fromIter<Text, Nat>(userTicketQuantityHash_.vals(), 1, Text.equal, Text.hash);
    userClaimHistoryHash := HashMap.fromIter<Text, [T.ClaimHistory]>(userClaimHistoryHash_.vals(), 1, Text.equal, Text.hash);
    userEyesClaimHistoryHash := HashMap.fromIter<Text, [T.EyesClaimHistory]>(userEyesClaimHistoryHash_.vals(), 1, Text.equal, Text.hash);
    userDailyDistributionHistoryHash := HashMap.fromIter<Text, [T.UserDistribution]>(userDailyDistributionHistoryHash_.vals(), 1, Text.equal, Text.hash);
    userTicketCommissionHistoryHash := HashMap.fromIter<Text, [T.CommissionHistory]>(userTicketCommissionHistoryHash_.vals(), 1, Text.equal, Text.hash);
    dailyDistributionHistoryHash := HashMap.fromIter<Nat, T.DailyDistribution>(dailyDistributionHistoryHash_.vals(), 1, Nat.equal, Hash.hash);
    nftHash := HashMap.fromIter<Nat, Nat>(nftHash_.vals(), 1, Nat.equal, Hash.hash);
    metadataHash := HashMap.fromIter<Nat, T.NFTMetadata>(metadataHash_.vals(), 1, Nat.equal, Hash.hash);
    unusedMetadataHash := HashMap.fromIter<Nat, Nat>(unusedMetadataHash_.vals(), 1, Nat.equal, Hash.hash);
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

  //// GETTERS ///////////////////////////////////////////////////////////////////////////////////////////////

  /*public query (message) func getEYED() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    Iter.toArray(genesisEyesDistribution.entries());
  }; */

  public query (message) func getDH() : async [(Nat, T.DailyDistribution)] {
    assert (_isAdmin(message.caller));
    Iter.toArray(dailyDistributionHistoryHash.entries());
  };

  /*public query (message) func getEYEDamount() : async Nat {
    assert (_isAdmin(message.caller));
    return genesisEyesDistribution.size();
    //Iter.toArray(genesisEyesDistribution.entries());
  }; */

  /*public query (message) func getEYED2() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    Iter.toArray(pandoraEyesDistribution.entries());
  }; */

  /*public shared (message) func setOne() : async Nat {
    assert (_isAdmin(message.caller));
    userClaimableHash := HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);

    1;
  }; */

  /*public shared (message) func setInitDist(n : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    initDistributionDay := n;

    n;
  }; */

  /////////////////////////// SETTERS ////////////////////////////////////////////////////////////////////////////////////

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
  /////// INTERNAL HELPER FUNCTIONS ======================================================================================================
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

  public query (message) func getClaimDailyCheck() : async [(Text, [T.ClaimHistory])] {
    assert (_isAdmin(message.caller));
    return Iter.toArray(userClaimHistoryHash.entries());
  };

  public query (message) func getDistributionByUser(eth : Text) : async {
    #none : Nat;
    #ok : [T.UserDistribution];
  } {
    assert (_isAdmin(message.caller));
    //userClaimable
    switch (userDailyDistributionHistoryHash.get(getICPAddress(eth))) {
      case (?n) {
        return #ok(n);
      };
      case (null) { return #none(0) };
    };

  };

  public query (message) func getUnclaimedDaily(eth : Text) : async {
    #none : Nat;
    #ok : Nat;
  } {
    assert (_isAdmin(message.caller));
    //userClaimable
    switch (userClaimableDistributionHash.get(getICPAddress(eth))) {
      case (?n) {
        return #ok(n);
      };
      case (null) { return #none(0) };
    };

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

  public query (message) func getEyesRef() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    return Iter.toArray(userClaimableReferralEyes.entries());
  };

  public shared (message) func addTicketCommission(ethAddress : Text, quantity : Nat, amount : Nat) : async Nat {
    if (_isAdmin(message.caller) == false) assert (_isARB(message.caller));
    var ethAddress__ = toLower(ethAddress);
    //assert (_isReferred(getEthAddress(message.caller)));
    if (getReferrer(ethAddress__) == "none") return 0;
    //THIS IS FOR DETECTING EYES REFERRAL, NOT THE 5% TICKET COMMISSION
    if (quantity >= 2) {
      // will only give $EYES commission if the user buy >= 2 tickets
      switch (userReferralFee.get(ethAddress__)) {
        case (?x) {
          if (x == 0) {

            var rw = await getEyesCommission();
            var referrerEth_ = getReferrer(ethAddress__); // GET THE REFERRER OF THE ADDRESS WHO PURCHASES TICKET, AND PAY EM
            let eyesRef_ = {
              icpAddress = getICPAddress(ethAddress);
              time = now();
              ethAddress = ethAddress;
              eyesMinted = 0;
              ticketBought = quantity;
            };
            switch (userClaimableReferralEyesHistoryHash.get(referrerEth_)) {
              case (?v) {
                userClaimableReferralEyesHistoryHash.put(referrerEth_, Array.append<T.EyesReferral>(v, [eyesRef_]));
              };
              case (null) {
                userClaimableReferralEyesHistoryHash.put(referrerEth_, [eyesRef_]);
              };
            };
            switch (userClaimableReferralEyes.get(referrerEth_)) {
              case (?r) {
                userClaimableReferralEyes.put(referrerEth_, r +rw);
                userReferralFee.put(ethAddress__, 1); //set flag to one, means it is no longer subject to give
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
    var referrerICP_ = getICPAddress(referrerEth_); //get the ICP address of that one referree who will receive the commission
    if (_isGenesisWhiteList(referrerEth_)) {
      // only give commission if genesis
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

  public query (message) func lsa() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    return Iter.toArray(adminHash.entries());
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

  public query (message) func isPandoraDistributed(p : Text) : async {
    #notPandora : Nat;
    #notDistributed : Nat;
    #distributed : Nat;
  } {
    assert (_isAdmin(message.caller));
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

  public shared (message) func setGas(n : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    gasFeeThreshold := n;
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

  func textToNat(txt : Text) : Nat {
    switch (Nat.fromText(txt)) {
      case (?x) {
        return x;
      };
      case (null) {
        return 0;
      };
    };
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

  //public query (message)

  func notifyDiscord(message : Text) : async Bool {

    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      notifyXPotDiscord : (a : Text) -> async Bool;
    };
    try {
      let result = await ICDragon.notifyXPotDiscord(message); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return false;
    };

  };

  func transferXDistributionETH(amount_ : Nat, to_ : Text) : async T.TransferResult {

    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      transferXDistributionETH : (a : Nat, t : Text) -> async T.TransferResult;
    };
    try {
      let result = await ICDragon.transferXDistributionETH(amount_, to_); //"(record {subaccount=null;})"
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
    if (_isGenesisWhiteList(getEthAddress(message.caller)) == false) assert (_isReferred(getEthAddress(message.caller)));
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

  public query (message) func getUserMintHash(user_ : Text) : async [Text] {
    assert (_isAdmin(message.caller));
    switch (userMintingTxHash.get(user_)) {
      case (?x) {
        return x;

      };
      case (null) {
        return ["none"];
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
            let eyesRef_ = {
              icpAddress = getICPAddress(ethAddress_);
              time = now();
              ethAddress = ethAddress_;
              eyesMinted = amount_;
              ticketBought = 0;
            };
            switch (userClaimableReferralEyesHistoryHash.get(referrerEth_)) {
              case (?v) {
                userClaimableReferralEyesHistoryHash.put(referrerEth_, Array.append<T.EyesReferral>(v, [eyesRef_]));
              };
              case (null) {
                userClaimableReferralEyesHistoryHash.put(referrerEth_, [eyesRef_]);
              };
            };
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

  public shared (message) func faucet(ethAddress_ : Text, q_ : Nat) : async T.TransferEyesResult {
    assert (_isAdmin(message.caller));
    var ethAddress = toLower(ethAddress_);
    let ICDragon = actor ("s4bfy-iaaaa-aaaam-ab4qa-cai") : actor {
      transferEyesX : (a : Principal, t : Nat) -> async T.TransferEyesResult;
    };
    try {
      let result = await ICDragon.transferEyesX(Principal.fromText(getICPAddress(ethAddress)), q_); //"(record {subaccount=null;})"
      return result;
    } catch e {
      return #error("Panic");
    };

  };

  func textSplit(word_ : Text, delimiter_ : Char) : [Text] {
    let hasil = Text.split(word_, #char delimiter_);
    let wordsArray = Iter.toArray(hasil);
    return wordsArray;
    //Debug.print(wordsArray[0]);
  };

  public shared (message) func batchAddPandora(batchEthAddr : Text) : async Nat {
    assert (_isAdmin(message.caller));
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
        return #distribute(whiteListEyesAmount);
      };
      case (#distributed(x)) {
        return #none(4);
      };
      case (#notPandora(x)) {
        return #none(5);
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

  public shared (message) func addE(q : Nat, a : Text) : async () {
    assert (_isAdmin(message.caller));
    userClaimableReferralEyes.put(toLower(a), q);
  };

  public shared (message) func claimEyes() : async Nat {
    assert (_isNotPaused());
    assert (_isReferred(getEthAddress(message.caller)));
    switch (userClaimableReferralEyes.get(toLower(getEthAddress(message.caller)))) {
      case (?amount) {

        var a = await executeEyesDistribution(Principal.toText(message.caller), amount);
        switch (a) {
          case (#success(x)) {
            if (x <= 0) return 0;
            let eyesClaim_ = { time = now(); txhash = x; eyes_claimed = amount };
            let claimArray_ = userEyesClaimHistoryHash.get(toLower(getEthAddress(message.caller)));
            switch (claimArray_) {
              case (?c) {
                userEyesClaimHistoryHash.put(getEthAddress(message.caller), Array.append<T.EyesClaimHistory>(c, [eyesClaim_]));
              };
              case (null) {
                userEyesClaimHistoryHash.put(getEthAddress(message.caller), [eyesClaim_]);
              };
            };
            userClaimableReferralEyes.put(toLower(getEthAddress(message.caller)), 0);
          };
          case (#error(x)) {

          };
        };

        return amount;
      };
      case (null) {
        return 0;
      };
    };
    0;
  };

  public query (message) func claimTicketFee() : async Nat {
    1;
  };

  ////////////NFT FUNCTIONS | nftfunc///////////////////////////////////////////////////////////

  func getRandomizedNFTMetadata() : async Nat {
    var count_ = 0;
    var check : Nat8 = 0;
    while (check == 0 and count_ < 5) {
      let random = Random.Finite(await Random.blob());
      let dice_ = random.range(20);
      switch (dice_) {
        case (?x) {
          var r_ = Nat.rem(x, unusedMetadataHash.size());
          check := 1;
          return r_;
        };
        case (null) {
          count_ += 1;
          //return 0;
        };
      };
    };
    return 0;
  };

  public query (message) func getMetadata(tokenId : Nat) : async {
    #ok : ?T.NFTMetadata;
    #none : Nat;
  } {
    switch (nftHash.get(tokenId)) {
      case (?nftId) {
        return #ok(metadataHash.get(nftId));
      };
      case (null) {
        return #none(0);
      };
    };
    #none(0);
  };
  //function to pair a newly binted token to available metadata, chosen randomly by ICP randomizer
  func setMetadata(tokenId : Nat) : async Nat {
    var metadataIndex = await getRandomizedNFTMetadata();
    var unusedHash_ = Iter.toArray(unusedMetadataHash.entries());
    var metadata = unusedHash_[metadataIndex];
    nftHash.put(tokenId, metadata.1);
    //unusedMetadataHash.delete(metadata.1); // COMMENTED OUT FOR TESTING PURPOSE
    metadata.1;

  };
  private stable var  nftMetadataIndex = 0;

  //public query(message) func getMetada
  public shared (message) func initBatchMetadata(tokenList : [Text]) : async Nat {
    assert (_isAdmin(message.caller));
    //return tokenList.size();
    unusedMetadataHash := HashMap.HashMap<Nat, Nat>(0, Nat.equal, Hash.hash);
    //var data = textSplit(tokenList, '|');
    
    for (row_ in tokenList.vals()) {
      var nftData = textSplit(row_, '/');
      var image_ = (nftData[0]);
      var background_ = (nftData[1]);
      var wings_ = (nftData[2]);
      var hair_ = (nftData[3]);
      var skin_ = (nftData[4]);
      var eyes_ = (nftData[5]);
      var horn_ = (nftData[6]);
      var armor_ = (nftData[7]);
      var chest_ = (nftData[8]);
      var elemental_ = (nftData[9]);
      var card_ = (nftData[10]);
      let nft_ : T.NFTMetadata = {
        id = nftMetadataIndex;
        image = image_;
        background = background_;
        wings = wings_;
        hair = hair_;
        skin = skin_;
        eyes = eyes_;
        horn = horn_;
        armor = armor_;
        chest = chest_;
        elemental = elemental_;
        card = card_;
      };
      metadataHash.put(nftMetadataIndex, nft_);
      unusedMetadataHash.put(nftMetadataIndex, nftMetadataIndex);
      nftMetadataIndex += 1;
    };

    metadataHash.size();

  };

  func removeMetadata(tokenId : Nat) : Nat {
    //assert (_isAdmin(message.caller));
    nftHash.delete(tokenId);
    switch (nftHash.get(tokenId)) {
      case (?n) {
        unusedMetadataHash.put(n, n);
      };
      case (null) {

      };

    };
    tokenId;

  };

  public query (message) func gNFT() : async [(Nat, Nat)] {
    return Iter.toArray(nftHash.entries());
  };

  public shared (message) func updateMetadata(bint : Text, murn : Text, lb_mint : Nat, lb_burn : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    latestMetadataBintBlock := lb_mint;
    latestMetadataMurnBlock := lb_burn;
    var nftMurnTemp = HashMap.HashMap<Nat, Nat>(0, Nat.equal, Hash.hash);
    var murnt = 0;
    var binted = 0;
    var murnIds_ = textSplit(murn, '|');
    //remove all metadata from burnt token
    for (id_ in murnIds_.vals()) {
      var nftId_ = textToNat(id_);
      nftMurnTemp.put(nftId_, nftId_);
      murnt += 1;
      var res = removeMetadata(nftId_);
    };

    var bintIds_ = textSplit(bint, '|');
    //map metadata to valid tokens
    for (id_ in bintIds_.vals()) {
      var nftId_ = textToNat(id_);
      // check if binted token is burnt
      switch (nftMurnTemp.get(nftId_)) {
        case (?x) {
          // do nothing, this token is burnt
        };
        case (null) {
          switch (nftHash.get(nftId_)) {
            case (?y) {
              // do nothing, this token has already set to have metadata
            };
            case (null) {
              var res = await setMetadata(nftId_);
              binted += 1;
            };
          };
        };
      };
    };
    1;
  };

  public shared (message) func cNFT() : async Nat {
    assert (_isAdmin(message.caller));
    unusedMetadataHash := HashMap.HashMap<Nat, Nat>(0, Nat.equal, Hash.hash);
    metadataHash := HashMap.HashMap<Nat, T.NFTMetadata>(0, Nat.equal, Hash.hash);
    nftHash := HashMap.HashMap<Nat, Nat>(0, Nat.equal, Hash.hash);
    nftMetadataIndex :=0;
    metadataHash.size();
  };

  public query (message) func getAllMetadata() : async [(Nat, T.NFTMetadata)] {
    assert (_isAdmin(message.caller));
    return Iter.toArray(metadataHash.entries());
  };
  //////////////END OF NFT FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////

  public query (message) func getUnclaimedDailyReward() : async [(Nat, Nat)] {
    assert (_isAdmin(message.caller));
    return [(_calculateUnclaimedDailyReward(), gasFeeThreshold)];
  };

  public shared (message) func initiateDailyDistribution() : async Text {
    assert (_isAdmin(message.caller));

    var id = Int.toText(now()) # "init_";
    var unclaimed = _calculateUnclaimedDailyReward();
    var url = "https://api.dragoneyes.xyz/distributeDailyReward?id=" #id # "&gas=" #Nat.toText(gasFeeThreshold) # "&unclaimed=" #Nat.toText(unclaimed);
    //url;
    var result = await send_http(url);
    result;
  };

  public shared (message) func checkDistURL() : async Text {
    assert (_isAdmin(message.caller));

    var id = Int.toText(now()) # "init_";
    var unclaimed = _calculateUnclaimedDailyReward();
    var url = "https://api.dragoneyes.xyz/distributeDailyReward?id=" #id # "&gas=" #Nat.toText(gasFeeThreshold) # "&unclaimed=" #Nat.toText(unclaimed);
    url;
    //var result = await send_http(url);
    //result;
  };

  func initDailyDistribution() : async Text {
    var id = Int.toText(now()) # "init";
    var unclaimed = _calculateUnclaimedDailyReward();
    var url = "https://api.dragoneyes.xyz/distributeDailyReward?id=" #id # "&gas=" #Nat.toText(gasFeeThreshold) # "&unclaimed=" #Nat.toText(unclaimed);
    var result = await send_http(url);
    result;
  };

  public shared (message) func setTwo() : async Nat {
    assert (_isAdmin(message.caller));
    distributionDay := 0;
    userClaimableDistributionHash := HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
    userDailyDistributionHistoryHash := HashMap.HashMap<Text, [T.UserDistribution]>(0, Text.equal, Text.hash);
    dailyDistributionHistoryHash := HashMap.HashMap<Nat, T.DailyDistribution>(0, Nat.equal, Hash.hash);
    aprBase := 0;

    1;
  };

  public shared (message) func distributeDailyReward(list : Text, overview : Text) : async Nat {
    //
    assert (_isAdmin(message.caller));
    assert (_isNotPaused());

    //assign overview data
    var overviewData = textSplit(overview, '/');

    let od_ : T.DailyDistribution = {
      time : Int = now();
      amount = textToNat(overviewData[0]);
      nft = textToNat(overviewData[2]);
      holder = textToNat(overviewData[1]);
    };
    yesterdayFee := textToNat(overviewData[0]);
    //record overview data
    switch (dailyDistributionHistoryHash.get(distributionDay)) {
      case (?n) {
        dailyDistributionHistoryHash.put(distributionDay, od_);
      };
      case (null) {
        dailyDistributionHistoryHash.put(distributionDay, od_);
      };
    };
    //prepare data for distribution
    var rows_ = textSplit(list, '|');
    //distribute
    for (row_ in rows_.vals()) {
      var addr_ = textSplit(row_, '/');
      var ethAddr_ = toLower(addr_[0]);
      var icpAddr_ = getICPAddress(ethAddr_);

      var amt_ : Nat = textToNat(addr_[1]);
      var nft_ : Nat = textToNat(addr_[2]);

      let urh = {
        icpAddress = icpAddr_;
        ethAddress = ethAddr_;
        day = distributionDay;
        amount = amt_;
        nft = nft_;
        time = now();
      };
      // Record to history
      let userRewardHistory = userDailyDistributionHistoryHash.get(icpAddr_);
      if (icpAddr_ != "none") {
        var theETH = getEthAddress(Principal.fromText(icpAddr_));
        let userETHReward_ = userETHClaimableDistributionHash.get(icpAddr_);
        var existingReward = 0;
        switch (userETHReward_) {
          case (?r) {
            existingReward := r;
            userETHClaimableDistributionHash.put(icpAddr_, 0);
          };
          case (null) {
            //userETHClaimableDistributionHash.put(icpAddr_, amt_);
          };
        };

        switch (userRewardHistory) {
          case (?n) {
            userDailyDistributionHistoryHash.put(icpAddr_, Array.append<T.UserDistribution>(n, [urh]));
          };
          case (null) {
            userDailyDistributionHistoryHash.put(icpAddr_, [urh]);
          };
        };
        //record to claimable
        let userReward_ = userClaimableDistributionHash.get(icpAddr_);
        switch (userReward_) {
          case (?r) {
            userClaimableDistributionHash.put(icpAddr_, r + amt_ + existingReward);
          };
          case (null) {
            userClaimableDistributionHash.put(icpAddr_, amt_ + existingReward);
          };
        };
      } else {
        let userETHReward_ = userETHClaimableDistributionHash.get(ethAddr_);
        switch (userETHReward_) {
          case (?r) {
            userETHClaimableDistributionHash.put(icpAddr_, r + amt_);
          };
          case (null) {
            userETHClaimableDistributionHash.put(icpAddr_, amt_);
          };
        };
      };

    };

    distributionDay += 1;
    if (distributionDay > 0) {
      var days_ = 7;
      if (dailyDistributionHistoryHash.size() < 7) days_ := dailyDistributionHistoryHash.size();
      var totalFee = 0;
      var count = 0;
      for (number in Iter.range(0, days_ -1)) {
        var n = distributionDay -number;
        count += 1;
        switch (dailyDistributionHistoryHash.get(number)) {
          case (?n) {

            if (initDistributionDay > 1) {
              totalFee += n.amount / initDistributionDay;
            } else {
              totalFee += n.amount;
            };
          };
          case (null) {
            totalFee := 123123123;
          };
        };
      };
      //aprBase := natToFloat(totalFee);
      //aprBase := natToFloat(dailyDistributionHistoryHash.size());
      aprBase := (((natToFloat(totalFee) / natToFloat(days_)) / natToFloat(textToNat(overviewData[1]))));
    };
    distributionDay;
  };
  private stable var nextTimeStamp : Int = 0;
  private stable var timerId = 0;
  private stable var cnt = 0;
  public shared (message) func startTimer() : async Nat {
    assert (_isAdmin(message.caller));
    assert (isTimerStarted == false);
    //cancelTimer(timerId);
    //startHalvingTimeStamp := n;
    var text = await send_http("https://api.dragoneyes.xyz/gts");
    var n__ = Float.toInt(natToFloat(textToNat(text)));

    nextTimeStamp := n__;
    // Debug.print("stamp " #Int.toText(nextTimeStamp));

    timerId := recurringTimer(
      #seconds(1),
      func() : async () {

        if (cnt < 100) { cnt += 10 } else { cnt := 0 };
        let time_ = now() / 1000000;
        if (time_ >= nextTimeStamp) {
          //var n_ = now() / 1000000;
          nextTimeStamp := nextTimeStamp + (24 * 60 * 60 * 1000);
          var n = await initDailyDistribution();

        };
      },
    );
    isTimerStarted := true;
    timerId;
  };

  public query (message) func getC() : async Nat {
    assert (_isAdmin(message.caller));
    return cnt;
  };

  public query (message) func getN() : async Int {
    assert (_isAdmin(message.caller));
    return nextTimeStamp;
  };

  public shared (message) func resumeTimer() : async Nat {
    assert (_isAdmin(message.caller));
    timerId := recurringTimer(
      #seconds(1),
      func() : async () {
        // if (counter < 100) { counter += 10 } else { counter := 0 };
        let time_ = now() / 1000000;
        if (time_ >= nextTimeStamp) {

          nextTimeStamp := nextTimeStamp + (24 * 60 * 60 * 1000);
          var n = await initDailyDistribution();

        };
      },
    );

    timerId;
  };

  public query (message) func getAprBase() : async {
    apr : Float;
    yesterday : Nat;
    pot : Nat;
    last : Text;
    total : Nat;
    gasFee : Nat;
  } {

    var distributionNet = distributionBalance;
    if (distributionBalance > (_calculateUnclaimedDailyReward() + gasFeeThreshold)) {
      //distributionNet := distributionBalance - (_calculateUnclaimedDailyReward() + gasFeeThreshold);
    };
    var potNet = potETHBalance;
    if (potETHBalance > (_calculateUnclaimed() + gasFeeThreshold)) {
      //potNet := potETHBalance - (_calculateUnclaimed() + gasFeeThreshold);
    };
    var totalFee = potNet + distributionNet + calculateTotalWithdrawn();
    return {
      apr = aprBase;
      yesterday = yesterdayFee;
      pot = potNet;
      last = lastPotWinner;
      total = totalFee;
      gasFee = gasFeeThreshold / 5;
    };
  };

  public query (message) func getTotalWithdrawn() : async Nat {
    assert (_isAdmin(message.caller));
    assert (_isNotPaused());
    return calculateTotalWithdrawn();
    //return total_;
  };

  func calculateTotalWithdrawn() : Nat {
    var re_ = Iter.toArray(userClaimHistoryHash.entries());
    var total_ = 0;
    for (allUsers in re_.vals()) {
      if (_isAdmin(Principal.fromText(allUsers.0)) == false) {
        for (claimData_ in allUsers.1.vals()) {

          total_ += claimData_.reward_claimed;
        };
      };

    };
    totalWithdrawn := total_;
    return total_;
  };

  public shared (message) func add(eth : Text, amt : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    userClaimableDistributionHash.put(getICPAddress(eth), amt);
    0;
  };
  public query (message) func gdd(eth : Text) : async ?Nat {
    assert (_isAdmin(message.caller));
    userClaimableDistributionHash.get(getICPAddress(eth));
  };

  public shared (message) func claimDailyReward() : async {
    #error : Text;
    #success : Text;
    #reject : Text;
    #none : Nat;
  } {
    assert (_isNotPaused());
    assert (_isReferred(getEthAddress(message.caller)));
    var p = message.caller;
    //assert (_isNotBlacklisted(p));
    //return (#error("claim feature under maintenance, will be back very soon"));
    let reward_ = userClaimableDistributionHash.get(Principal.toText(p));

    switch (reward_) {
      case (?rg) {
        //if (r < 10000) return false;
        //https outcall transfer
        // let transferResult_ = await transfer(r -10000, message.caller);
        if (rg < (gasFeeThreshold / 5)) return #error("Amount below gas fee threshold");
        var r = rg -gasFeeThreshold / 5;
        let transferResult_ = await transferXDistributionETH(r, getEthAddress(message.caller));
        switch transferResult_ {
          case (#success(x)) {
            userClaimableDistributionHash.put(Principal.toText(p), 0);
            // var n = _calculateUnclaimed();
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
            totalWithdrawn += r;
            return #success("Success");
          };
          case (#error(txt)) {
            Debug.print("error " #txt);
            return #error(txt);
          };
          case (#reject(x)) {
            userClaimableDistributionHash.put(Principal.toText(p), 0);
            //var n = _calculateUnclaimed();
            let claimHistory_ : T.ClaimHistory = {
              time = now();
              txhash = "reject|" #x;
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
            totalWithdrawn += r;
            return #reject(x);

          };
        };
      };
      case (null) {
        return #none(0);
      };
    };
    #none(0);
  };

  public query (message) func getClaimables() : async { #dragonpot : Nat } {
    assert (_isReferred(getEthAddress(message.caller)));
    assert (_isNotPaused());
    switch (userClaimableHash.get(Principal.toText(message.caller))) {
      case (?n) {
        return #dragonpot(n);
      };
      case (null) {
        return #dragonpot(0);
      };
    };
  };

  public query (message) func getAPR() : async Nat {
    assert (_isReferred(getEthAddress(message.caller)));
    assert (_isNotPaused());
    1;
  };

  public query (message) func getAllClaimables() : async T.Claimables {
    assert (_isReferred(getEthAddress(message.caller)));
    assert (_isNotPaused());
    var dragonpot_ = 0;
    var daily_ = 0;
    var ticketFee_ = 0;
    var eyes_ = 0;
    switch (userClaimableHash.get(Principal.toText(message.caller))) {
      case (?n) {
        dragonpot_ := n;
      };
      case (null) {

      };
    };
    switch (userClaimableDistributionHash.get(Principal.toText(message.caller))) {
      case (?n) {
        daily_ := n;
      };
      case (null) {

      };
    };

    switch (userTicketCommissionHash.get(Principal.toText(message.caller))) {
      case (?n) {
        ticketFee_ := n;
      };
      case (null) {

      };
    };

    switch (userClaimableReferralEyes.get(toLower(getEthAddress(message.caller)))) {
      case (?x) {
        eyes_ := x;
      };
      case (null) {

      };
    };
    let a = {
      dragonpot = dragonpot_;
      daily = daily_;
      eyes = eyes_;
      ticket = ticketFee_;
    };
    return a;
  };

  public query (message) func shh() : async [(Text, [T.ClaimHistory])] {
    return Iter.toArray(userClaimHistoryHash.entries());
  };

  public shared (message) func claimXDragonPot() : async {
    #error : Text;
    #success : Text;
    #reject : Text;
    #none : Nat;
  } {
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
            // var n = _calculateUnclaimed();
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
            totalWithdrawn += r;
            return #success("Success");
          };
          case (#error(txt)) {
            Debug.print("error " #txt);
            return #error(txt);
          };
          case (#reject(x)) {
            userClaimableHash.put(Principal.toText(p), 0);
            //var n = _calculateUnclaimed();
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
            totalWithdrawn += r;
            return #reject(x);

          };
        };
      };
      case (null) {
        return #none(0);
      };
    };
    #none(0);
  };

  public shared (message) func ticketBintRequest() : async Nat {
    assert (_isNotPaused());
    assert (_isReferred(getEthAddress(message.caller)));
    var id_ = Int.toText(now()) # "ticketbintrequest";
    var url_ = "https://api.dragoneyes.xyz/checkXDragonEvent";
    1;
  };

  public shared (message) func updatePotETHBalance(gamblePot : Nat, distribution : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    potETHBalance := gamblePot;
    distributionBalance := distribution;
    var a = calculateTotalWithdrawn();
    return 0;
  };

  public query (message) func getPotETHBalance() : async Nat {
    return potETHBalance - (_calculateUnclaimed() + gasFeeThreshold);
  };

  public shared (message) func ddt(ethAddr : Text, q : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    var icpAddr = getICPAddress(ethAddr);
    var p = Principal.fromText(icpAddr);
    switch (userTicketQuantityHash.get(icpAddr)) {
      case (?x) {
        userTicketQuantityHash.put(icpAddr, q);
      };
      case (null) {

      };
    };
    return 0;
  };
  public shared (message) func setGasReserve(g : Nat) : async Nat {
    adminPotReserve := g;
    adminPotReserve;
  };

  func calculatePotReward() : async Nat {
    let id_ = Int.toText(now()) # "potbalance";

    let url = "https://api.dragoneyes.xyz/getPotETHBalance?id=" #id_;

    let decoded_text = await send_http(url);
    switch (Nat.fromText(decoded_text)) {
      case (?n) {

        var reward_ = 0;
        var unclaimed_ = _calculateUnclaimed();
        potETHBalance := n;
        if (n > (unclaimed_ + gasFeeThreshold)) {
          reward_ := n - (unclaimed_ + gasFeeThreshold);
          //adminPotReserve := adminPotReserve + 500000000000000;
        } else {
          return 0;
        };
        if (reward_ < gasFeeThreshold) {

          return 0;
        } else {
          return reward_;
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

    if (dice_1 == 0 or dice_2 == 0) {
      userTicketQuantityHash.put(Principal.toText(message.caller), remaining_ + 1);
      return #noroll(1);
    } else {
      remaining_ := remaining_ - 1;
      userTicketQuantityHash.put(Principal.toText(message.caller), remaining_);
      let bet_ : T.Bet = {
        id = betIndex;
        dice_1 = dice_1;
        dice_2 = dice_2;
        walletAddress = message.caller;
        ethWalletAddress = getEthAddress(message.caller);
        time = now();
      };
      betIndex += 1;
      var userBets_ = userBetHistoryHash.get(Principal.toText(message.caller));
      switch (userBets_) {
        case (?u) {
          userBetHistoryHash.put(Principal.toText(message.caller), Array.append<T.Bet>(u, [bet_]));
        };
        case (null) {
          userBetHistoryHash.put(Principal.toText(message.caller), [bet_]);
        };
      };
    };
    if (dice_1 == dice_2 and dice_1 == 1) {
      // check if WIN
      let userReward_ = userClaimableHash.get(Principal.toText(message.caller));
      var r_ = await calculatePotReward();
      var reward_ = Float.toText(natToFloat(r_) / 1000000000000000000);
      if (r_ <= 0) {
        userTicketQuantityHash.put(Principal.toText(message.caller), remaining_ + 1);
        return #noroll(2);
      }; // if reward is too small, return noroll and dont substract
      switch (userReward_) {
        case (?r) {
          userClaimableHash.put(Principal.toText(message.caller), r + r_);
        };
        case (null) {
          userClaimableHash.put(Principal.toText(message.caller), r_);
        };
      };
      lastPotWinner := getEthAddress(message.caller);
      var a = await notifyDiscord("XDRAGON POT WINNER! " #getEthAddress(message.caller) # " has just won " #reward_ # " ETH!");
      return #win(1);

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

  func _calculateDailyDistributed() : Nat {
    //assert (_isAdmin(message.caller));
    assert (_isNotPaused());
    var re_ = Iter.toArray(dailyDistributionHistoryHash.entries());

    var total_ = 0;
    for (n in re_.vals()) {

      total_ := total_ + n.1.amount;

    };

    //totalClaimable := total_;
    return total_;

  };

  public query (message) func getTotalDistribution() : async Nat {
    assert (_isAdmin(message.caller));
    return _calculateDailyDistributed();
  };

  func _calculateUnclaimedDailyReward() : Nat {
    //assert (_isAdmin(message.caller));
    assert (_isNotPaused());
    var re_ = Iter.toArray(userClaimableDistributionHash.entries());

    var total_ = 0;
    for (n in re_.vals()) {

      total_ := total_ + n.1;

    };

    //totalClaimable := total_;
    return total_;

  };

  public query (message) func getLatestBintBlock() : async Nat {
    return latestBintBlock;
  };

  public query (message) func getLatestMetadataMintBlock() : async Nat {
    return latestMetadataBintBlock;
  };

  public query (message) func getLatestMetadataMurnBlock() : async Nat {
    return latestMetadataMurnBlock;
  };

  public shared (message) func resetBintBlock() : async Nat {
    assert (_isAdmin(message.caller));
    userTicketQuantityHash := HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
    latestBintBlock := 0;
    return latestBintBlock;
  };

  public shared (message) func ticketBint(ethAddressTicketArray : Text, lastBlock : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    //assert (_isReferred(getEthAddress(message.caller)));
    var ticketList = textSplit(ethAddressTicketArray, '|');
    //if (lastBlock <= latestBintBlock) return 0;
    //return ticketList;
    var count = 0;
    for (row_ in ticketList.vals()) {

      var addr_ = textSplit(row_, '/');

      var ethAddr_ = toLower(addr_[0]);
      var amt_ : Nat = textToNat(addr_[2]);
      switch (Nat.fromText(addr_[2])) {
        case (?t) {
          amt_ := t;
        };
        case (null) {
          amt_ := 0;
        };
      };

      if (_isHashNotUsed(addr_[1]) or latestBintBlock == 0) {
        count += 1;
        ethTransactionHash.put(addr_[1], 1);
        switch (userTicketQuantityHash.get(getICPAddress(ethAddr_))) {
          case (?x) {
            var a_ = x +amt_;
            if (latestBintBlock == 0) {
              //a_ := amt_;
            };
            userTicketQuantityHash.put(getICPAddress(ethAddr_), a_);
            // return x +1;
          };
          case (null) {

            userTicketQuantityHash.put(getICPAddress(ethAddr_), amt_);
            //return 1;
          };
        };
      };
    };

    latestBintBlock := lastBlock;
    count;
  };

  public shared (message) func splitBint(ethAddressTicketArray : Text) : async [Text] {
    assert (_isAdmin(message.caller));
    //assert (_isReferred(getEthAddress(message.caller)));
    var ticketList = textSplit(ethAddressTicketArray, '|');
    //return ticketList;
    var count = 0;
    for (row_ in ticketList.vals()) {

      var addr_ = textSplit(row_, '/');
      count := count + 1;
      var ethAddr_ = toLower(addr_[0]);
      assert (_isHashNotUsed(addr_[1]));
      ethTransactionHash.put(addr_[1], 1);
      switch (userTicketQuantityHash.get(getICPAddress(ethAddr_))) {
        case (?x) {
          userTicketQuantityHash.put(getICPAddress(ethAddr_), x +1);
          // return x +1;
        };
        case (null) {

          userTicketQuantityHash.put(getICPAddress(ethAddr_), 1);
          //return 1;
        };
      };
    };

    return [""];
  };

  public query (message) func getAllTickets() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    return Iter.toArray(userTicketQuantityHash.entries());
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
