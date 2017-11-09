package main

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/sha256"
	"encoding/asn1"
	"errors"
	"math/big"
	"math/rand"
	"strconv"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

var logger = shim.NewLogger("porchaincode")

type SimpleChaincode struct {
	MinuteShare    int64
	MinuteAmount   int64
	TimeStartShare int64
	TimePreBlock   int64
	PreMinuteShare int64
	PreTotalAmount int64
}

type edsasig struct {
	R, S *big.Int
}

const PORCON = 100000000
const BLOCKM = 385 * PORCON //50000000 * 60 / (86400 * 90) //per minute share money

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	_, args := stub.GetFunctionAndParameters() //获取到调用Init函数的方法名称和参数
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	err := stub.PutState("ORGFUNDER", []byte(args[0]))
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
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

func (t *SimpleChaincode) fee(stub shim.ChaincodeStubInterface, value int64) error {

	userfund, err := stub.GetState("ORGFUNDER")
	if err != nil {
		return err
	}
	account, err := stub.GetState(string(userfund))
	if err != nil {
		return err
	}
	amount, err := strconv.ParseInt(string(account), 10, 64)
	if err != nil {
		return errors.New("Failed to Parse A state")
	}

	amount += value

	err = stub.PutState(string(userfund), []byte(strconv.FormatInt(amount, 10)))

	if err != nil {
		return err
	}
	return nil
}

func (t *SimpleChaincode) mining(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 3 {
		return shim.Error("Incorrect number of arguments. Expecting 3")
	}
	address := args[0]
	readkw, err := strconv.ParseInt(args[1], 10, 64)
	if err != nil {
		return shim.Error("Failed to get A state")
	}

	var tn time.Time
	tn = time.Now()
	timet := tn.UnixNano() / 1000000000
	if t.PreMinuteShare < 1000 {
		t.PreMinuteShare = 1000
	}
	if t.TimeStartShare == 0 {
		t.TimeStartShare = timet
		t.TimePreBlock = timet
	}

	nMaxAmount := (60+timet-t.TimeStartShare)/60*BLOCKM - t.PreTotalAmount
	if nMaxAmount > BLOCKM {
		nMaxAmount = BLOCKM
	}
	r := rand.New(rand.NewSource(tn.UnixNano()))
	var nRand int
	nRand = r.Intn(10000)
	nRandAmount := int64(nRand) * nMaxAmount * readkw / (5000 * t.PreMinuteShare)
	if nRandAmount < 0 {
		nRandAmount = 0
	} else if nRandAmount > BLOCKM {
		nRandAmount = BLOCKM
	}

	t.MinuteAmount += nRandAmount
	t.MinuteShare += readkw

	account, err := stub.GetState(address)
	var userA string
	if account == nil {
		userA = "0"
	} else {
		userA = string(account)
	}

	amount, err := strconv.ParseInt(userA, 10, 64)
	if err != nil {
		return shim.Error("Failed to Parse A state")
	}

	amount += nRandAmount

	err = stub.PutState(address, []byte(strconv.FormatInt(amount, 10)))
	if err != nil {
		return shim.Error("put state fail.")
	}

	if (t.TimePreBlock + 60) < timet {
		t.TimePreBlock = timet
		t.PreMinuteShare = t.MinuteShare
		t.PreTotalAmount += t.MinuteAmount
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

	aValue, err := strconv.ParseInt(string(accountA), 10, 64)
	if err != nil {
		return shim.Error("Expecting integer value for args 3 holding")
	}
	bValue, err := strconv.ParseInt(string(accountB), 10, 64)
	if err != nil {
		return shim.Error("Expecting integer value for args 3 holding")
	}

	if paycount > aValue {
		return shim.Error("account value small to payment.")
	}

	aValue -= (paycount + 0.0001*PORCON)
	bValue += paycount

	err = stub.PutState(args[0], []byte(strconv.FormatInt(aValue, 10)))
	if err != nil {
		return shim.Error("put state fail.")
	}
	err = stub.PutState(args[1], []byte(strconv.FormatInt(bValue, 10)))
	if err != nil {
		return shim.Error("put state fail.")
	}

	err = t.fee(stub, 0.0001*PORCON)
	if err != nil {
		return shim.Error("fee function error:" + err.Error())
	}
	return shim.Success(nil)
}

func (t *SimpleChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}
	account, err := stub.GetState(args[0])
	if err != nil {
		return shim.Error("account not exist.")
	}
	var ret string
	ret = "\"" + string(account) + "\""
	return shim.Success([]byte(ret))
}

func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	if function == "payment" {
		// the old "Query" is now implemtned in invoke
		return t.payment(stub, args)
	} else if function == "query" {

		return t.query(stub, args)
	} else if function == "mining" {

		return t.mining(stub, args)
	} else {
		return shim.Error("error command not support.")
	}

	return shim.Success(nil)
}

func main() {

	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		logger.Errorf("Error starting Simple chaincode: %s", err)
	}
}
