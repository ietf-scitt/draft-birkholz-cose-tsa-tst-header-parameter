---
title: 'COSE Header parameter for RFC 3161 Time-Stamp Tokens'
abbrev: TST Header
docname: draft-birkholz-cose-tsa-tst-header-parameter-latest
stand_alone: true
ipr: trust200902
area: Security
wg: COSE
kw: Internet-Draft
cat: std
pi:
  toc: yes
  sortrefs: yes
  symrefs: yes

author:
- ins: H. Birkholz
  name: Henk Birkholz
  org: Fraunhofer SIT
  abbrev: Fraunhofer SIT
  email: henk.birkholz@sit.fraunhofer.de
  street: Rheinstrasse 75
  code: '64295'
  city: Darmstadt
  country: Germany
- ins: T. Fossati
  name: Thomas Fossati
  organization: Linaro
  email: thomas.fossati@linaro.org
- ins: M. Riechert
  name: Maik Riechert
  organization: Microsoft
  email: Maik.Riechert@microsoft.com
  country: UK

normative:
  STD70:
    =: RFC5652
    -: CMS
  RFC3161: TSA
  STD96:
    =: RFC9052
    -: COSE

informative:
  RFC9338: countersign

entity:
  SELF: "RFCthis"

--- abstract

RFC 3161 provides a method for timestamping a message digest to prove that the message was created before a given time.
This document defines a CBOR Signing And Encrypted (COSE) header parameter that can be used to combine COSE message structures used for signing (i.e., COSE_Sign and COSE_Sign1) with existing RFC 3161-based timestamping infrastructure.

--- middle

# Introduction

RFC 3161 {{-TSA}} provides a method to timestamp a message digest to prove that it was created before a given time.

This document defines a new COSE {{-COSE}} header parameter that carries the TimestampToken (TST) output of RFC 3161, thus allowing existing and widely deployed trust infrastructure to be used with COSE structures used for signing (COSE_Sign and COSE_Sign1).

## Requirements Notation

{::boilerplate bcp14-tagged}

# Modes of use

There are two different modes of composing COSE protection and timestamping.

## Timestamp then COSE (TTC) {#sec-timestamp-then-cose}

{{fig-timestamp-then-cose}} shows the case where a datum is first digested and submitted to a TSA to be timestamped.

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

In this context, timestamp tokens are similar to a countersignature {{-countersign}} made by the TSA.

# RFC 3161 Time-Stamp Tokens COSE Header Parameters {#sec-tst-hdr}

The two modes described in {{sec-timestamp-then-cose}} and {{sec-cose-then-timestamp}} use different inputs into the timestamping machinery, and consequently create different kinds of binding between COSE and TST.
To clearly separate their semantics two different COSE header parameters are defined as described in the following subsections.

## `3161-ttc` {#sec-tst-hdr-ttc}

The `3161-ttc` COSE _protected_ header parameter MUST be used for the mode described in {{sec-timestamp-then-cose}}.

The `3161-ttc` protected header is defined as follows:

* Name: 3161-ttc
* Label: TBD
* Value Type: bstr
* Value Registry: {{!IANA.cose}}
* Description: RFC 3161 timestamp token
* Reference: {{sec-tst-hdr-ttc}} of {{&SELF}}

The content of the byte string are the bytes of the DER-encoded RFC 3161 TimeStampToken structure.

## `3161-ctt` {#sec-tst-hdr-ctt}

The `3161-ctt` COSE _unprotected_ header parameter MUST be used for the mode described in {{sec-cose-then-timestamp}}.

The message imprint sent in the request to the TSA MUST be either:

* the hash of the signature field of the COSE_Sign1 message.
* the hash of the signatures field of the COSE_Sign message.

In either case, to minimize dependencies, the hash algorithm SHOULD be the same as the algorithm used for signing the COSE message.
This may not be possible if the timestamp token has been obtained outside the processing context in which the COSE object is assembled.

The `3161-ctt` unprotected header is defined as follows:

* Name: 3161-ctt
* Label: TBD
* Value Type: bstr
* Value Registry: {{!IANA.cose}}
* Description: RFC 3161 timestamp token
* Reference: {{sec-tst-hdr-ctt}} of {{&SELF}}

# Timestamp Processing

RFC 3161 timestamp tokens use CMS as signature envelope format.
{{-CMS}} provides the details about signature verification, and {{-TSA}} provides the details specific to timestamp token validation.
The payload of the signed timestamp token is the TSTInfo structure defined in {{-TSA}}, which contains the message imprint that was sent to the TSA.
The hash algorithm is contained in the message imprint structure, together with the hash itself.

As part of the signature verification, the receiver MUST make sure that the message imprint in the embedded timestamp token matches either the payload or the signature fields, depending on the mode of use.

{{Appendix B of -TSA}} provides an example that illustrates how timestamp tokens can be used to verify signatures of a timestamped message when utilizing X.509 certificates.

# Security Considerations

The security considerations made in {{-TSA}} as well as those of {{-countersign}} apply.

In the "Timestamp, then COSE" (TTC) sequence of operation, the TSA is
given an opaque identifier (a cryptographic hash value) for the
payload.
While this means that the content of the payload is not directly
revealed, to prevent comparison with known payloads or disclosure of
identical payloads being used over time, the payload would need to be
armored, e.g., with a nonce that is shared with the recipient of the
header parameter but not the TSA.
Such a mechanism can be employed inside the ones described in this
specification, but is out of scope for this document.

# IANA Considerations

IANA is requested to add the two COSE header parameters described in {{sec-tst-hdr}} to the "COSE Header Parameters" subregistry of the {{!IANA.cose}} registry.

--- back
