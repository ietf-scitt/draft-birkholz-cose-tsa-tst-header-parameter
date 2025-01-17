#!/bin/bash

set -eux
set -o pipefail

export DUMPASN1_PATH=../ctt

TTC_REQ=ttc-req.der
TTC_REQ_ASN1=ttc-req.asn1
TTC_RES=ttc-rsp.der
TTC_TST=ttc-tst.der
TTC_TST_ASN1=ttc-tst.asn1
TTC_DIAG_OUT=out.diag

openssl ts \
  -query \
  -data <(echo -n "This is the content.") \
  -no_nonce \
  -sha256 \
  -cert \
  -out ${TTC_REQ}

dumpasn1 -w72 -p ${TTC_REQ} > ${TTC_REQ_ASN1}

curl \
  -H "Content-Type: application/timestamp-query" \
  --data-binary "@${TTC_REQ}" \
  https://freetsa.org/tsr \
  > ${TTC_RES}

openssl ts \
  -reply \
  -in ${TTC_RES} \
  -token_out \
  -out ${TTC_TST}

set +e
dumpasn1 -w72 -p ${TTC_TST} | head -30 > ${TTC_TST_ASN1}
set -e

go-cose3161 ${TTC_TST} | cbor-edn diag2diag > ${TTC_DIAG_OUT}
