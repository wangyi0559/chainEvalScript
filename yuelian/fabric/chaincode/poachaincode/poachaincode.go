package main

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/sha256"
	"encoding/asn1"
	"errors"
	"math/big"
	"strconv"
	"strings"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

var logger = shim.NewLogger("poachaincode")

type SimpleChaincode struct {
}

type POA struct {
	value    int64
	limitsec int64
}

type edsasig struct {
	R, S *big.Int
}

const POACON = 100000000

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	_, args := stub.GetFunctionAndParameters() //获取到调用Init函数的方法名称和参数
	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	var obj []POA = make([]POA, 1)
	obj[0].value = 130000000 * POACON
	obj[0].limitsec = 0

	struser, err := t.encodeUserData(obj)
	if err != nil {
		return shim.Error(err.Error())
	}

	err = stub.PutState(args[0], []byte(struser))
	if err != nil {
		return shim.Error(err.Error())
	}

	obj[0].value = 0
	struser, err = t.encodeUserData(obj)
	if err != nil {
		return shim.Error(err.Error())
	}
	err = stub.PutState(args[1], []byte(struser))
	if err != nil {
		return shim.Error(err.Error())
	}

	err = stub.PutState("ORGFUNDER", []byte(args[1]))
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

func (t *SimpleChaincode) createuser(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}
	key := args[0]
	accountA, err := stub.GetState(key)
	if err != nil {
		return shim.Error(err.Error())
	}
	if len(accountA) > 0 {
		return shim.Error("user exist.")
	}

	var obj []POA = make([]POA, 1)
	obj[0].value = 0
	obj[0].limitsec = 0

	struser, err := t.encodeUserData(obj)
	if err != nil {
		return shim.Error(err.Error())
	}
	err = stub.PutState(key, []byte(struser))
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

//arg0 fee account address arg1 channel blockhash
func (t *SimpleChaincode) markchannelhash(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	accountA, err := stub.GetState(args[0])
	if err != nil {
		return shim.Error("Failed to get Address state")
	}
	userA, err := t.decodeUserData(string(accountA))
	if err != nil {
		return shim.Error("decode userdata fail.")
	}

	if userA[0].value < 0.0001*POACON {
		return shim.Error("account values not enough.")
	}

	userA[0].value -= 0.0001 * POACON

	strAccount, err := t.encodeUserData(userA)

	stub.PutState(args[0], []byte(strAccount))

	key := "POR-BLOCK-HASH"

	err = stub.PutState(key, []byte(args[1]))
	if err != nil {
		return shim.Error(err.Error())
	}

	err = t.fee(stub, 0.0001*POACON)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}

func (t *SimpleChaincode) fee(stub shim.ChaincodeStubInterface, value int64) error {

	userfund, err := stub.GetState("ORGFUNDER")
	if err != nil {
		return err
	}

	account, err := stub.GetState(string(userfund))
	if err != nil {
		return err
	}

	user, err := t.decodeUserData(string(account))
	if err != nil {
		return err
	}

	user[0].value += value

	strAccount, err := t.encodeUserData(user)
	if err != nil {
		return err
	}
	err = stub.PutState(string(userfund), []byte(strAccount))

	if err != nil {
		return err
	}
	return nil
}

func (t *SimpleChaincode) checksignature(pubstr, sign, digest []byte) (bool, error) {

	sig := new(edsasig)
	_, err := asn1.Unmarshal(sign, sig)

	if err != nil {
		return false, errors.New("Failed unmashalling signature [%s]" + err.Error())
	}

	// Validate sig
	if sig.R == nil {
		return false, errors.New("Invalid signature. R must be different from nil.")
	}
	if sig.S == nil {
		return false, errors.New("Invalid signature. S must be different from nil.")
	}

	if sig.R.Sign() != 1 {
		return false, errors.New("Invalid signature. R must be larger than zero")
	}

	if sig.S.Sign() != 1 {
		return false, errors.New("Invalid signature. S must be larger than zero")
	}

	namedCurve := elliptic.P256()
	x, y := elliptic.Unmarshal(namedCurve, pubstr)
	if x == nil {
		return false, errors.New("x509: failed to unmarshal elliptic curve point")
	}
	pubkey := &ecdsa.PublicKey{
		Curve: namedCurve,
		X:     x,
		Y:     y,
	}

	if err != nil {
		return false, errors.New("Parse public key error:" + err.Error())
	}

	return ecdsa.Verify(pubkey, digest, sig.R, sig.S), nil
}

