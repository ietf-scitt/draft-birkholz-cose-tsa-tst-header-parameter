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

## Timestamp then COSE {#sec-timestamp-then-cose}

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
   title="Timestamp, then COSE"}

## COSE then Timestamp {#sec-cose-then-timestamp}

{{fig-cose-then-timestamp}} shows the case where the signature(s) field of the signed COSE object is digested and submitted to a TSA to be timestamped.
The obtained timestamp token is then added back as an unprotected header into the same COSE object.

In this context, timestamp tokens are similar to a countersignature {{-countersign}} made by the TSA.

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
   title="COSE, then Timestamp"}

# RFC 3161 Time-Stamp Tokens COSE Header Parameter {#sec-tst-hdr}

To carry RFC 3161 timestamp tokens in COSE signed messages, a new COSE header parameter, `rfc3161-tst`, is defined as follows:

* Name: rfc3161-tst
* Label: tst
* Value Type: bstr
* Value Registry: none
* Description: One or more RFC 3161 timestamp tokens.
* Reference: {{&SELF}}

The content of the byte string are the bytes of the DER-encoded RFC 3161 TimeStampToken structure.

When used as described in {{sec-timestamp-then-cose}}, the message imprint sent to the TSA ({{Section 2.4 of -TSA}}) MUST be the hash of the payload field of the COSE signed object.

When used as described in {{sec-cose-then-timestamp}}, the message imprint sent in the request to the TSA MUST be either:

* the hash of the signature field of the COSE_Sign1.
* the hash of the signatures field of the COSE_Sign message.

In either case, to minimize dependencies, the hash algorithm SHOULD be the same as the algorithm used for signing the COSE message.  This may not be possible if the timestamp token has been obtained outside the processing context in which the COSE object is assembled.

RFC 3161 timestamp tokens use CMS as signature envelope format. {{-CMS}} provides the details about signature verification, and {{-TSA}} provides the details specific to timestamp token validation.
The payload of the signed timestamp token is the TSTInfo structure defined in {{-TSA}}, which contains the message imprint that was sent to the TSA.
The hash algorithm is contained in the message imprint structure, together with the hash itself.

As part of the signature verification, the receiver MUST make sure that the message imprint in the embedded timestamp token matches either the payload or the signature fields, depending on the mode of use..

Guidance is illustrated in {{Appendix B of -TSA}} via an example that shows how timestamp tokens can be used during signature verification of a timestamped message when using X.509 certificates.

# Security Considerations

The security considerations made in {{-TSA}} as well as those of {{-countersign}} apply.

# IANA Considerations

IANA is requested to add the COSE Header parameter described in {{sec-tst-hdr}} to the "COSE Header Parameters" of the {{!IANA.cose}} registry.

--- back
