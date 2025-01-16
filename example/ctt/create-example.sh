#!/bin/bash

set -eux
set -o pipefail

CTT_DIAG_IN=in.diag
CTT_REQ=ctt-req.der
CTT_REQ_ASN1=ctt-req.asn1
CTT_RES=ctt-rsp.der
CTT_TST=ctt-tst.der
CTT_TST_ASN1=ctt-tst.asn1
CTT_DIAG_OUT=out.diag
CTT_DIAG_OUT_TMPL=out.diag.temp

CTT_SIGNATURE="$(awk '/signature/ {print $4}' ${CTT_DIAG_IN})"

openssl ts \
  -query \
  -data <(echo ${CTT_SIGNATURE} | diag2cbor.rb) \
  -no_nonce \
  -sha256 \
  -cert \
  -out ${CTT_REQ}

dumpasn1 -w72 -p ${CTT_REQ} > ${CTT_REQ_ASN1}

curl \
  -H "Content-Type: application/timestamp-query" \
  --data-binary '@ctt-req.tsq' \
  https://freetsa.org/tsr \
  > ${CTT_RES}

openssl ts \
  -reply \
  -in ${CTT_RES} \
  -token_out \
  -out ${CTT_TST}

set +e
dumpasn1 -w72 -p ${CTT_TST} | head -30 > ${CTT_TST_ASN1}
set -e

CTT="$(xxd -p -c0 ${CTT_TST})"

cat ${CTT_DIAG_OUT_TMPL} | \
  sed "s/__CTT__/${CTT}/g" \
  > "${CTT_DIAG_OUT}"