// arg0 target address
// arg1 paycount
// arg2 time limit
// arg3 signature

func (t *SimpleChaincode) lockpay(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 6 {
		return shim.Error("Incorrect number of arguments. Expecting 4")
	}
	var err error

	accountA, err := stub.GetState(args[0])
	if err != nil {
		return shim.Error("Failed to get A state")
	}

	accountB, err := stub.GetState(args[1])
	if err != nil {
		return shim.Error("Failed to get B state")
	}

	var paycount int64

	paycount, err = strconv.ParseInt(args[2], 10, 64)
	if err != nil {
		return shim.Error("Expecting integer value for args 3 holding")
	}

	b58 := NewBitcoinBase58()

	pubkey, err := b58.DecodeStringCheck(args[3])
	if err != nil {
		return shim.Error("Decode A base58 string fail:" + err.Error())
	}

	//check user address and pubkey is valid
	hash := sha256.Sum256(pubkey)
	hashadress, err := b58.EncodeToStringCheck(hash[:20])
	if err != nil {
		return shim.Error("Encode base58 user address error:" + err.Error())
	}

	if args[0] != hashadress {
		return shim.Error("user address or pubkey not corrent!")
	}

	signature, err := b58.DecodeStringCheck(args[4])
	if err != nil {
		return shim.Error("Decode sign base58 string fail:" + err.Error())
	}

	limittm, err := strconv.ParseInt(args[5], 10, 64)
	if err != nil {
		return shim.Error("Expecting integer value for args 6 holding")
	}

	translation := args[0] + string(accountA) + args[1] + args[2]

	hash = sha256.Sum256([]byte(translation))

	valid, err := t.checksignature(pubkey, signature, hash[:])

	if err != nil {
		return shim.Error("check signature error:" + err.Error())
	}

	if !valid {
		return shim.Error("veify signature fail.")
	}

	userA, err := t.decodeUserData(string(accountA))
	if err != nil {
		return shim.Error("Decode userdata fail.")
	}
	userB, err := t.decodeUserData(string(accountB))
	if err != nil {
		return shim.Error("Decode userdata fail.")
	}

	var count int = len(userA)
	var tn time.Time
	tn = time.Now()
	timet := tn.UnixNano() / 1000000000

	var i int
	for i = 1; i < count; i++ {
		if timet > userA[i].limitsec {
			userA[0].value += userA[i].value
			userA[i].value = 0
		}
	}

	if (paycount + 0.0001*POACON) > userA[0].value {
		return shim.Error("account value small to pay.")
	}

	userA[0].value -= (paycount + 0.0001*POACON)

	nLen := len(userB)
	var newB []POA = make([]POA, nLen+1)
	copy(newB, userB)

	newB[nLen].value = newB[nLen].value + paycount
	newB[nLen].limitsec = timet + limittm

	astr, err := t.encodeUserData(userA)

	if err != nil {
		return shim.Error("encode userdata fail.")
	}

	bstr, err := t.encodeUserData(newB)
	if err != nil {
		return shim.Error("encode userdata fail.")
	}

	err = stub.PutState(args[0], []byte(astr))
	if err != nil {
		return shim.Error("put state fail.")
	}

	err = stub.PutState(args[1], []byte(bstr))
	if err != nil {
		return shim.Error("put state fail.")
	}

	err = t.fee(stub, 0.0001*POACON)
	if err != nil {
		return shim.Error("cut fee error:" + err.Error())
	}

	return shim.Success(nil)
}

