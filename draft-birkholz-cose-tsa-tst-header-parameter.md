---
v: 3

title: 'COSE Header parameter for RFC 3161 Time-Stamp Tokens'
abbrev: TST Header
docname: draft-birkholz-cose-tsa-tst-header-parameter-latest
area: Security
wg: COSE
kw: Internet-Draft
cat: std
stream: IETF

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

normative:
  STD70:
    =: RFC5652
    -: CMS
  RFC3161: TSA
  STD96:
    =: RFC9052
    -: COSE

informative:
  I-D.ietf-scitt-architecture: SCITT

entity:
  SELF: "RFCthis"

--- abstract

This document defines a CBOR Signing And Encrypted (COSE) header parameter for incorporating RFC 3161-based timestamping into COSE message structures (COSE_Sign and COSE_Sign1). This enables the use of established RFC 3161 timestamping infrastructure to prove the creation time of a message.

--- middle

# Introduction

RFC 3161 {{-TSA}} provides a method to timestamp a message digest to prove that it was created before a given time.

This document defines two new CBOR Object Signing and Encryption (COSE) {{-COSE}} header parameters that carry the TimestampToken (TST) output of RFC 3161, thus allowing existing and widely deployed trust infrastructure to be used with COSE structures used for signing (COSE_Sign and COSE_Sign1).

To motivate the two different modes of use that are specified in this documents, two usage scenarios are illustrated in {{use-one}} and {{use-two}} below.

{{sec-timestamp-then-cose}} and {{sec-cose-then-timestamp}} then define the corresponding modes of use.

## Usage Scenario 1: A TST Included in Signed Documents {#use-one}

In support of legal assurances, a signed document can be augmented with a trustworthy timestamp.
In essence, a PDF signer wants to strengthen the assertion that a PDF was not signed before a certain point in time ("the signature cannot be older than").
To achieve this goal, the PDF signer acquires a TST from a TSA, includes it in the to-be-signed PDF that becomes the COSE payload and then signs it.
Using only its local clock instead, a PDF signer would be able to tamper with its clock and thereby falsify the recentness of the signing procedure.

This usage scenario motivates the "Timestamp then COSE" mode below.

## Usage Scenario 2: Registering a Signed Statement at a Transparency Service {#use-two}

Transparency services as described in {{-SCITT}} notarize COSE-signed statements by registering them in verifiable data structures that constitute append-only logs.
Once a signed statement is registered, it cannot be changed.
In some applications, the registration policy of a transparency service could enforce adding a timestamp to the unprotected header of the COSE-signed statement in order to strengthen the assurance at which point of time the registration occurred ("the registration cannot have happened before").
To achieve this goal, the transparency service acquires a TST from a TSA, includes it in the unprotected header of the COSE-signed statement and then registers it.
Using only its local clock instead, a transparency service would be able to tamper with its clock an thereby falsify the recentness of the registration procedure.

This usage scenario motivates the "COSE then Timstamp" mode below.

## Requirements Notation

{::boilerplate bcp14-tagged}

# Modes of Use

There are two different modes of composing COSE protection and timestamping motivated by the usage scenarios above.

## Timestamp then COSE (TTC) {#sec-timestamp-then-cose}

{{fig-timestamp-then-cose}} shows the case where a datum is first digested and submitted to a TSA to be timestamped.

This mode is utilized when the signature should also be performed over the timestamp to provide an immutable timestamp.

A signed COSE message is then built as follows:

* The obtained timestamp token is added to the protected headers,
* The original datum becomes the payload of the signed COSE message.

~~~ aasvg
.---------.              .---------------.     .----------------------.
| payload +------------->| Sig_structure +---->| COSE_Sign/COSE_Sign1 |
'----+----'              '---------------'     '----------------------'
     |                          ^
     |     .---.                |
     |    |     |     .-----.   |
     '--->| TSA +---->| TST +---'
          |     |     '-----'
           '---'
~~~
{: #fig-timestamp-then-cose artwork-align="center"
   title="Timestamp, then COSE (TTC)"}

The message imprint sent to the TSA ({{Section 2.4 of -TSA}}) MUST be the hash of the payload field of the COSE signed object.

## COSE then Timestamp (CTT) {#sec-cose-then-timestamp}

{{fig-cose-then-timestamp}} shows the case where the signature(s) field of the signed COSE object is digested and submitted to a TSA to be timestamped.
The obtained timestamp token is then added back as an unprotected header into the same COSE object.

This mode is utilized when a record of the timing of the signature operation is desired.

~~~ aasvg
.----------------------.         .-----.
| COSE_Sign/COSE_Sign1 |<--------+ TST |
'----+-----------------'         '-----'
     |                              ^
     v                              |
.----------------------.            |
| signatures/signature |            |
'----+-----------------'            |
     |                     .---.    |
     |                    |     |   |
     '------------------->| TSA +---'
                          |     |
                           '---'
~~~
{: #fig-cose-then-timestamp artwork-align="center"
   title="COSE, then Timestamp (CTT)"}

In this context, timestamp tokens are similar to a countersignature made by the TSA.

# RFC 3161 Time-Stamp Tokens COSE Header Parameters {#sec-tst-hdr}

