---
v: 3

title: 'COSE Header parameter for RFC 3161 Time-Stamp Tokens'
abbrev: TST Header
docname: draft-ietf-cose-tsa-tst-header-parameter-latest
area: "Security"
wg: COSE
kw: Internet-Draft
cat: std
stream: IETF
venue:
  github: ietf-scitt/draft-birkholz-cose-tsa-tst-header-parameter

author:
- name: Henk Birkholz
  org: Fraunhofer SIT
  abbrev: Fraunhofer SIT
  email: henk.birkholz@sit.fraunhofer.de
  street: Rheinstrasse 75
  code: '64295'
  city: Darmstadt
  country: Germany
- name: Thomas Fossati
  organization: Linaro
  email: thomas.fossati@linaro.org
- name: Maik Riechert
  organization: Microsoft
  email: Maik.Riechert@microsoft.com
  country: UK

contributor:
- name: Carsten Bormann
  email: cabo@tzi.org
  contribution: Carsten contributed part of the security considerations.
- name: Orie Steele
  email: orie@transmute.industries
  contribution: Orie contributed an improved version of the diagrams.

normative:
  STD70:
    =: RFC5652
    -: CMS
  RFC3161: TSA
  STD96:
    =: RFC9052
    -: COSE

informative:
  RFC9581: cbor-time-tag

entity:
  SELF: "RFCthis"

--- abstract

This document defines two CBOR Signing And Encrypted (COSE) header parameters for incorporating RFC 3161-based timestamping into COSE message structures (`COSE_Sign` and `COSE_Sign1`).
This enables the use of established RFC 3161 timestamping infrastructure in COSE-based protocols.

--- middle

# Introduction

RFC 3161 {{-TSA}} provides a method to timestamp a message digest to prove that it was created before a given time.

This document defines two new CBOR Object Signing and Encryption (COSE) {{-COSE}} header parameters that carry the TimestampToken (TST) output of RFC 3161, thus allowing existing and widely deployed trust infrastructure to be used with COSE structures used for signing (`COSE_Sign` and `COSE_Sign1`).

## Use Cases

This section discusses two use cases, each representing one of the two modes of use defined in {{modes}}.

A first use case is a digital document signature signed alongside a trustworthy timestamp.
This is a common case in legal contracts.
In such scenarios, the document signer wants to reinforce the claim that the document was signed at a specific time.
To achieve this, the document signer acquires a fresh TST for the document's signature from a TSA and concatenates it with the document.
Later on, a relying party consuming the both the signed document and the TST can be certain that the document was signed _at least_ at the time specified by the TSA.
The relying party does not have to trust the document signer's clock, which may have been maliciously altered or simply inaccurate.

This usage scenario motivates the "COSE then Timestamp" mode described in {{sec-cose-then-timestamp}}.

A second use case is the notarization of a signed documents by registering it at a transparency service.
This is common for accountability and auditability of issued documents, also referred to 'statements' in this context.
It is also common to only register signed parts of a document (typically referred to as a 'signed statement') at a transparency service to reduce the complexity of consistency checks at a later point in time, which would require the retrieval or reconstruction of unsigned parts.
Once a document's signed parts are registered at a transparency service's append-only log, its log entry cannot be changed.
To not loose the TST during a registration procedure, it must be part of the signed statement.
To achieve this, the Issuer acquires a TST from a TSA, bundles it with the unsigned document so that the resulting signed statement includes the TST, and then registers the signed parts (rendering it a 'transparent statement').
Later on, a relying party consuming the transparent statement including the TST can be certain that statement was signed by the Issuer _at least_ at the time specified by the TSA.
A relying party that wants to ascertain the authenticity of the statement after the issuer's signing key has expired (or has been compromised), can do so by making sure that no revocation information has been made public before the time asserted by the issuer, registered at the transparency service.

This usage scenario motivates the "Timestamp then COSE" mode defined in {{sec-timestamp-then-cose}}.

## Requirements Notation

{::boilerplate bcp14-tagged}

# Modes of Use {#modes}

There are two different modes of composing COSE protection and timestamping, motivated by the usage scenarios discussed above.

The diagrams in this section illustrate the processing flow of the specified modes.
For simplicity, only the `COSE_Sign1` processing is shown.
Similar diagrams for `COSE_Sign` can be derived by allowing multiple `private-key` parallelogram boxes and replacing the label `[signature]` with `[signatures]`.