//args[0] usera,args[1] userb,args[2] paycount 200000000 ,args[3] pubkey,args[4] signature
func (t *SimpleChaincode) payment(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 5 {
		return shim.Error("Incorrect number of arguments. Expecting 4")
	}
	var err error

	accountA, err := stub.GetState(args[0])
	if err != nil {
		return shim.Error("Failed to get A state")
	}

	accountB, err := stub.GetState(args[1])
	if err != nil {
		return shim.Error("Failed to get B state")
	}

	var paycount int64

	paycount, err = strconv.ParseInt(args[2], 10, 64)
	if err != nil {
		return shim.Error("Expecting integer value for args 3 holding")
	}

	b58 := NewBitcoinBase58()

	pubkey, err := b58.DecodeStringCheck(args[3])
	if err != nil {
		return shim.Error("Decode A base58 string fail:" + err.Error())
	}

	//check user address and pubkey is valid
	hash := sha256.Sum256(pubkey)
	hashadress, err := b58.EncodeToStringCheck(hash[:20])

	if err != nil {
		return shim.Error("Encode base58 user address error:" + err.Error())
	}

	if args[0] != hashadress {
		return shim.Error("user address or pubkey not corrent!")
	}

	signature, err := b58.DecodeStringCheck(args[4])
	if err != nil {
		return shim.Error("Decode sign base58 string fail:" + err.Error())
	}

	translation := args[0] + string(accountA) + args[1] + args[2]

	hash = sha256.Sum256([]byte(translation))

	valid, err := t.checksignature(pubkey, signature, hash[:])
	if err != nil {
		return shim.Error("check signature error:" + err.Error())
	}

	if !valid {
		return shim.Error("veify signature fail.")
	}

	userA, err := t.decodeUserData(string(accountA))
	if err != nil {
		return shim.Error("decode userdata fail.")
	}
	userB, err := t.decodeUserData(string(accountB))
	if err != nil {
		return shim.Error("decode userdata fail.")
	}
	var count int = len(userA)
	var tn time.Time
	tn = time.Now()
	timet := tn.UnixNano() / 1000000000
	var i int
	for i = 1; i < count; i++ {
		if timet > userA[i].limitsec {
			userA[0].value += userA[i].value
			userA[i].value = 0
		}
	}

	if paycount > userA[0].value {
		return shim.Error("account value small to payment.")
	}

	userA[0].value -= (paycount + 0.0001*POACON)
	userB[0].value += paycount

	astr, err := t.encodeUserData(userA)
	if err != nil {
		return shim.Error("encode userdata fail.")
	}
	bstr, err := t.encodeUserData(userB)
	if err != nil {
		return shim.Error("encode userdata fail.")
	}
	err = stub.PutState(args[0], []byte(astr))
	if err != nil {
		return shim.Error("put state fail.")
	}
	err = stub.PutState(args[1], []byte(bstr))
	if err != nil {
		return shim.Error("put state fail.")
	}
	err = t.fee(stub, 0.0001*POACON)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}

func (t *SimpleChaincode) decodeUserData(userstr string) ([]POA, error) {

	sitem := strings.Split(userstr, "|")
	count := len(sitem)
	var err error
	var userdata []POA = make([]POA, count)
	var i int
	for i = 0; i < count; i++ {
		strVal := strings.Split(sitem[i], ",")
		userdata[i].value, err = strconv.ParseInt(strVal[0], 10, 64)
		if err != nil {
			break
		}
		userdata[i].limitsec, err = strconv.ParseInt(strVal[1], 10, 64)
		if err != nil {
			break
		}
	}
	return userdata, err
}

func (t *SimpleChaincode) encodeUserData(userdata []POA) (string, error) {

	var userstr string
	count := len(userdata)
	var err error
	var i int
	for i = 0; i < count; i++ {
		if i > 0 {
			if userdata[i].value == 0 {
				continue
			}
			userstr += "|"
		}
		userstr += strconv.FormatInt(userdata[i].value, 10) + "," + strconv.FormatInt(userdata[i].limitsec, 10)
	}
	return userstr, err
}

func (t *SimpleChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}
	account, err := stub.GetState(args[0])
	if err != nil {
		return shim.Error("account not exist.")
	}
	return shim.Success(account)
}

func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	if function == "createuser" {
		return t.createuser(stub, args)
	} else if function == "payment" {
		// the old "Query" is now implemtned in invoke
		return t.payment(stub, args)
	} else if function == "markchannel" {

		return t.markchannelhash(stub, args)
	} else if function == "lockpay" {

		return t.lockpay(stub, args)
	} else if function == "query" {

		return t.query(stub, args)
	} else {
		return shim.Error("error command not support.")
	}

	return shim.Success(nil)
}

func main() {

	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		logger.Errorf("Error starting poa chaincode: %s", err)
	}

}