The two modes described in {{sec-timestamp-then-cose}} and {{sec-cose-then-timestamp}} use different inputs into the timestamping machinery, and consequently create different kinds of binding between COSE and TST.
To clearly separate their semantics two different COSE header parameters are defined as described in the following subsections.

## `3161-ttc` {#sec-tst-hdr-ttc}

The `3161-ttc` COSE _protected_ header parameter MUST be used for the mode described in {{sec-timestamp-then-cose}}.

The `3161-ttc` protected header parameter contains a DER-encoded RFC3161 TimeStampToken wrapped in a CBOR byte string (Major type 2).

To minimize dependencies, the hash algorithm used for signing the COSE message SHOULD be the same as the algorithm used in the RFC3161 MessageImprint.

## `3161-ctt` {#sec-tst-hdr-ctt}

The `3161-ctt` COSE _unprotected_ header parameter MUST be used for the mode described in {{sec-cose-then-timestamp}}.

The message imprint sent in the request to the TSA MUST be either:

* the hash of the signature field of the COSE_Sign1 message.
* the hash of the signatures field of the COSE_Sign message.

In either case, to minimize dependencies, the hash algorithm SHOULD be the same as the algorithm used for signing the COSE message.
This may not be possible if the timestamp token has been obtained outside the processing context in which the COSE object is assembled.

The `3161-ctt` unprotected header parameter contains a DER-encoded RFC3161 TimeStampToken wrapped in a CBOR byte string (Major type 2).

# Timestamp Processing

RFC 3161 timestamp tokens use CMS as signature envelope format.
{{-CMS}} provides the details about signature verification, and {{-TSA}} provides the details specific to timestamp token validation.
The payload of the signed timestamp token is the TSTInfo structure defined in {{-TSA}}, which contains the message imprint that was sent to the TSA.
The hash algorithm is contained in the message imprint structure, together with the hash itself.

As part of the signature verification, the receiver MUST make sure that the message imprint in the embedded timestamp token matches a hash of either the payload, signature, or signature fields, depending on the mode of use and type of COSE structure.

{{Appendix B of -TSA}} provides an example that illustrates how timestamp tokens can be used to verify signatures of a timestamped message when utilizing X.509 certificates.

# Security Considerations

Please review the Security Considerations section in {{-TSA}}; these considerations apply to this document as well.

Also review the Security Considerations section in {{-COSE}}; these considerations apply to this document as well, especially the need for implementations to protect private key material.

The following scenario assumes an attacker can manipulate the clocks on the COSE signer and its relying parties, but not the TSA.
It is also assumed that the TSA is a trusted third party, so the attacker cannot impersonate the TSA and create valid timestamp tokens.
In such a setting, any tampering with the COSE signer's clock does not have an impact because, once the timestamp is obtained from the TSA, it becomes the only reliable source of time.
However, in both CTT and TTC mode, a denial of service can occur if the attacker can adjust the relying party's clock so that the CMS validation fails.
This could disrupt the timestamp validation.

In CTT mode, an attacker could manipulate the unprotected header by removing or replacing the timestamp.
To avoid that, the signed COSE object should be integrity protected during transit and at rest.

In TTC mode, the TSA is given an opaque identifier (a cryptographic hash value) for the payload.
While this means that the content of the payload is not directly revealed, to prevent comparison with known payloads or disclosure of identical payloads being used over time, the payload would need to be armored, e.g., with a nonce that is shared with the recipient of the header parameter but not the TSA.
Such a mechanism can be employed inside the ones described in this specification, but is out of scope for this document.

# IANA Considerations

IANA is requested to add the COSE header parameters defined in {{tbl-new-hdrs}} to the "COSE Header Parameters" registry {{!IANA.cose_header-parameters}}.

| Name | Label | Value Type | Value Registry | Description | Reference |
| `3161-tcc` | TBD1 | bstr | - | RFC 3161 timestamp token | {{&SELF}}, {{sec-tst-hdr-ttc}} |
| `3161-ctt` | TBD2 | bstr | - | RFC 3161 timestamp token | {{&SELF}}, {{sec-tst-hdr-ctt}} |
{: #tbl-new-hdrs align="left" title="New COSE Header Parameters"}

--- back

# Diagrams

The diagrams in this appendix illustrate the processing flow of the modes specified in {{sec-timestamp-then-cose}} and {{sec-cose-then-timestamp}} respectively.

For simplicity, only the `COSE_Sign1` processing is shown.
Similar diagrams for `COSE_Sign` can be derived by allowing multiple `SK_cose` boxes and replacing the label `[signature]` with `[signatures]`.

~~~ aasvg
{::include ascii-art/ttc.ascii-art}
~~~
{: #fig-ttc artwork-align="left" title="Timestamp then COSE"}

~~~ aasvg
{::include ascii-art/ctt.ascii-art}
~~~
{: #fig-ctt artwork-align="left" title="COSE then Timestamp"}

# Acknowledgments
{:unnumbered}

The editors would like to thank
Carl Wallace,
Leonard Rosenthol,
Michael B. Jones,
Michael Prorock,
Orie Steele,
and
Steve Lasker
for their reviews and comments.