## COSE then Timestamp (CTT) {#sec-cose-then-timestamp}

{{fig-cose-then-timestamp}} shows the case where the signature(s) field of the signed COSE object is digested and submitted to a TSA to be timestamped.
The obtained timestamp token is then added back as an unprotected header into the same COSE object.

This mode is utilized when a record of the timing of the signature operation is desired.

~~~ aasvg
{::include ascii-art/ctt-alt.ascii-art}
~~~
{: #fig-cose-then-timestamp artwork-align="center"
   title="COSE, then Timestamp (CTT)"}

In this context, timestamp tokens are similar to a countersignature made by the TSA.

## Timestamp then COSE (TTC) {#sec-timestamp-then-cose}

{{fig-timestamp-then-cose}} shows the case where a datum is first digested and submitted to a TSA to be timestamped.

This mode is used to wrap the signed document and its timestamp together in an immutable payload.

A signed COSE message is then built as follows:

* The obtained timestamp token is added to the protected headers,
* The original datum becomes the payload of the signed COSE message.

~~~ aasvg
{::include ascii-art/ttc-alt.ascii-art}
~~~
{: #fig-timestamp-then-cose artwork-align="center"
   title="Timestamp, then COSE (TTC)"}

# RFC 3161 Time-Stamp Tokens COSE Header Parameters {#sec-tst-hdr}

The two modes described in {{sec-timestamp-then-cose}} and {{sec-cose-then-timestamp}} use different inputs into the timestamping machinery, and consequently create different kinds of binding between COSE and TST.
To clearly separate their semantics two different COSE header parameters are defined as described in the following subsections.

## `3161-ctt` {#sec-tst-hdr-ctt}

The `3161-ctt` COSE _unprotected_ header parameter MUST be used for the mode described in {{sec-cose-then-timestamp}}.

The `3161-ctt` unprotected header parameter contains a DER-encoded RFC3161 `TimeStampToken` wrapped in a CBOR byte string (Major type 2).

The `MessageImprint` sent in the request to the TSA MUST be:

* the hash of the CBOR-encoded signature field of the `COSE_Sign1` message, or
* the hash of the CBOR-encoded signatures field of the `COSE_Sign` message.

In either case, to minimize dependencies, the hash algorithm SHOULD be the same as the algorithm used for signing the COSE message.
This may not be possible if the timestamp token has been obtained outside the processing context in which the COSE object is assembled.

Refer to {{ctt-sign1}} and {{ctt-sign}} for concrete examples of `MessageImprint` computation.

### `MessageImprint` Computation for `COSE_Sign1` {#ctt-sign1}

The following illustrates how `MessageImprint` is computed using a sample `COSE_Sign1` message.

Given the `COSE_Sign1` message

~~~ cbor-diag
18(
  [
    / protected h'a10126' / << {
        / alg / 1:-7 / ECDSA 256 /
      } >>,
    / unprotected / {
      / kid / 4:'11'
    },
    / payload / 'This is the content.',
    / signature / h'8eb33e4ca31d1c465ab05aac34cc6b23d58fef5c083106c4
d25a91aef0b0117e2af9a291aa32e14ab834dc56ed2a223444547e01f11d3b0916e5
a4c345cacb36'
  ]
)
~~~

the `bstr`-wrapped `signature`

~~~ cbor-pretty
58 40                                     # bytes(64)
   8eb33e4ca31d1c465ab05aac34cc6b23
   d58fef5c083106c4d25a91aef0b0117e
   2af9a291aa32e14ab834dc56ed2a2234
   44547e01f11d3b0916e5a4c345cacb36
~~~

(including the heading bytes `0x5840`) is used as input for computing the `MessageImprint`.

When using SHA-256, the resulting `MessageImprint` is

~~~ asn1
SEQUENCE {
  SEQUENCE {
    OBJECT IDENTIFIER sha-256 (2 16 840 1 101 3 4 2 1)
    NULL
    }
  OCTET STRING
    44 C2 41 9D 13 1D 53 D5 55 84 B5 DD 33 B7 88 C2
    4E 55 1C 6D 44 B1 AF C8 B2 B8 5E 69 54 76 3B 4E
  }
~~~

### `MessageImprint` Computation for `COSE_Sign` {#ctt-sign}

