package main

import (
	"crypto/aes"
	"crypto/cipher"
	//"crypto/rand"
	"encoding/hex"
	"fmt"
	//"io"
)

func main() {
	// Encrypt Area ///////////////////////////////////////////////
	/*  key, _ := hex.DecodeString("6368616e676520746869732070617373776f726420746f206120736563726574") */
	// plaintext := []byte("exampleplaintext")
	//
	// block, err := aes.NewCipher(key)
	// if err != nil {
	//   panic(err.Error())
	// }
	//
	// nonce := make([]byte, 12)
	// if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
	//   panic(err.Error())
	// }
	//
	// aesgcm, err := cipher.NewGCM(block)
	// if err != nil {
	//   panic(err.Error())
	// }
	//
	// ciphertext := aesgcm.Seal(nil, nonce, plaintext, nil)
	// fmt.Println("key : ", string(key))
	// fmt.Println("nonce : ", string(nonce))
	/* fmt.Printf("%x\n", ciphertext) */

	// Decrypt Area //////////////////////////////////////////////
	key, _ := hex.DecodeString("6368616e676520746869732070617373776f726420746f206120736563726574")
	ciphertext, _ := hex.DecodeString("c3aaa29f002ca75870806e44086700f62ce4d43e902b3888e23ceff797a7a471e")
	nonce, _ := hex.DecodeString("64a9433eae7ccceee2fc0eda")

	block, err := aes.NewCipher(key)
	if err != nil {
		panic(err.Error())
	}

	aesgcm, err := cipher.NewGCM(block)
	if err != nil {
		panic(err.Error())
	}

	plaintext, err := aesgcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		panic(err.Error())
	}

	fmt.Println("key : ", string(key))
	fmt.Println("nonce : ", string(nonce))
	fmt.Printf("%s\n", plaintext)
}