The following illustrates how `MessageImprint` is computed using a sample `COSE_Sign` message.

Given the `COSE_Sign` message

~~~ cbor-diag
98(
  [
    / protected / h'',
    / unprotected / {},
    / payload / 'This is the content.',
    / signatures / [
      [
        / protected h'a10126' / << {
            / alg / 1:-7 / ECDSA 256 /
          } >>,
        / unprotected / {
          / kid / 4:'11'
        },
        / signature / h'e2aeafd40d69d19dfe6e52077c5d7ff4e408282cbefb
5d06cbf414af2e19d982ac45ac98b8544c908b4507de1e90b717c3d34816fe926a2b
98f53afd2fa0f30a'
      ]
    ]
  ]
)
~~~

the `signatures` array

~~~ cbor-pretty
81                                        # array(1)
   83                                     # array(3)
      43                                  # bytes(3)
         a10126
      a1                                  # map(1)
         04                               # unsigned(4)
         42                               # bytes(2)
            3131                          # "11"
      58 40                               # bytes(64)
         e2aeafd40d69d19dfe6e52077c5d7ff4
         e408282cbefb5d06cbf414af2e19d982
         ac45ac98b8544c908b4507de1e90b717
         c3d34816fe926a2b98f53afd2fa0f30a
~~~

is used as input for computing the `MessageImprint`.

When using SHA-256, the resulting `MessageImprint` is

~~~ asn1
SEQUENCE {
  SEQUENCE {
    OBJECT IDENTIFIER sha-256 (2 16 840 1 101 3 4 2 1)
    NULL
    }
  OCTET STRING
    80 3F AD A2 91 2D 6B 7A 83 3A 27 BD 96 1C C0 5B
    C1 CC 16 47 59 B1 C5 6F 7A A7 71 E4 E2 15 26 F7
  }
~~~

## `3161-ttc` {#sec-tst-hdr-ttc}

The `3161-ttc` COSE _protected_ header parameter MUST be used for the mode described in {{sec-timestamp-then-cose}}.

The `3161-ttc` protected header parameter contains a DER-encoded RFC3161 `TimeStampToken` wrapped in a CBOR byte string (Major type 2).

The `MessageImprint` sent to the TSA ({{Section 2.4 of -TSA}}) MUST be the hash of the payload of the COSE signed object.
This does not include the `bstr`-wrapping, only the payload bytes.
(For an example, see {{ex-ttc}}.)

To minimize dependencies, the hash algorithm used for signing the COSE message SHOULD be the same as the algorithm used in the RFC3161 MessageImprint.
However, this may not be possible if the timestamp requester and the COSE message signer are different entities.

# Timestamp Processing

RFC 3161 timestamp tokens use CMS as signature envelope format.
{{-CMS}} provides the details about signature verification, and {{-TSA}} provides the details specific to timestamp token validation.
The payload of the signed timestamp token is the TSTInfo structure defined in {{-TSA}}, which contains the MessageImprint that was sent to the TSA.
The hash algorithm is contained in the MessageImprint structure, together with the hash itself.

As part of the signature verification, the receiver MUST make sure that the MessageImprint in the embedded timestamp token matches a hash of either the payload, signature, or signature fields, depending on the mode of use and type of COSE structure.

{{Appendix B of -TSA}} provides an example that illustrates how timestamp tokens can be used to verify signatures of a timestamped message when utilizing X.509 certificates.

# Security Considerations

Please review the Security Considerations section in {{-TSA}}; these considerations apply to this document as well.

Also review the Security Considerations section in {{-COSE}}; these considerations apply to this document as well, especially the need for implementations to protect private key material.

The following scenario assumes an attacker can manipulate the clocks on the COSE signer and its relying parties, but not the TSA.
It is also assumed that the TSA is a trusted third party, so the attacker cannot impersonate the TSA and create valid timestamp tokens.
In such a setting, any tampering with the COSE signer's clock does not have an impact because, once the timestamp is obtained from the TSA, it becomes the only reliable source of time.
However, in both CTT and TTC mode, a denial of service can occur if the attacker can adjust the relying party's clock so that the CMS validation fails.
This could disrupt the timestamp validation.

Implementers MUST clearly differentiate between RFC 3161 TSA timestamps proving the existence of payload data at an earlier point in time (TTC) and timestamps explicitly providing evidence of the existence of the cryptographic signature (CTT).
Failure to clearly distinguish between these timestamp semantics can result in vulnerabilities, such as incorrectly accepting signatures created after key revocation based on older payload-only timestamps.
Validators must not interpret protected-header payload timestamps as proof of signature
creation time and should rely exclusively on RFC 3161 TSA timestamps explicitly covering signature data for determining signature validity timing.

In CTT mode, an attacker could manipulate the unprotected header by removing or replacing the timestamp.
To avoid that, the signed COSE object should be integrity protected during transit and at rest.

In TTC mode, the TSA is given an opaque identifier (a cryptographic hash value) for the payload.
While this means that the content of the payload is not directly revealed, to prevent comparison with known payloads or disclosure of identical payloads being used over time, the payload would need to be armored, e.g., with a nonce that is shared with the recipient of the header parameter but not the TSA.
Such a mechanism can be employed inside the ones described in this specification, but is out of scope for this document.

CTT and TTC modes have different semantic meanings.
An implementation must ensure that the contents of the CTT and TCC headers are interpreted according to their specific semantics.
In particular, symmetric to the signature and assembly mechanics, each mode has its own separate verification algorithm.

Consumers of TSTs typically rely not only on accurate time but also prompt reporting of compromised keys.
{{-COSE}} discusses the necessity of keeping private keys private, but does not discuss the prompt reporting when those keys are disclosed.
Therefore, keeping track of cryptoperiods, key rotation, or key revocation is an essential part of trusting a TSA.
Additionally, the resolution, accuracy, and precision of a TSA's clock (see {{-cbor-time-tag}} for further details on a clock's qualities), as well as an expected latency introduced by round trips to the TSA and back can be critical information that has to be taken into account by implementers when implementing the COSE header parameters defined in this document.

# IANA Considerations

IANA is requested to add the COSE header parameters defined in {{tbl-new-hdrs}} to the "COSE Header Parameters" registry {{!IANA.cose_header-parameters}}.

| Name | Label | Value Type | Value Registry | Description | Reference |
| `3161-ttc` | TBD1 | bstr | - | RFC 3161 timestamp token: Timestamp then COSE | {{&SELF}}, {{sec-tst-hdr-ttc}} |
| `3161-ctt` | TBD2 | bstr | - | RFC 3161 timestamp token: COSE then Timestamp | {{&SELF}}, {{sec-tst-hdr-ctt}} |
{: #tbl-new-hdrs align="left" title="New COSE Header Parameters"}

--- back

# Examples

## TTC {#ex-ttc}

The payload

~~~
This is the content.
~~~

is hashed using SHA-256 to create the `TimeStampReq` object

~~~ asn1
{::include-fold example/ttc/ttc-req.asn1}
~~~

which is sent to the Time Stamping Authority.

A `TimeStampResp` is returned which contains the `TimeStampToken`

~~~ asn1
{::include-fold example/ttc/ttc-tst.asn1}
[...]
~~~

The contents of the `TimeStampToken` are `bstr`-wrapped and added to the protected headers bucket which is then signed alongside the original payload to obtain the `COSE_Sign1` object

~~~ cbor-diag
{::include-fold example/ttc/out.diag}
~~~

## CTT

Starting with the following `COSE_Sign1` object

~~~ cbor-diag
{::include-fold example/ctt/in.diag}
~~~

The CBOR-encoded signature field is hashed using SHA-256 to create the following `TimeStampReq` object

~~~ asn1
{::include-fold example/ctt/ctt-req.asn1}
~~~

which is sent to the Time Stamping Authority.

A `TimeStampResp` is returned which contains the following `TimeStampToken`

~~~ asn1
{::include-fold example/ctt/ctt-tst.asn1}
[...]
~~~

The contents of the `TimeStampToken` are `bstr`-wrapped and added to the unprotected headers bucket in the original `COSE_Sign1` object to obtain the following

~~~ cbor-diag
{::include-fold example/ctt/out.diag}
~~~

# Acknowledgments
{:unnumbered}

The editors would like to thank
Carl Wallace,
Carsten Bormann,
Francesca Palombini,
Leonard Rosenthol,
Linda Dunbar,
Michael B. Jones,
Michael Prorock,
Orie Steele,
Shuping Peng,
Stefan Santesson,
Steve Lasker,
and
Yingzhen Qu
for their reviews and comments.
